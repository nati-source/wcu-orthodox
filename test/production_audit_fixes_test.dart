import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/models/attendance_models.dart';
import 'package:wcu_orthodox/models/charity_models.dart';
import 'package:wcu_orthodox/models/pilgrimage_models.dart';
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
  });
}
