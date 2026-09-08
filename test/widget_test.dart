import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/main.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WCU Orthodox App smoke & role switcher test', (WidgetTester tester) async {
    await tester.pumpWidget(const WcuOrthodoxApp());
    await tester.pumpAndSettle();

    // Verify initial Student Header and Liturgy section
    expect(find.text('Wachamo University Fellowship'), findsOneWidget);
    expect(find.text('Upcoming Liturgy'), findsOneWidget);
  });

  test('FellowshipState logic test: constrained matching and rolling pin check-in', () async {
    final state = FellowshipState();

    expect(state.allStudents.isNotEmpty, true);
    expect(state.families.isNotEmpty, true);

    // Test Smart Matching
    await state.runSmartMatching();
    for (final fam in state.families) {
      expect(fam.memberIds.isNotEmpty, true);
    }

    // Test Check-In with correct PIN
    final activePin = state.activeSession.rollingPin;
    final checkInSuccess = state.checkInStudent(
      studentId: state.currentUser.id,
      enteredPinOrCode: activePin,
      method: AttendanceCheckInMethod.pin,
    );
    expect(checkInSuccess, true);

    // Test Invalid PIN
    final checkInFail = state.checkInStudent(
      studentId: 'usr-random',
      enteredPinOrCode: '000000',
      method: AttendanceCheckInMethod.pin,
    );
    expect(checkInFail, false);
  });

  test('Domain tests: Liturgical Calendar, Prayer Book, Pilgrimage & Mentorship', () {
    final state = FellowshipState();

    // 1. Liturgical Calendar
    expect(state.calendarWeek.isNotEmpty, true);
    expect(state.currentCalendarDay.geezDateString.isNotEmpty, true);

    // 2. Prayer Book
    expect(state.wudaseMaryam.sections.length, 7);
    expect(state.yezewetirTselot.sections.isNotEmpty, true);

    // 3. Father Confessor
    expect(state.confessorFathers.isNotEmpty, true);
    state.bookConfessionAppointment(
      fatherId: state.confessorFathers.first.id,
      scheduledDate: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '3:00 PM - 5:30 PM',
      topic: 'Holy Communion Preparation',
    );
    expect(state.myConfessionAppointments.isNotEmpty, true);

    // 4. Pilgrimage Trips (Telebirr / Free)
    expect(state.pilgrimageTrips.isNotEmpty, true);
    final paidTrip = state.pilgrimageTrips.firstWhere((t) => !t.isFree);
    state.registerForTrip(
      tripId: paidTrip.id,
      paymentMethod: PaymentMethodType.telebirr,
      transactionReference: 'TB-TEST-123456',
    );
    expect(state.myTripRegistrations.any((r) => r.tripId == paidTrip.id), true);

    // 5. Charity & Dues
    state.submitDuesPayment(
      amount: 50.0,
      purpose: 'Monthly Dues',
      paymentMethod: PaymentMethodType.telebirr,
      transactionReference: 'TB-DUES-123',
    );
    expect(state.duesPayments.any((d) => d.transactionReference == 'TB-DUES-123'), true);

    // 6. Department Mentorship
    expect(state.academicMentors.isNotEmpty, true);
    state.requestMentorship(
      mentorId: state.academicMentors.first.id,
      coursesNeeded: 'Data Structures',
    );
    expect(state.myMentorshipRequests.isNotEmpty, true);

    // 7. Faith Trivia Challenge
    expect(state.triviaQuizzes.isNotEmpty, true);
    state.submitQuizAttempt(
      quizId: state.triviaQuizzes.first.id,
      score: 5,
      totalQuestions: 5,
    );
    expect(state.quizAttempts.isNotEmpty, true);
    expect(state.familyLeaderboard.isNotEmpty, true);

    // 8. 10 EOTC Fellowship Departments & Coordinator Recruitment Delegation
    expect(state.ministries.length, 10);
    final musicDept = state.ministries.firstWhere((m) => m.id == 'dept-music');
    expect(musicDept.titleAmharic, 'መዝሙርና ስነ ጥበባት');
    expect(musicDept.teamLead, 'Dawit Fikadu');
    expect(musicDept.subWings.isNotEmpty, true);

    // Test student applying to Music & Arts
    state.submitMinistryApplication(
      ministryId: 'dept-music',
      reason: 'Singing ancient Yaredic hymns',
      experience: '2 years parish church choir',
      availability: 'Wednesdays and Saturdays',
      studentYear: '2nd Year',
      preferredSubWing: 'Begena & Instruments (የበገናና መሳሪያዎች)',
    );

    // Verify Coordinator Queue Filtering
    final musicApps = state.getApplicationsForDepartment('dept-music');
    expect(musicApps.isNotEmpty, true);
    final newApp = musicApps.first;
    expect(newApp.preferredSubWing, 'Begena & Instruments (የበገናና መሳሪያዎች)');

    // Test Coordinator approving candidate
    final initialRosterCount = state.getMembersForDepartment('dept-music').length;
    state.approveVolunteerApplication(
      newApp.id,
      notes: 'Welcome! Rehearsal is Wednesday 4 PM.',
      reviewedBy: 'Dawit Fikadu (Music Coordinator)',
    );
    expect(state.getMembersForDepartment('dept-music').length, initialRosterCount + 1);

    // 9. Priests & Schedules Management Test
    final initialPriests = state.confessorFathers.length;
    final newPriest = const ConfessorFatherModel(
      id: 'fat-new-test',
      fullName: 'Kesis Daniel Mulugeta',
      clericalTitle: 'መልአከ ብርሃን ቀሲስ',
      churchName: "St. Gabriel's Church",
      meetingVenue: 'Campus Chapel Room 1',
      phoneNumber: '+251911998877',
      availableDays: ['Saturday', 'Sunday'],
      availableTimeSlots: ['4:00 PM - 6:00 PM'],
      bio: 'Youth confessor and spiritual counselor',
    );
    state.addConfessorFather(newPriest);
    expect(state.confessorFathers.length, initialPriests + 1);

    // Update Priest Venue
    state.updateConfessorFather(newPriest.copyWith(meetingVenue: 'Youth Hall Room 3'));
    final updatedPriest = state.confessorFathers.firstWhere((f) => f.id == 'fat-new-test');
    expect(updatedPriest.meetingVenue, 'Youth Hall Room 3');

    // Confirm Appointment with Note/Venue
    final apptId = state.myConfessionAppointments.first.id;
    state.confirmConfessionAppointment(apptId, notes: 'Meet at Youth Hall Room 3 at 4 PM');
    final updatedAppt = state.confessionAppointments.firstWhere((a) => a.id == apptId);
    expect(updatedAppt.status, ConfessionAppointmentStatus.confirmed);
    expect(updatedAppt.notes, 'Meet at Youth Hall Room 3 at 4 PM');

    // 10. Theme Palette Switching Test
    expect(state.currentThemePalette, AppThemePalette.midnightFellowship);
    state.setThemePalette(AppThemePalette.parchmentIncense);
    expect(state.currentThemePalette, AppThemePalette.parchmentIncense);
    state.setThemePalette(AppThemePalette.axumiteEmerald);
    expect(state.currentThemePalette, AppThemePalette.axumiteEmerald);

    // 11. WCU Departments List Test
    expect(WcuDepartments.all.length >= 55, true);
    expect(WcuDepartments.all.contains('Computer Science'), true);
    expect(WcuDepartments.all.contains('Architecture'), true);
    expect(WcuDepartments.all.contains('Medicine'), true);
    expect(WcuDepartments.all.contains('Law'), true);
    expect(WcuDepartments.all.contains('Curriculum and Instruction'), true);
  });
}



