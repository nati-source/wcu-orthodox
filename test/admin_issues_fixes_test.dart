import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/models/pilgrimage_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Admin Issues & Local Testing Fixes Verification', () {
    test(
      '1. Registration approval isolation: student must not be auto-approved',
      () {
        final state = FellowshipState();

        // Register a regular student
        state.registerStudent(
          fullName: 'Dawit Abebe',
          baptismalName: 'Haile Giorgis',
          phoneNumber: '+251911999999',
          batchYear: '2025',
          department: 'Software Engineering',
          academicYear: 2,
        );

        // Student must NOT be approved
        expect(state.currentUser.isApproved, isFalse);
        expect(
          state.pendingApprovals.any((s) => s.id == state.currentUser.id),
          isTrue,
        );
      },
    );

    test('2. Digital Pass Isolation: Admin/user must only see their own digital passes', () async {
      final state = FellowshipState();

      // Current user is Admin
      final adminUser = UserModel(
        id: 'usr-admin-1',
        fullName: 'Admin Nati',
        baptismalName: 'Gebre Maryam',
        phoneNumber: '+251911000000',
        batchYear: '2023',
        department: 'CS',
        academicYear: 4,
        role: UserRole.admin,
        isApproved: true,
        badges: const [],
        ministryStatus: 'Leader',
        assignedFamilyId: 'fam-1',
        attendancePercentage: 100,
      );
      state.setCurrentUser(adminUser);

      // Add a pilgrimage trip
      final trip = PilgrimageTripModel(
        id: 'trip-debre-libanos',
        title: 'Debre Libanos Pilgrimage',
        destination: 'Debre Libanos',
        departureDate: DateTime.now().add(const Duration(days: 5)),
        returnDate: DateTime.now().add(const Duration(days: 6)),
        departurePoint: 'Main Gate',
        telebirrNumber: '0911000000',
        telebirrAccountName: 'Fellowship',
        cbeAccountNumber: '1000123456',
        cbeAccountName: 'Fellowship',
        totalSeats: 50,
        bookedSeats: 0,
        itinerary: const ['Prayer'],
        packingList: const ['Cross'],
        coordinatorName: 'Kesis',
        coordinatorPhone: '0911000000',
      );
      state.addPilgrimageTrip(trip);

      // Add a registration belonging to a DIFFERENT student (Abebe)
      final otherStudentReg = TripRegistrationModel(
        id: 'reg-student-abebe',
        tripId: trip.id,
        tripTitle: trip.title,
        studentId: 'usr-student-abebe',
        studentName: 'Abebe Kebede',
        studentBaptismalName: 'Walda Rufael',
        studentPhone: '+251922334455',
        department: 'Economics',
        academicYear: 3,
        busNumber: 1,
        seatNumber: 1,
        feeAmount: 300,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TXN123456',
        paymentStatus: TripPaymentStatus.verified,
        qrTicketCode: 'PILGRIM-DEBR-ABEB',
        registeredAt: DateTime.now(),
      );

      // Coordinator/Admin registers Abebe into passenger list
      await state.addPilgrimRegistration(otherStudentReg);

      // Verify that allTripRegistrations contains Abebe's registration
      expect(state.allTripRegistrations.length, 1);
      expect(
        state.allTripRegistrations.first.id,
        '${trip.id}_${otherStudentReg.studentId}',
      );

      // CRITICAL: Abebe's digital pass MUST NOT appear in Admin's personal passes!
      expect(state.myTripRegistrations, isEmpty);

      // Now, Admin registers for their own ticket on the same trip
      await state.registerForTrip(
        tripId: trip.id,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'ADMIN-TXN-777',
      );

      // Admin's myTripRegistrations must contain exactly 1 ticket (Admin's own ticket)
      expect(state.myTripRegistrations.length, 1);
      expect(state.myTripRegistrations.first.studentId, adminUser.id);
      expect(state.myTripRegistrations.first.studentName, adminUser.fullName);

      // Total passenger registrations for the trip is 2, but Admin only sees 1 in digital passes
      expect(state.allTripRegistrations.length, 2);
    });

    test(
      '3. Profile Editing: saveUserProfile updates local state and attributes',
      () async {
        final state = FellowshipState();

        final initialUser = UserModel(
          id: 'usr-edit-test',
          fullName: 'Initial Name',
          baptismalName: 'Initial Baptismal',
          phoneNumber: '+251911111111',
          batchYear: '2023',
          department: 'Physics',
          academicYear: 2,
          role: UserRole.admin,
          isApproved: true,
          badges: const [],
          ministryStatus: 'Member',
          assignedFamilyId: 'fam-1',
          attendancePercentage: 90,
        );
        state.setCurrentUser(initialUser);

        bool notified = false;
        state.addListener(() {
          notified = true;
        });

        await state.saveUserProfile(
          fullName: 'Natnael Daniel Updated',
          baptismalName: 'Haile Maryam Updated',
          phoneNumber: '+251999887766',
          department: 'Software Engineering',
          academicYear: 4,
          batchYear: '2025',
          gender: 'male',
        );

        expect(notified, isTrue);
        expect(state.currentUser.fullName, 'Natnael Daniel Updated');
        expect(state.currentUser.baptismalName, 'Haile Maryam Updated');
        expect(state.currentUser.phoneNumber, '+251999887766');
        expect(state.currentUser.department, 'Software Engineering');
        expect(state.currentUser.academicYear, 4);
        expect(state.currentUser.batchYear, '2025');
        expect(state.currentUser.gender, 'male');
      },
    );
  });
}
