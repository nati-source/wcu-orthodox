import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/main.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/admin/admin_approvals_screen.dart';
import 'package:wcu_orthodox/views/coordinator/coordinator_hub_screen.dart';
import 'package:wcu_orthodox/views/student/student_roadmap_screen.dart';
import 'package:wcu_orthodox/views/student/student_family_screen.dart';
import 'package:wcu_orthodox/views/student/student_home_screen.dart';
import 'package:wcu_orthodox/views/student/student_library_screen.dart';
import 'package:wcu_orthodox/views/student/student_qr_scanner_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('WCU Orthodox App smoke & role switcher test', (WidgetTester tester) async {
    final state = FellowshipState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StudentHomeScreen(
            state: state,
            onNavigateTab: (_) {},
            onOpenScanner: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify initial Student Header and Liturgy section
    expect(find.text('Upcoming Liturgy'), findsOneWidget);
    state.dispose();
  });

  test('FellowshipDepartmentConstants mapping & normalization test', () {
    // 10 Official EOTC Fellowship Departments
    expect(FellowshipDepartmentConstants.allDepartmentIds.length, 10);
    expect(FellowshipDepartmentConstants.deptEducation, 'dept-apostolic');
    expect(FellowshipDepartmentConstants.deptMemberCare, 'dept-membercare');
    expect(FellowshipDepartmentConstants.deptChoirArts, 'dept-music');
    expect(FellowshipDepartmentConstants.deptDevelopment, 'dept-development');
    expect(FellowshipDepartmentConstants.deptFinanceProperty, 'dept-accounting');
    expect(FellowshipDepartmentConstants.deptBatchPrograms, 'dept-programs');
    expect(FellowshipDepartmentConstants.deptCharity, 'dept-charity');
    expect(FellowshipDepartmentConstants.deptSpecialNeeds, 'dept-language');
    expect(FellowshipDepartmentConstants.deptPlanning, 'dept-planning');
    expect(FellowshipDepartmentConstants.deptAudit, 'dept-audit');

    // Test Amharic Name lookups
    expect(FellowshipDepartmentConstants.getNameAmharic(FellowshipDepartmentConstants.deptEducation), 'ትምህርትና ሐዋርያዊ አገልግሎት');
    expect(FellowshipDepartmentConstants.getNameAmharic(FellowshipDepartmentConstants.deptChoirArts), 'መዝሙርና ስነ ጥበባት');
    expect(FellowshipDepartmentConstants.getNameAmharic(FellowshipDepartmentConstants.deptCharity), 'ሙያና በጎ አድራጎት');
    expect(FellowshipDepartmentConstants.getNameAmharic(FellowshipDepartmentConstants.deptAudit), 'ኦዲትና ኢንስፔክሽን');

    // Test English Name lookups
    expect(FellowshipDepartmentConstants.getNameEn(FellowshipDepartmentConstants.deptEducation), 'Education & Apostolic Ministry');
    expect(FellowshipDepartmentConstants.getNameEn(FellowshipDepartmentConstants.deptAudit), 'Audit & Inspection');

    // Test normalization
    expect(FellowshipDepartmentConstants.normalizeDepartmentId('DEPT_EDUCATION'), 'dept-apostolic');
    expect(FellowshipDepartmentConstants.normalizeDepartmentId('DEPT_CHOIR_ARTS'), 'dept-music');
    expect(FellowshipDepartmentConstants.normalizeDepartmentId('DEPT_AUDIT'), 'dept-audit');
    expect(FellowshipDepartmentConstants.normalizeDepartmentId('dept-charity'), 'dept-charity');
  });

  test('Scoped RBAC: Department Coordinator & Audit Inspection permissions test', () {
    final state = FellowshipState();

    // 1. Normal Student: Denied coordinator actions
    state.switchRole(UserRole.student);
    expect(state.canAccessDepartmentRead(FellowshipDepartmentConstants.deptChoirArts), false);
    expect(state.canAccessDepartmentWrite(FellowshipDepartmentConstants.deptChoirArts), false);

    // 2. Music Coordinator (DEPT_CHOIR_ARTS): Scoped to dept-music
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptChoirArts);
    expect(state.currentUser.coordinatorProfile?.departmentId, 'dept-music');
    expect(state.currentUser.coordinatorProfile?.isReadOnlyAudit, false);
    expect(state.currentUser.coordinatorProfile?.canApproveApplicants, true);

    // Can read & write in their own department
    expect(state.canAccessDepartmentRead('dept-music'), true);
    expect(state.canAccessDepartmentWrite('dept-music'), true);

    // Denied read & write in other departments (scoped isolation)
    expect(state.canAccessDepartmentRead('dept-charity'), false);
    expect(state.canAccessDepartmentWrite('dept-charity'), false);
    expect(state.canAccessDepartmentWrite('dept-accounting'), false);

    // 3. Switch Coordinator to Charity Department (DEPT_CHARITY)
    state.switchCoordinatorDepartment(FellowshipDepartmentConstants.deptCharity);
    expect(state.currentUser.coordinatorProfile?.departmentId, 'dept-charity');
    expect(state.canAccessDepartmentRead('dept-charity'), true);
    expect(state.canAccessDepartmentWrite('dept-charity'), true);
    expect(state.canAccessDepartmentWrite('dept-music'), false);

    // 4. Audit Coordinator (DEPT_AUDIT): Read-only inspection across all 10 departments, WRITE BLOCKED
    state.switchCoordinatorDepartment(FellowshipDepartmentConstants.deptAudit);
    expect(state.currentUser.coordinatorProfile?.isReadOnlyAudit, true);
    expect(state.currentUser.coordinatorProfile?.canApproveApplicants, false);

    // Read access allowed across all departments for audit inspection
    for (final deptId in FellowshipDepartmentConstants.allDepartmentIds) {
      expect(state.canAccessDepartmentRead(deptId), true);
    }
    // Write access strictly BLOCKED across all departments
    for (final deptId in FellowshipDepartmentConstants.allDepartmentIds) {
      expect(state.canAccessDepartmentWrite(deptId), false);
    }

    // 5. Global Admin: Full system-wide read & write access
    state.switchRole(UserRole.admin);
    for (final deptId in FellowshipDepartmentConstants.allDepartmentIds) {
      expect(state.canAccessDepartmentRead(deptId), true);
      expect(state.canAccessDepartmentWrite(deptId), true);
    }
  });

  test('Scoped RBAC: Volunteer Application Approval & Rejection Mutation Guards', () {
    final state = FellowshipState();

    // Submit an application for Music Department
    state.submitMinistryApplication(
      ministryId: FellowshipDepartmentConstants.deptChoirArts,
      reason: 'Yaredic Choir Singing',
      experience: 'Choir member',
      availability: 'Wednesdays',
      preferredSubWing: 'Choir Vocal & Zema (የዝማሬና ዜማ ዘርፍ)',
    );

    final apps = state.getApplicationsForDepartment('dept-music');
    expect(apps.isNotEmpty, true);
    final targetApp = apps.first;

    // Normal student cannot approve
    state.switchRole(UserRole.student);
    state.approveVolunteerApplication(targetApp.id);
    expect(state.volunteerApplications.firstWhere((a) => a.id == targetApp.id).status, ApplicationStatus.pending);

    // Charity coordinator CANNOT approve Music department application (wrong department)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptCharity);
    state.approveVolunteerApplication(targetApp.id);
    expect(state.volunteerApplications.firstWhere((a) => a.id == targetApp.id).status, ApplicationStatus.pending);

    // Audit coordinator CANNOT approve (read-only audit)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptAudit);
    state.approveVolunteerApplication(targetApp.id);
    expect(state.volunteerApplications.firstWhere((a) => a.id == targetApp.id).status, ApplicationStatus.pending);

    // Music coordinator CAN approve Music department application
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptChoirArts);
    state.approveVolunteerApplication(targetApp.id, notes: 'Approved for Zema wing');
    expect(state.volunteerApplications.firstWhere((a) => a.id == targetApp.id).status, ApplicationStatus.approved);
  });

  test('Spiritual Parent: Scoped Roadmap Access Guard test', () {
    final state = FellowshipState();

    // Family of St. George has member IDs: ['usr-current', 'usr-1', 'usr-2', 'usr-3', 'usr-4']
    // Family of St. Teklehaimanot has member IDs: ['usr-5', 'usr-6', 'usr-7']

    // 1. Spiritual Parent of St. George Family
    state.switchRole(UserRole.spiritualParent);
    expect(state.spiritualChildren.isNotEmpty, true);

    // Can access spiritual children in own family
    expect(state.canAccessStudentRoadmap('usr-1'), true);
    expect(state.canAccessStudentRoadmap('usr-2'), true);
    expect(state.canAccessStudentRoadmap('usr-3'), true);
    expect(state.canAccessStudentRoadmap('usr-4'), true);
    expect(state.getRoadmapsForStudent('usr-1').isNotEmpty, true);

    // DENIED access to students in another family
    expect(state.canAccessStudentRoadmap('usr-5'), false);
    expect(state.canAccessStudentRoadmap('usr-6'), false);
    expect(state.canAccessStudentRoadmap('usr-7'), false);
    expect(state.getRoadmapsForStudent('usr-5').isEmpty, true);

    // 2. Normal Student
    state.switchRole(UserRole.student);
    expect(state.canAccessStudentRoadmap(state.currentUser.id), true); // Own roadmap
    expect(state.canAccessStudentRoadmap('usr-1'), false); // Other student's roadmap denied

    // 3. Global Admin
    state.switchRole(UserRole.admin);
    expect(state.canAccessStudentRoadmap('usr-1'), true);
    expect(state.canAccessStudentRoadmap('usr-5'), true);
    expect(state.getRoadmapsForStudent('usr-5').isNotEmpty, true);
  });

  test('FellowshipState logic test: constrained matching and rolling pin check-in', () async {
    final state = FellowshipState();

    expect(state.allStudents.isNotEmpty, true);
    expect(state.families.isNotEmpty, true);

    // Test Smart Matching (requires admin / family manager role)
    state.switchRole(UserRole.admin);
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

    // 9. Priests & Schedules Management Test (Admin role)
    state.switchRole(UserRole.admin);
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

  test('Department Capabilities: Broadcast Engine & Guest Teacher Notice Test', () {
    final state = FellowshipState();

    // 1. Send broadcast as Education Coordinator (DEPT_EDUCATION)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptEducation);
    expect(state.canPublishSpecialTeacherNotice, true);

    state.sendDepartmentBroadcast(
      departmentId: FellowshipDepartmentConstants.deptEducation,
      title: 'Urgent Apostolic Wing Meeting',
      body: 'Reviewing curriculum for next semester preaching programs.',
      urgency: 'urgent',
      meetingLocation: 'Hall 3, 2nd Floor',
      meetingTime: DateTime.now().add(const Duration(hours: 4)),
    );

    final eduBroadcasts = state.getBroadcastsForDepartment(FellowshipDepartmentConstants.deptEducation);
    expect(eduBroadcasts.any((b) => b.title == 'Urgent Apostolic Wing Meeting'), true);

    // 2. Publish Guest Preacher / Teacher Notice (DEPT_EDUCATION privilege)
    state.publishSpecialGuestTeacherNotice(
      teacherName: 'Memhir Girma Wondimu',
      teacherTitle: 'ሊቀ ማእምራን',
      topic: 'The Orthodox Christology in Patristic Era',
      venue: 'Main Campus Spiritual Auditorium',
      dateAndTime: DateTime.now().add(const Duration(days: 3)),
      description: 'All students are invited. Special translation available.',
    );

    final specialNotices = state.departmentBroadcasts.where((b) => b.isSpecialTeacherNotice).toList();
    expect(specialNotices.any((n) => n.title.contains('Memhir Girma Wondimu')), true);

    // 3. Charity Coordinator cannot broadcast into Education Department
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptCharity);
    final countBefore = state.departmentBroadcasts.length;
    state.sendDepartmentBroadcast(
      departmentId: FellowshipDepartmentConstants.deptEducation,
      title: 'Unauthorized Message',
      body: 'This should be blocked',
    );
    expect(state.departmentBroadcasts.length, countBefore);
  });

  test('Department Capabilities: Development Fundraising Proposals & Admin Review Test', () {
    final state = FellowshipState();

    // 1. Submit proposal as Development Coordinator (DEPT_DEVELOPMENT)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptDevelopment);
    expect(state.canSubmitFundraisingProposal, true);

    state.submitFundraisingProposal(
      title: 'Campus Begena & Sacred Art Charity Exhibition',
      objective: 'Handcrafted cross sales and sacred iconography exhibition to fund student aid.',
      targetAmount: 45000.0,
      expectedExpenses: 8000.0,
      category: 'Sacred Artifacts Expo',
      timelineOrDuration: '3 Weeks (Meskerem 15 - Tikimt 5)',
      proposedStrategy: '1 Month exhibition in campus hall with alumni invitations',
      targetAudience: '50 needy freshmen students for stationery and cafeteria support',
    );

    expect(state.fundraisingProposals.any((p) => p.title == 'Campus Begena & Sacred Art Charity Exhibition'), true);
    final proposal = state.fundraisingProposals.firstWhere((p) => p.title == 'Campus Begena & Sacred Art Charity Exhibition');
    expect(proposal.status, ProposalStatus.pending);
    expect(proposal.category, 'Sacred Artifacts Expo');
    expect(proposal.expectedExpenses, 8000.0);
    expect(proposal.netExpectedProceeds, 37000.0);

    // 2. Update proposal as coordinator
    final updated = proposal.copyWith(
      targetAmount: 50000.0,
      expectedExpenses: 9000.0,
      objective: 'Updated objective with increased student coverage.',
    );
    state.updateFundraisingProposal(updated);
    final fetchedUpdated = state.fundraisingProposals.firstWhere((p) => p.id == proposal.id);
    expect(fetchedUpdated.targetAmount, 50000.0);
    expect(fetchedUpdated.netExpectedProceeds, 41000.0);

    // 3. Non-admin coordinator cannot approve proposals
    state.reviewFundraisingProposal(
      proposalId: proposal.id,
      status: ProposalStatus.approved,
      adminNotes: 'Unauthorized approval attempt',
    );
    expect(state.fundraisingProposals.firstWhere((p) => p.id == proposal.id).status, ProposalStatus.pending);

    // 4. Admin approves proposal with executive review notes
    state.switchRole(UserRole.admin);
    state.reviewFundraisingProposal(
      proposalId: proposal.id,
      status: ProposalStatus.approved,
      adminNotes: 'Approved by Executive Committee. Budget allocation sanctioned.',
    );
    final approvedProp = state.fundraisingProposals.firstWhere((p) => p.id == proposal.id);
    expect(approvedProp.status, ProposalStatus.approved);
    expect(approvedProp.adminReviewNotes, 'Approved by Executive Committee. Budget allocation sanctioned.');

    // 5. Delete / withdraw a proposal test
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptDevelopment);
    state.submitFundraisingProposal(
      title: 'Temporary Draft Proposal',
      objective: 'Draft only',
      targetAmount: 5000.0,
      expectedExpenses: 500.0,
      proposedStrategy: 'Test strategy',
      targetAudience: 'Test audience',
    );
    final tempProp = state.fundraisingProposals.firstWhere((p) => p.title == 'Temporary Draft Proposal');
    expect(state.fundraisingProposals.any((p) => p.id == tempProp.id), true);
    state.deleteFundraisingProposal(tempProp.id);
    expect(state.fundraisingProposals.any((p) => p.id == tempProp.id), false);
  });

  test('Department Capabilities: Dual Choir Wings (Mezmur & Fine Arts) & Multilingual Gated Applications', () {
    final state = FellowshipState();

    // 1. Submit application to Choir & Fine Arts with Fine Arts Wing
    state.submitMinistryApplication(
      ministryId: FellowshipDepartmentConstants.deptChoirArts,
      reason: 'Passion for Orthodox Iconography and drama',
      experience: 'Church artist for 3 years',
      availability: 'Sunday mornings',
      preferredSubWing: 'Fine Arts (ስነ ጥበባት)',
      choirWing: ChoirWingType.fineArts,
    );

    final choirApp = state.volunteerApplications.firstWhere((a) => a.choirWing == ChoirWingType.fineArts);
    expect(choirApp.ministryId, 'dept-music');
    expect(choirApp.choirWing, ChoirWingType.fineArts);

    // Approve as Choir Coordinator
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptChoirArts);
    state.approveVolunteerApplication(choirApp.id, reviewedBy: 'Martha Tedla (Fine Arts Lead)');

    final newMember = state.departmentMembers.firstWhere((m) => m.studentId == choirApp.studentId && m.departmentId == 'dept-music');
    expect(newMember.choirWing, ChoirWingType.fineArts);

    // 2. Submit application to Special Needs with multiple languages
    state.submitMinistryApplication(
      ministryId: FellowshipDepartmentConstants.deptSpecialNeeds,
      reason: 'Willing to translate and provide sign language assistance',
      experience: 'Fluent in Afan Oromo, Tigrinya, and certified in Ethiopian Sign Language',
      availability: 'Flexible',
      preferredSubWing: 'Sign Language & Multilingual Apostolic',
      languagesKnown: ['Amharic (አማርኛ)', 'Afan Oromo (Afaan Oromoo)', 'Sign Language (የምልክት ቋንቋ)'],
    );

    final langApp = state.volunteerApplications.firstWhere((a) => a.ministryId == 'dept-language');
    expect(langApp.languagesKnown.length, 3);
    expect(langApp.languagesKnown.contains('Sign Language (የምልክት ቋንቋ)'), true);
  });

  test('Department Capabilities: Batch Programs Pilgrimage Suite & Charity Mutual Aid Suite Test', () {
    final state = FellowshipState();

    // 1. Pilgrimage Suite: Coordinator privileges (DEPT_BATCH_PROGRAMS)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptBatchPrograms);
    expect(state.canManagePilgrimages, true);

    // Add new pilgrimage trip
    final newTrip = PilgrimageTripModel(
      id: 'trip-waldiba-test',
      title: 'የዋልድባ ገዳም ጉዞ',
      destination: 'Waldiba Monastery',
      departureDate: DateTime.now().add(const Duration(days: 30)),
      returnDate: DateTime.now().add(const Duration(days: 34)),
      departurePoint: 'Main Gate',
      feeAmount: 1200.0,
      totalSeats: 60,
      bookedSeats: 0,
      telebirrNumber: '+251911223344',
      telebirrAccountName: 'WCU EOTC Fellowship',
      cbeAccountNumber: '1000123456789',
      cbeAccountName: 'WCU Orthodox Christian Fellowship',
      itinerary: ['Day 1: Departure', 'Day 2: Monastery Prayer'],
      packingList: ['Netela', 'Bible'],
      coordinatorName: 'Ermias Tesfaye',
      coordinatorPhone: '+251911223344',
    );
    state.addPilgrimageTrip(newTrip);

    expect(state.pilgrimageTrips.any((t) => t.destination == 'Waldiba Monastery'), true);
    final createdTrip = state.pilgrimageTrips.firstWhere((t) => t.destination == 'Waldiba Monastery');

    // Register student for trip
    state.registerForTrip(
      tripId: createdTrip.id,
      paymentMethod: PaymentMethodType.telebirr,
      transactionReference: 'TB-WALDIBA-999',
    );

    final reg = state.allTripRegistrations.firstWhere((r) => r.tripId == createdTrip.id);
    expect(reg.isBoarded, false);

    // Verify payment and Scan Boarding Ticket on Bus
    state.verifyTripPayment(reg.id, true);
    final verifiedReg = state.allTripRegistrations.firstWhere((r) => r.id == reg.id);
    expect(verifiedReg.paymentStatus, TripPaymentStatus.verified);

    // Bus QR Boarding scan
    final scanResult = state.scanBusBoardingTicket(reg.qrTicketCode);
    expect(scanResult, true);
    expect(state.allTripRegistrations.firstWhere((r) => r.id == reg.id).isBoarded, true);

    // 2. Charity Suite: Coordinator privileges (DEPT_CHARITY)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptCharity);
    expect(state.canManageCharityAndAid, true);

    // Add charity campaign
    final newCamp = CharityCampaignModel(
      id: 'camp-test-aid',
      title: 'የተማሪዎች ደብተርና እስክሪብቶ ድጋፍ',
      description: 'ለአቅመ ደካማ ተማሪዎች የትምህርት መርጃ ማሰባሰቢያ',
      targetAmount: 20000.0,
      raisedAmount: 0.0,
      donorsCount: 0,
      deadline: DateTime.now().add(const Duration(days: 15)),
      category: 'Student Mutual Aid',
    );
    state.addCharityCampaign(newCamp);
    expect(state.charityCampaigns.any((c) => c.title == 'የተማሪዎች ደብተርና እስክሪብቶ ድጋፍ'), true);

    // Emergency Aid Verification & Disbursement (Scoped to DEPT_MEMBER_CARE only)
    if (state.emergencyAidRequests.isNotEmpty) {
      final targetAid = state.emergencyAidRequests.first;
      // DEPT_CHARITY coordinator is blocked from emergency aid
      expect(state.canManageEmergencyAid, false);
      state.verifyEmergencyAid(
        targetAid.id,
        EmergencyAidStatus.approved,
        adminNote: 'Attempt by Charity coordinator',
      );
      expect(state.emergencyAidRequests.firstWhere((a) => a.id == targetAid.id).adminNote != 'Attempt by Charity coordinator', true);

      // Switch to DEPT_MEMBER_CARE (አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ)
      state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptMemberCare);
      expect(state.canManageEmergencyAid, true);

      state.verifyEmergencyAid(
        targetAid.id,
        EmergencyAidStatus.approved,
        adminNote: 'Emergency medical aid approved and transferred via Telebirr.',
      );
      final updatedAid = state.emergencyAidRequests.firstWhere((a) => a.id == targetAid.id);
      expect(updatedAid.status, EmergencyAidStatus.approved);
      expect(updatedAid.adminNote, 'Emergency medical aid approved and transferred via Telebirr.');
    }
  });

  testWidgets('Coordinator Hub: Batch Programs Pilgrimage & Charity interactive features test', (tester) async {
    final state = FellowshipState();
    // Set to Batch & Programs coordinator
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptBatchPrograms);

    // 1. Interactive Pilgrimage CRUD
    final initialTripsCount = state.pilgrimageTrips.length;
    final testTrip = PilgrimageTripModel(
      id: 'trip-interactive-test',
      title: 'Debre Libanos Pilgrimage Retreat',
      destination: 'Debre Libanos Monastery',
      departureDate: DateTime.now().add(const Duration(days: 10)),
      returnDate: DateTime.now().add(const Duration(days: 11)),
      departurePoint: 'WCU Campus Gate',
      feeAmount: 450.0,
      isFree: false,
      telebirrNumber: '+251911223344',
      telebirrAccountName: 'WCU Orthodox Fellowship',
      cbeAccountNumber: '1000234567890',
      cbeAccountName: 'WCU Orthodox Tewahedo Fellowship',
      totalSeats: 60,
      bookedSeats: 0,
      itinerary: ['Morning departure', 'Liturgy and prayers', 'Return in evening'],
      packingList: ['Netela', 'Bible'],
      coordinatorName: 'Batch Coordinator',
      coordinatorPhone: '+251911000000',
    );
    state.addPilgrimageTrip(testTrip);
    expect(state.pilgrimageTrips.length, initialTripsCount + 1);

    // Edit trip
    final editedTrip = testTrip.copyWith(title: 'Debre Libanos Pilgrimage & Holy Water Blessing', feeAmount: 500.0);
    state.updatePilgrimageTrip(editedTrip);
    expect(state.pilgrimageTrips.firstWhere((t) => t.id == testTrip.id).title, 'Debre Libanos Pilgrimage & Holy Water Blessing');

    // Register pilgrim student
    final pilgrim = TripRegistrationModel(
      id: 'reg-test-1',
      tripId: testTrip.id,
      tripTitle: editedTrip.title,
      studentId: 'usr-pilgrim-1',
      studentName: 'Betelehem Tadesse',
      studentBaptismalName: 'Walata Kidan',
      studentPhone: '+251911887766',
      department: 'Biomedical Engineering',
      academicYear: 3,
      busNumber: 1,
      seatNumber: 18,
      feeAmount: 500.0,
      isFree: false,
      paymentMethod: PaymentMethodType.telebirr,
      transactionReference: 'TB-TEST-998877',
      paymentStatus: TripPaymentStatus.pendingVerification,
      qrTicketCode: 'PILGRIM-TEST-9988',
      registeredAt: DateTime.now(),
    );
    state.addPilgrimRegistration(pilgrim);
    expect(state.allTripRegistrations.any((r) => r.id == 'reg-test-1'), true);

    // Verify payment
    state.verifyTripPayment('reg-test-1', true);
    expect(state.allTripRegistrations.firstWhere((r) => r.id == 'reg-test-1').paymentStatus, TripPaymentStatus.verified);

    // Edit pilgrim seat
    final updatedPilgrim = pilgrim.copyWith(busNumber: 2, seatNumber: 5, paymentStatus: TripPaymentStatus.verified);
    state.updatePilgrimRegistration(updatedPilgrim);
    expect(state.allTripRegistrations.firstWhere((r) => r.id == 'reg-test-1').seatNumber, 5);

    // 2. Switch to Charity Coordinator
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptCharity);

    // Add & Edit Charity Campaign
    final initialCampsCount = state.charityCampaigns.length;
    final testCamp = CharityCampaignModel(
      id: 'camp-test-1',
      title: 'Needy Students Cafeteria Meal Voucher Fund',
      description: 'Monthly meal voucher support for underprivileged campus students.',
      targetAmount: 30000.0,
      raisedAmount: 5000.0,
      donorsCount: 15,
      deadline: DateTime.now().add(const Duration(days: 30)),
      category: 'Student Mutual Aid',
    );
    state.addCharityCampaign(testCamp);
    expect(state.charityCampaigns.length, initialCampsCount + 1);

    // Add and delete charity disbursement
    final disb = CharityDisbursementModel(
      id: 'disb-test-1',
      beneficiaryName: 'Mekdes Zewdu (Year 2 Medicine)',
      assistanceType: 'Prescription Medicine Voucher',
      amount: 600.0,
      voucherReference: 'VOUCH-MED-099',
      approvedBy: 'Charity Coordinator',
      disbursedAt: DateTime.now(),
      notes: 'Disbursed via Telebirr for emergency clinic pharmacy prescription.',
    );
    state.addCharityDisbursement(disb);
    expect(state.charityDisbursements.any((d) => d.id == 'disb-test-1'), true);

    state.deleteCharityDisbursement('disb-test-1');
    expect(state.charityDisbursements.any((d) => d.id == 'disb-test-1'), false);

    // Render CoordinatorHubScreen to ensure zero layout exceptions / overflows
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoordinatorHubScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Coordinator Hub'), findsOneWidget);
    state.dispose();
  });

  testWidgets('Spiritual Parent: Children Progress Tracking in Family and Roadmap screens test', (WidgetTester tester) async {
    final state = FellowshipState();
    state.switchRole(UserRole.spiritualParent);

    final children = state.spiritualChildren;
    expect(children.isNotEmpty, true);

    // 1. Render StudentRoadmapScreen as Spiritual Parent
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StudentRoadmapScreen(
            state: state,
            onOpenScanner: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify presence of spiritual children selector and overview
    expect(find.textContaining('ASSIGNED SPIRITUAL CHILDREN'), findsOneWidget);
    expect(find.textContaining('Spiritual Parent Curriculum Oversight'), findsOneWidget);
    expect(find.textContaining('CURRICULUM ROADMAP PROGRESS'), findsOneWidget);
    expect(find.textContaining('ደውል (Call)'), findsOneWidget);

    // 2. Render StudentFamilyScreen as Spiritual Parent
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StudentFamilyScreen(state: state),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('My Spiritual Children • የመንፈስ ልጆቼ'), findsOneWidget);
    expect(find.textContaining('Assigned'), findsOneWidget);
    expect(find.text('Roadmap'), findsWidgets);

    state.dispose();
  });

  testWidgets('Education & Apostolic Coordinator Hub: Batch targeting, announcements & special programs test', (WidgetTester tester) async {
    final state = FellowshipState();
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptEducation);

    // 1. Verify batch-specific broadcast dispatch
    final initialCount = state.getBroadcastsForDepartment(FellowshipDepartmentConstants.deptEducation).length;
    state.sendDepartmentBroadcast(
      departmentId: FellowshipDepartmentConstants.deptEducation,
      title: 'Year 2 Patristics Midterm Exam Announcement',
      body: 'Exam will be held next Tuesday in Hall 402. Bring IDs.',
      targetBatch: '2',
      targetAudienceLabel: 'Year 2 Batch (2ኛ ዓመት ባች)',
      broadcastCategory: 'courseInfo',
      courseCode: 'PATR-201',
      instructorOrSpeaker: 'Memhir Yohannes',
    );

    final eduBroadcasts = state.getBroadcastsForDepartment(FellowshipDepartmentConstants.deptEducation);
    expect(eduBroadcasts.length, initialCount + 1);

    final created = eduBroadcasts.firstWhere((b) => b.title.contains('Year 2 Patristics'));
    expect(created.targetBatch, '2');
    expect(created.broadcastCategory, 'courseInfo');
    expect(created.courseCode, 'PATR-201');

    // 2. Verify getBroadcastsForBatch query
    final year2Broadcasts = state.getBroadcastsForBatch('2');
    expect(year2Broadcasts.any((b) => b.id == created.id), true);

    final year4Broadcasts = state.getBroadcastsForBatch('4');
    // Year 4 should not see Year 2 specific broadcast, but will see 'all' batch broadcasts
    expect(year4Broadcasts.any((b) => b.id == created.id), false);

    // 3. Verify special guest teacher notice scheduling
    state.publishSpecialGuestTeacherNotice(
      teacherName: 'Dr. Rodas Tadesse',
      teacherTitle: 'Megabe Hadis',
      topic: 'Sacred Creation & Patristic Theology',
      venue: 'WCU Main Auditorium Hall A',
      dateAndTime: DateTime.now().add(const Duration(days: 4)),
      targetBatch: 'all',
      description: 'Open to all university students.',
    );

    final updatedEduBroadcasts = state.getBroadcastsForDepartment(FellowshipDepartmentConstants.deptEducation);
    expect(updatedEduBroadcasts.any((b) => b.title.contains('Dr. Rodas Tadesse') || b.title.contains('ሮዳስ')), true);

    // 4. Verify broadcast deletion
    state.deleteDepartmentBroadcast(created.id);
    expect(state.getBroadcastsForDepartment(FellowshipDepartmentConstants.deptEducation).any((b) => b.id == created.id), false);

    // 5. Render CoordinatorHubScreen with Education Department selected
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoordinatorHubScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Apostolic Education'), findsOneWidget);
    expect(find.textContaining('አዲስ ማስታወቂያ (Broadcast)'), findsOneWidget);
    expect(find.textContaining('ልዩ መርሐ ግብር (Program)'), findsOneWidget);
    expect(find.textContaining('DEPARTMENT BROADCASTS FEED'), findsOneWidget);

    state.dispose();
  });

  testWidgets('Coordinator Hub: Development & Fundraising Module UI and Actions Test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    final state = FellowshipState();
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptDevelopment);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoordinatorHubScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and action buttons
    expect(find.textContaining('ልማትና ገቢ አሰባሰብ (Development & Fundraising)'), findsOneWidget);
    expect(find.textContaining('አዲስ ፕሮፖዛል አዘጋጅ (Draft)'), findsOneWidget);
    expect(find.textContaining('Templates'), findsOneWidget);

    // Verify metrics cards
    expect(find.textContaining('Total Target Capital'), findsOneWidget);
    expect(find.textContaining('Approved Target'), findsOneWidget);

    // Verify search and status filter chips
    expect(find.textContaining('Search proposals'), findsOneWidget);
    expect(find.textContaining('All ('), findsOneWidget);
    expect(find.textContaining('Pending Review ('), findsOneWidget);
    expect(find.textContaining('Approved ('), findsOneWidget);
    expect(find.textContaining('Revision Needed ('), findsOneWidget);

    // Verify seeded proposals are displayed
    expect(find.textContaining('የ2017 ዓመታዊ ታላቁ የበዓላት ባዛር'), findsOneWidget);
    expect(find.textContaining('Alumni Fellowship'), findsOneWidget);

    // Tap Templates button to open templates bottom sheet
    await tester.tap(find.textContaining('Templates'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Fundraising Proposal Templates'), findsOneWidget);
    expect(find.textContaining('የተማሪዎች አስቸኳይ የጤናና የምግብ መረዳጃ ፈንድ'), findsOneWidget);

    // Tap Use Template button to open draft dialog pre-populated
    await tester.tap(find.text('Use Template').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Submit to Admin Board'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.binding.setSurfaceSize(null);
    state.dispose();
  });

  testWidgets('Coordinator Hub: Mobile Screen Responsiveness & Zero Right Overflow in Education and Development', (tester) async {
    // Set small mobile screen size (360 x 740)
    await tester.binding.setSurfaceSize(const Size(360, 740));
    final state = FellowshipState();

    // 1. Verify Education module on narrow screen
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptEducation);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoordinatorHubScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Apostolic Education • ትምህርትና ሐዋርያዊ'), findsOneWidget);
    expect(find.textContaining('Broadcasts'), findsOneWidget);
    expect(tester.takeException(), isNull); // Zero overflow exception!

    // 2. Verify Development module on narrow screen
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptDevelopment);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoordinatorHubScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Development & Proposals • ልማትና ገቢ'), findsOneWidget);
    expect(find.textContaining('Submitted Fundraising Proposals'), findsNothing);
    expect(tester.takeException(), isNull); // Zero overflow exception!

    await tester.binding.setSurfaceSize(null);
    state.dispose();
  });

  testWidgets('Admin Approvals: Proposals Tab, Interactive Approval, Revision Request, and Coordinator Reflection Test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    final state = FellowshipState();
    state.switchRole(UserRole.admin);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: AdminApprovalsScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Proposals Tab is present in Admin Approvals
    expect(find.textContaining('Proposals ('), findsOneWidget);

    // 2. Tap Proposals Tab
    await tester.tap(find.textContaining('Proposals ('));
    await tester.pumpAndSettle();

    // Verify Proposals Overview & Cards
    expect(find.textContaining('Fundraising Proposals • ልማትና ገቢ'), findsOneWidget);
    expect(find.textContaining('PROPOSALS REVIEW QUEUE'), findsOneWidget);
    expect(find.textContaining('የ2017 ዓመታዊ ታላቁ የበዓላት ባዛር'), findsOneWidget);

    // 3. Find pending proposal and approve it interactively
    final pendingProposals = state.fundraisingProposals.where((p) => p.isPending).toList();
    expect(pendingProposals.isNotEmpty, true);
    final targetPending = pendingProposals.first;

    // Tap Approve button on card
    final approveBtnFinder = find.widgetWithText(ElevatedButton, 'አጽድቅ (Approve)');
    expect(approveBtnFinder, findsWidgets);
    await tester.tap(approveBtnFinder.first);
    await tester.pumpAndSettle();

    // Verify Approval Confirmation Dialog
    expect(find.textContaining('Approve Proposal • ፕሮፖዛል አጽድቅ'), findsOneWidget);
    expect(find.textContaining('Board Approval Note & Allocation Remarks'), findsOneWidget);

    // Confirm approval
    await tester.tap(find.text('Confirm Approval • አጽድቅ'));
    await tester.pumpAndSettle();

    // Verify state updated
    final updatedApproved = state.fundraisingProposals.firstWhere((p) => p.id == targetPending.id);
    expect(updatedApproved.isApproved, true);
    expect(updatedApproved.adminReviewNotes, isNotNull);

    // 4. Test Revision Request on another pending proposal (or submit a new one and reject it)
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptDevelopment);
    state.submitFundraisingProposal(
      title: 'Youth Choir Audio Equipment Campaign',
      objective: 'Purchase wireless microphones for holiday liturgies.',
      targetAmount: 35000,
      expectedExpenses: 2000,
      proposedStrategy: 'Holiday tea and bread sale.',
      targetAudience: 'Campus Fellowship',
    );

    // Switch back to Admin to review
    state.switchRole(UserRole.admin);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: AdminApprovalsScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to Proposals Tab
    await tester.tap(find.textContaining('Proposals ('));
    await tester.pumpAndSettle();

    expect(find.textContaining('Youth Choir Audio Equipment Campaign'), findsOneWidget);

    // Tap Revision button
    final revisionBtnFinder = find.widgetWithText(OutlinedButton, 'ማሻሻያ እዘዝ (Revision)');
    expect(revisionBtnFinder, findsWidgets);
    await tester.tap(revisionBtnFinder.first);
    await tester.pumpAndSettle();

    // Verify Revision Dialog
    expect(find.textContaining('Request Revision • ማሻሻያ እዘዝ'), findsOneWidget);

    // Tap Send Feedback
    await tester.tap(find.text('Send Feedback • ማሻሻያውን ላክ'));
    await tester.pumpAndSettle();

    final revisedProp = state.fundraisingProposals.firstWhere((p) => p.title.contains('Youth Choir Audio Equipment'));
    expect(revisedProp.isRejected, true);

    // 5. Verify Coordinator sees the updated status and admin note in Coordinator Hub
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptDevelopment);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: CoordinatorHubScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('REVISION NEEDED • የተመለሰ'), findsWidgets);
    expect(find.textContaining('Admin Revision Feedback'), findsWidgets);

    await tester.binding.setSurfaceSize(null);
    state.dispose();
  });

  testWidgets('Integration: Home Screen 10 Departments Quick Action and Library Category Chips Test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(450, 900));
    final state = FellowshipState();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StudentHomeScreen(
            state: state,
            onNavigateTab: (_) {},
            onOpenScanner: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify 10 Ministries & Volunteer Serving quick action card is present on home screen
    expect(find.textContaining('10 Ministries'), findsOneWidget);
    expect(find.textContaining('Volunteer Serving'), findsOneWidget);

    // 2. Verify Digital Library category filter chips
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StudentLibraryScreen(state: state),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Material'), findsOneWidget);
    expect(find.text('Patristics (አበው)'), findsOneWidget);
    expect(find.text('Liturgical (ቅዳሴ)'), findsOneWidget);
    expect(find.text('Mezmur Audio (መዝሙር)'), findsOneWidget);
    expect(find.text('Dogma (ዶግማ)'), findsOneWidget);

    // Scroll to see extended category chips
    await tester.drag(find.text('Patristics (አበው)'), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Lives of Saints (ገድላት)'), findsOneWidget);
    expect(find.text('Scripture (መጽሐፍ ቅዱስ)'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
    state.dispose();
  });

  testWidgets('Scanner RBAC: Student Attendance mode vs Coordinator Pilgrim Pass Camera mode test', (tester) async {
    await tester.binding.setSurfaceSize(const Size(450, 900));
    final state = FellowshipState();

    // 1. As Normal Student: Only Attendance mode visible, Pilgrim Pass mode hidden
    state.switchRole(UserRole.student);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: StudentQrScannerScreen(state: state),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Live Attendance Scanner'), findsOneWidget);
    expect(find.text('SESSION ACTIVE'), findsOneWidget);
    expect(find.text('OR ENTER ROLLING 4-DIGIT PIN'), findsOneWidget);
    // Pilgrim Pass mode tab should NOT be visible to regular students
    expect(find.text('Pilgrim Pass'), findsNothing);

    // 2. As Batch & Programs Coordinator: Mode selector is visible & Pilgrim Pass mode available
    state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptBatchPrograms);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: StudentQrScannerScreen(state: state, initialMode: 1),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Pilgrim Pass Boarding Scanner'), findsOneWidget);
    expect(find.text('Pilgrim Pass'), findsOneWidget);
    expect(find.text('Course Attendance'), findsOneWidget);
    expect(find.text('OR ENTER TICKET / REF CODE'), findsOneWidget);

    await tester.binding.setSurfaceSize(null);
    state.dispose();
  });
}



