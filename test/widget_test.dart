import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/main.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/coordinator/coordinator_hub_screen.dart';

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
      proposedStrategy: '1 Month exhibition in campus hall',
      targetAudience: '50 needy freshmen students for stationery and cafeteria support',
    );

    expect(state.fundraisingProposals.any((p) => p.title == 'Campus Begena & Sacred Art Charity Exhibition'), true);
    final proposal = state.fundraisingProposals.firstWhere((p) => p.title == 'Campus Begena & Sacred Art Charity Exhibition');
    expect(proposal.status, ProposalStatus.pending);

    // 2. Non-admin coordinator cannot approve proposals
    state.reviewFundraisingProposal(
      proposalId: proposal.id,
      status: ProposalStatus.approved,
      adminNotes: 'Unauthorized approval attempt',
    );
    expect(state.fundraisingProposals.firstWhere((p) => p.id == proposal.id).status, ProposalStatus.pending);

    // 3. Admin approves proposal with executive review notes
    state.switchRole(UserRole.admin);
    state.reviewFundraisingProposal(
      proposalId: proposal.id,
      status: ProposalStatus.approved,
      adminNotes: 'Approved by Executive Committee. Budget allocation sanctioned.',
    );
    final approvedProp = state.fundraisingProposals.firstWhere((p) => p.id == proposal.id);
    expect(approvedProp.status, ProposalStatus.approved);
    expect(approvedProp.adminReviewNotes, 'Approved by Executive Committee. Budget allocation sanctioned.');
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
}

