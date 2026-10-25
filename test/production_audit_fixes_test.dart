import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Production Audit & Security Fixes Verification', () {
    test('1. Role escalation prevention: UserModel.fromMap strictly enforces server role', () {
      final untrustedClientPayload = {
        'id': 'usr-hack-1',
        'email': 'natnaeltedla25@gmail.com', // Admin allowlist email
        'fullName': 'Attacker Student',
        'role': 'student',
        'isApproved': false,
      };

      final parsed = UserModel.fromMap(untrustedClientPayload, 'usr-hack-1');
      expect(parsed.role, UserRole.student);
      expect(parsed.isApproved, isFalse);
      expect(parsed.fullName, 'Attacker Student');
    });

    test('2. UI Permission Alignment: Coordinator capabilities align with Firestore rules', () {
      final state = FellowshipState();

      // Configure a Programs Coordinator
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptBatchPrograms,
      );
      expect(state.canManagePilgrimages, isTrue);
      expect(state.canVerifyFinances, isFalse);
      expect(state.canManageApprovals, isFalse);
      expect(state.canSchedulePriests, isFalse);
      expect(state.canManageEmergencyAid, isFalse);

      // Configure a Charity Coordinator
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptCharity,
      );
      expect(state.canVerifyFinances, isTrue);
      expect(state.canManageCharityAndAid, isTrue);
      expect(state.canManagePilgrimages, isFalse);
      expect(state.canManageApprovals, isFalse);

      // Configure a Member Care Coordinator
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptMemberCare,
      );
      expect(state.canManageEmergencyAid, isTrue);
      expect(state.canManageFamilies, isTrue);
      expect(state.canManageFamilyMatching, isTrue);
      expect(state.canManagePilgrimages, isFalse);
      expect(state.canVerifyFinances, isFalse);

      // Switch to Admin: has global administrative capabilities
      state.switchRole(UserRole.admin);
      expect(state.canManageApprovals, isTrue);
      expect(state.canApproveGeneralStudents, isTrue);
      expect(state.canSchedulePriests, isTrue);
      expect(state.canVerifyFinances, isTrue);
      expect(state.canManagePilgrimages, isTrue);
      expect(state.canManageEmergencyAid, isTrue);
    });

    test('3. Production mode does not write demo seed data', () async {
      final state = FellowshipState();
      state.switchRole(UserRole.admin);

      expect(await state.seedEntireDatabaseToFirestore(), 0);
      expect(await state.seedTestStudentsToFirestore(), 0);
      expect(await state.clearTestStudentsFromFirestore(), 0);
      expect(state.isSeedingData, isFalse);
    });

    test('4. Attendance Lateness: Compares against session start timestamp and grace period', () {
      final state = FellowshipState();

      // Case A: Checked in within 5 minutes of session start -> present
      state.startAttendanceWindow(durationSeconds: 1800);
      final livePin = state.activeSession.rollingPin;

      final studentA = UserModel(
        id: 'usr-student-a',
        fullName: 'Biniyam Girma',
        baptismalName: 'Wolde Giorgis',
        phoneNumber: '0911223344',
        batchYear: '2024',
        department: 'SE',
        academicYear: 2,
        role: UserRole.student,
        isApproved: true,
        badges: const [],
        ministryStatus: 'Active',
      );
      state.setCurrentUser(studentA);

      final successA = state.checkInStudent(
        studentId: studentA.id,
        enteredPinOrCode: livePin,
      );
      expect(successA, isTrue);
      expect(state.activeSession.scans.first.status, AttendanceStatus.present);
    });

    test('5. Money Integrity: Donations start as Pending and do not prematurely increment campaign', () async {
      final state = FellowshipState();

      final student = UserModel(
        id: 'usr-donor-1',
        fullName: 'Solomon Hailu',
        baptismalName: 'Gebre Kristos',
        phoneNumber: '0933445566',
        batchYear: '2024',
        department: 'Architecture',
        academicYear: 3,
        role: UserRole.student,
        isApproved: true,
        badges: const [],
        ministryStatus: 'Active',
      );
      state.setCurrentUser(student);

      final campaign = CharityCampaignModel(
        id: 'camp-orphanage-1',
        title: 'Debre Libanos Orphanage Support',
        description: 'Food and clothing assistance',
        targetAmount: 50000,
        raisedAmount: 5000,
        donorsCount: 10,
        deadline: DateTime.now().add(const Duration(days: 30)),
      );
      state.addCharityCampaign(campaign);

      // Student submits donation
      await state.submitCampaignDonation(
        campaignId: campaign.id,
        amount: 500,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TB-99887766',
      );

      // Ledger entry must be Pending (not Verified)
      final recordedPayment = state.duesPayments.firstWhere(
        (p) => p.transactionReference == 'TB-99887766',
      );
      expect(recordedPayment.status, 'Pending');

      // Campaign raisedAmount must NOT be bumped before treasurer verification
      final campInState = state.charityCampaigns.firstWhere(
        (c) => c.id == campaign.id,
      );
      expect(campInState.raisedAmount, 5000);
      expect(campInState.donorsCount, 10);

      // The donor cannot approve their own payment.
      await state.verifyDuesPayment(recordedPayment.id, true);
      expect(
        state.duesPayments.firstWhere((p) => p.id == recordedPayment.id).status,
        'Pending',
      );
      expect(
        state.charityCampaigns
            .firstWhere((c) => c.id == campaign.id)
            .raisedAmount,
        5000,
      );

      // When Treasurer verifies payment, campaign is updated atomically
      state.setCurrentUser(student.copyWith(role: UserRole.admin));
      await state.verifyDuesPayment(recordedPayment.id, true);
      final updatedCamp = state.charityCampaigns.firstWhere(
        (c) => c.id == campaign.id,
      );
      expect(updatedCamp.raisedAmount, 5500);
      expect(updatedCamp.donorsCount, 11);
      final verifiedPayment = state.duesPayments.firstWhere(
        (p) => p.id == recordedPayment.id,
      );
      expect(verifiedPayment.status, 'Verified');
    });

    test('6. Pilgrimage Capacity & Allocation: Trip full capacity blocks registration', () async {
      final state = FellowshipState();

      final fullTrip = PilgrimageTripModel(
        id: 'trip-full-1',
        title: 'Full Capacity Monastery Visit',
        destination: 'Zequala Monastery',
        departureDate: DateTime.now().add(const Duration(days: 10)),
        returnDate: DateTime.now().add(const Duration(days: 11)),
        departurePoint: 'Campus Gate 1',
        telebirrNumber: '0911000000',
        telebirrAccountName: 'Treasury',
        cbeAccountNumber: '1000123456789',
        cbeAccountName: 'Fellowship Treasury',
        feeAmount: 300,
        totalSeats: 45,
        bookedSeats: 45, // Fully booked
        itinerary: const ['Morning prayers', 'Monastery tour'],
        packingList: const ['Prayer book', 'Netela'],
        coordinatorName: 'Deacon Markos',
        coordinatorPhone: '0911223344',
      );
      await state.addPilgrimageTrip(fullTrip);

      final pilgrim = UserModel(
        id: 'usr-pilgrim-new',
        fullName: 'Kidus Yohannes',
        baptismalName: 'Yohannes',
        phoneNumber: '0944556677',
        batchYear: '2025',
        department: 'Medicine',
        academicYear: 1,
        role: UserRole.student,
        isApproved: true,
        badges: const [],
        ministryStatus: 'Active',
      );
      state.setCurrentUser(pilgrim);

      // Attempt registration on a fully booked trip
      await state.registerForTrip(
        tripId: fullTrip.id,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TB-TRIP-OVERCAP',
      );

      // Registration should be rejected and not added
      expect(
        state.allTripRegistrations.any(
          (r) => r.studentId == pilgrim.id && r.tripId == fullTrip.id,
        ),
        isFalse,
      );
    });

    test('7. UID-Only Identity Matching: User with duplicate name does not hijack account state', () {
      final state = FellowshipState();

      final loggedInUser = UserModel(
        id: 'usr-real-100',
        fullName: 'Abebe Bikila',
        baptismalName: 'Gebre Maryam',
        phoneNumber: '0911111111',
        batchYear: '2024',
        department: 'Civil Eng',
        academicYear: 3,
        role: UserRole.student,
        isApproved: true,
        badges: const [],
        ministryStatus: 'General',
      );
      state.setCurrentUser(loggedInUser);

      // Another user exists in the system with the exact same full name but different UID and admin role
      final duplicateNameUser = UserModel(
        id: 'usr-admin-999',
        fullName: 'Abebe Bikila',
        baptismalName: 'Wolde Mikael',
        phoneNumber: '0999999999',
        batchYear: '2022',
        department: 'History',
        academicYear: 4,
        role: UserRole.admin,
        isApproved: true,
        badges: const [],
        ministryStatus: 'Executive',
      );

      // Updating roles or directory operations for the duplicate-name user must NOT hijack currentUser
      state.assignUserRole(duplicateNameUser.id, UserRole.admin);

      // Current user identity, role, and capabilities must NOT be corrupted or overwritten by duplicate name
      expect(state.currentUser.id, 'usr-real-100');
      expect(state.currentUser.fullName, 'Abebe Bikila');
      expect(state.currentUser.role, UserRole.student);
      expect(state.isAdmin, isFalse);
      expect(state.canManageEmergencyAid, isFalse);
    });

    test('8. Pilgrimage seat cancellation & reallocation frees and reuses lowest available seat', () async {
      final state = FellowshipState();
      state.switchRole(UserRole.admin);

      final trip = PilgrimageTripModel(
        id: 'trip-seat-test',
        title: 'Monastery Pilgrimage',
        destination: 'Debre Damo',
        departureDate: DateTime.now().add(const Duration(days: 5)),
        returnDate: DateTime.now().add(const Duration(days: 6)),
        departurePoint: 'Fellowship Hall',
        telebirrNumber: '0911000000',
        telebirrAccountName: 'Treasury',
        cbeAccountNumber: '1000123456789',
        cbeAccountName: 'Treasury',
        feeAmount: 250,
        totalSeats: 10,
        bookedSeats: 0,
        occupiedSeats: const [],
        itinerary: const ['Departure', 'Liturgy'],
        packingList: const ['Bible'],
        coordinatorName: 'Deacon Yohannes',
        coordinatorPhone: '0911223344',
      );
      await state.addPilgrimageTrip(trip);

      // Register pilgrim 1 -> gets seat 1
      final reg1 = TripRegistrationModel(
        id: 'reg-1',
        tripId: trip.id,
        tripTitle: trip.title,
        studentId: 'stud-1',
        studentName: 'Student One',
        studentBaptismalName: 'Baptismal One',
        studentPhone: '0911000001',
        department: 'CS',
        academicYear: 1,
        busNumber: 1,
        seatNumber: 1,
        feeAmount: 250,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TX1',
        qrTicketCode: 'QR1',
        registeredAt: DateTime.now(),
      );
      final saved1 = await state.addPilgrimRegistration(reg1);
      expect(saved1, isNotNull);

      // Register pilgrim 2 -> gets seat 2
      final reg2 = TripRegistrationModel(
        id: 'reg-2',
        tripId: trip.id,
        tripTitle: trip.title,
        studentId: 'stud-2',
        studentName: 'Student Two',
        studentBaptismalName: 'Baptismal Two',
        studentPhone: '0911000002',
        department: 'CS',
        academicYear: 1,
        busNumber: 1,
        seatNumber: 2,
        feeAmount: 250,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TX2',
        qrTicketCode: 'QR2',
        registeredAt: DateTime.now(),
      );
      final saved2 = await state.addPilgrimRegistration(reg2);
      expect(saved2, isNotNull);

      // Register pilgrim 3 -> gets seat 3
      final reg3 = TripRegistrationModel(
        id: 'reg-3',
        tripId: trip.id,
        tripTitle: trip.title,
        studentId: 'stud-3',
        studentName: 'Student Three',
        studentBaptismalName: 'Baptismal Three',
        studentPhone: '0911000003',
        department: 'CS',
        academicYear: 1,
        busNumber: 1,
        seatNumber: 3,
        feeAmount: 250,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TX3',
        qrTicketCode: 'QR3',
        registeredAt: DateTime.now(),
      );
      final saved3 = await state.addPilgrimRegistration(reg3);
      expect(saved3, isNotNull);

      var currentTrip = state.pilgrimageTrips.firstWhere((t) => t.id == trip.id);
      expect(currentTrip.bookedSeats, 3);
      expect(currentTrip.occupiedSeats, [1, 2, 3]);

      // Cancel pilgrim 2's registration -> seat 2 is freed
      await state.deletePilgrimRegistration(saved2!.id);
      currentTrip = state.pilgrimageTrips.firstWhere((t) => t.id == trip.id);
      expect(currentTrip.bookedSeats, 2);
      expect(currentTrip.occupiedSeats, [1, 3]);

      // Register pilgrim 4 as current user -> must be allocated the lowest available seat (seat 2!)
      final student4 = UserModel(
        id: 'stud-4',
        fullName: 'Student Four',
        baptismalName: 'Tekle',
        phoneNumber: '0911000004',
        batchYear: '2024',
        department: 'CS',
        academicYear: 2,
        role: UserRole.student,
        isApproved: true,
        badges: const [],
        ministryStatus: 'Active',
      );
      state.setCurrentUser(student4);

      await state.registerForTrip(
        tripId: trip.id,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TB-SEAT-REALLOC-2',
      );

      currentTrip = state.pilgrimageTrips.firstWhere((t) => t.id == trip.id);
      expect(currentTrip.bookedSeats, 3);
      expect(currentTrip.occupiedSeats, containsAll([1, 2, 3]));

      final newReg = state.allTripRegistrations.firstWhere((r) => r.studentId == student4.id);
      expect(newReg.seatNumber, 2);
    });

    test('9. occupiedSeats serialization/deserialization round-trip', () {
      final trip = PilgrimageTripModel(
        id: 'trip-roundtrip',
        title: 'Trip Model Test',
        destination: 'Axum Tsion',
        departureDate: DateTime(2026, 11, 1),
        returnDate: DateTime(2026, 11, 3),
        departurePoint: 'Gate 2',
        telebirrNumber: '0911000000',
        telebirrAccountName: 'Treasury',
        cbeAccountNumber: '1000123456789',
        cbeAccountName: 'Treasury',
        feeAmount: 500,
        totalSeats: 30,
        bookedSeats: 3,
        occupiedSeats: const [1, 5, 9],
        itinerary: const ['Prayer'],
        packingList: const ['Book'],
        coordinatorName: 'Deacon Markos',
        coordinatorPhone: '0911000000',
      );

      final map = trip.toMap();
      expect(map['occupiedSeats'], [1, 5, 9]);

      final parsed = PilgrimageTripModel.fromMap(map, trip.id);
      expect(parsed.occupiedSeats, [1, 5, 9]);
      expect(parsed.nextAvailableSeat(), 2);
    });

    test('10. Timestamp and String date deserialization in models', () {
      final testDate = DateTime(2026, 8, 15, 10, 30);
      final timestamp = Timestamp.fromDate(testDate);
      final isoString = testDate.toIso8601String();

      // CharityCampaignModel
      final campTs = CharityCampaignModel.fromMap({'deadline': timestamp}, 'c1');
      expect(campTs.deadline, testDate);
      final campStr = CharityCampaignModel.fromMap({'deadline': isoString}, 'c2');
      expect(campStr.deadline, testDate);

      // EmergencyAidRequestModel
      final aidTs = EmergencyAidRequestModel.fromMap({'submittedAt': timestamp}, 'a1');
      expect(aidTs.submittedAt, testDate);
      final aidStr = EmergencyAidRequestModel.fromMap({'submittedAt': isoString}, 'a2');
      expect(aidStr.submittedAt, testDate);

      // MentorshipRequestModel
      final mentorTs = MentorshipRequestModel.fromMap({'requestedAt': timestamp}, 'm1');
      expect(mentorTs.requestedAt, testDate);
      final mentorStr = MentorshipRequestModel.fromMap({'requestedAt': isoString}, 'm2');
      expect(mentorStr.requestedAt, testDate);

      // ConfessionAppointmentModel
      final confTs = ConfessionAppointmentModel.fromMap({'scheduledDate': timestamp}, 'cf1');
      expect(confTs.scheduledDate, testDate);
      final confStr = ConfessionAppointmentModel.fromMap({'scheduledDate': isoString}, 'cf2');
      expect(confStr.scheduledDate, testDate);

      // FundraisingProposalModel
      final fundTs = FundraisingProposalModel.fromMap({
        'submittedAt': timestamp,
        'reviewedAt': timestamp,
      }, 'f1');
      expect(fundTs.submittedAt, testDate);
      expect(fundTs.reviewedAt, testDate);
      final fundStr = FundraisingProposalModel.fromMap({
        'submittedAt': isoString,
        'reviewedAt': isoString,
      }, 'f2');
      expect(fundStr.submittedAt, testDate);
      expect(fundStr.reviewedAt, testDate);

      // ChurchProgramModel
      final prgTs = ChurchProgramModel.fromMap({'dateTime': timestamp}, 'p1');
      expect(prgTs.dateTime, testDate);
      final prgStr = ChurchProgramModel.fromMap({'dateTime': isoString}, 'p2');
      expect(prgStr.dateTime, testDate);
    });

    test('11. canManageEmergencyAid RBAC verification across roles and coordinator profiles', () {
      final state = FellowshipState();

      // Admin has access
      state.switchRole(UserRole.admin);
      expect(state.canManageEmergencyAid, isTrue);

      // Member Care Coordinator has access
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptMemberCare,
      );
      expect(state.canManageEmergencyAid, isTrue);

      // Charity Coordinator has access
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptCharity,
      );
      expect(state.canManageEmergencyAid, isTrue);

      // Accounting Coordinator has access
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptFinanceProperty,
      );
      expect(state.canManageEmergencyAid, isTrue);

      // Audit Coordinator (read-only) does NOT have manage access
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptAudit,
      );
      expect(state.canManageEmergencyAid, isFalse);

      // Other department coordinator does NOT have access
      state.switchRole(
        UserRole.volunteerCoordinator,
        coordinatorDeptId: FellowshipDepartmentConstants.deptChoir,
      );
      expect(state.canManageEmergencyAid, isFalse);

      // General student does NOT have access
      state.switchRole(UserRole.student);
      expect(state.canManageEmergencyAid, isFalse);
    });

    test('12. Notification Overhaul: hasUpcomingProgram and isProgramCurrentlyLive getters', () async {
      final state = FellowshipState();

      // Initially no programs scheduled: hasUpcomingProgram is false, isProgramCurrentlyLive is false
      expect(state.hasUpcomingProgram, isFalse);
      expect(state.isProgramCurrentlyLive, isFalse);

      // Schedule a program in the future (3 hours from now)
      final futureTime = DateTime.now().add(const Duration(hours: 3));
      await state.scheduleChurchProgram(
        title: 'Upcoming Evening Prayer',
        description: 'Vespers at St. Mary',
        churchName: "St. Mary's Orthodox Church",
        dateTime: futureTime,
        category: 'Prayer',
      );

      expect(state.hasUpcomingProgram, isTrue);
      expect(state.isProgramCurrentlyLive, isFalse);

      // Schedule a program that started 30 minutes ago (currently in session)
      final liveTime = DateTime.now().subtract(const Duration(minutes: 30));
      await state.scheduleChurchProgram(
        title: 'Ongoing Holy Liturgy',
        description: 'Live service',
        churchName: "St. Mary's Orthodox Church",
        dateTime: liveTime,
        category: 'Liturgy',
      );

      expect(state.isProgramCurrentlyLive, isTrue);
    });
  });
}

