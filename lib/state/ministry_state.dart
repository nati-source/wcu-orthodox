part of 'fellowship_state.dart';

/// Feature slice managing 10 EOTC Departments, Coordinator Delegation, Applications & Proposals.
class MinistryState extends ChangeNotifier {
  final FellowshipState root; MinistryState(this.root);
  void refresh() => notifyListeners();
}

mixin MinistryStateMixin on ChangeNotifier {
  UserModel get _currentUser;
  set _currentUser(UserModel value);
  UserRole get _activeRole;
  List<UserModel> get _allStudents;
  bool get isAdmin;
  bool get canPublishSpecialTeacherNotice;
  bool get canSubmitFundraisingProposal;
  bool canAccessDepartmentWrite(String? targetDeptId);
  Future<void> broadcastEmergency({required String title, required String description, String churchName, String category});

  // ----------------------------------------------------
  // DOMAIN 7: 10 EOTC FELLOWSHIP DEPARTMENTS & COORDINATOR DELEGATION
  // ----------------------------------------------------
  List<MinistryModel> _ministries = MinistryModel.defaultMinistries;
  List<VolunteerApplicationModel> _volunteerApplications = [];
  List<DepartmentMemberModel> _departmentMembers = [];
  List<DepartmentBroadcastMessageModel> _departmentBroadcasts = [];
  List<FundraisingProposalModel> _fundraisingProposals = [];
  String? _selectedCoordinatorDepartmentId;

  List<MinistryModel> get ministries => List.unmodifiable(_ministries);
  List<VolunteerApplicationModel> get volunteerApplications => List.unmodifiable(_volunteerApplications);
  List<DepartmentMemberModel> get departmentMembers => List.unmodifiable(_departmentMembers);
  List<DepartmentBroadcastMessageModel> get departmentBroadcasts => List.unmodifiable(_departmentBroadcasts);
  List<FundraisingProposalModel> get fundraisingProposals => List.unmodifiable(_fundraisingProposals);
  String? get selectedCoordinatorDepartmentId => _selectedCoordinatorDepartmentId;

  void setSelectedCoordinatorDepartment(String? deptId) {
    _selectedCoordinatorDepartmentId = deptId;
    notifyListeners();
  }

  List<DepartmentBroadcastMessageModel> getBroadcastsForDepartment(String? deptId) {
    if (deptId == null || deptId.isEmpty) {
      return List.unmodifiable(_departmentBroadcasts);
    }
    return _departmentBroadcasts.where((b) => b.departmentId == deptId).toList();
  }

  /// Dynamically rotates or selects a volunteer coordinator phone number from registered
  /// coordinators in the database for that department to lower the burden on a single person.
  String getCoordinatorPhoneForMinistry(String ministryId, {String? defaultPhone}) {
    final matchingCoordinators = _allStudents.where((u) {
      if (!u.isApproved) return false;
      if (u.role != UserRole.volunteerCoordinator) return false;
      if (u.phoneNumber.trim().isEmpty) return false;
      final deptId = u.coordinatorProfile?.departmentId;
      return deptId != null && deptId.trim().toLowerCase() == ministryId.trim().toLowerCase();
    }).toList();

    if (matchingCoordinators.isNotEmpty) {
      final idx = Random().nextInt(matchingCoordinators.length);
      return matchingCoordinators[idx].phoneNumber.trim();
    }

    final anyCoordinators = _allStudents.where((u) {
      return u.isApproved && u.role == UserRole.volunteerCoordinator && u.phoneNumber.trim().isNotEmpty;
    }).toList();

    if (anyCoordinators.isNotEmpty) {
      final idx = Random().nextInt(anyCoordinators.length);
      return anyCoordinators[idx].phoneNumber.trim();
    }

    return defaultPhone ?? '+251911223344';
  }

  String getCoordinatorNameForMinistry(String ministryId, {String? defaultName}) {
    final matchingCoordinators = _allStudents.where((u) {
      if (!u.isApproved) return false;
      if (u.role != UserRole.volunteerCoordinator) return false;
      final deptId = u.coordinatorProfile?.departmentId;
      return deptId != null && deptId.trim().toLowerCase() == ministryId.trim().toLowerCase();
    }).toList();

    if (matchingCoordinators.isNotEmpty) {
      return matchingCoordinators.first.fullName;
    }
    return defaultName ?? 'Department Coordinator';
  }

  /// Returns broadcasts matching a specific batch year or targeted to all students
  List<DepartmentBroadcastMessageModel> getBroadcastsForBatch(String? batchYear) {
    if (batchYear == null || batchYear.isEmpty || batchYear == 'all') {
      return List.unmodifiable(_departmentBroadcasts);
    }
    final normalizedYear = batchYear.replaceAll(RegExp(r'[^0-9]'), '');
    return _departmentBroadcasts.where((b) {
      if (b.targetBatch == 'all' || b.targetBatch.isEmpty) return true;
      if (normalizedYear.isNotEmpty && b.targetBatch == normalizedYear) return true;
      return b.targetBatch == batchYear;
    }).toList();
  }

  Future<void> sendDepartmentBroadcast({
    required String departmentId,
    required String title,
    required String body,
    String urgency = 'normal',
    String targetBatch = 'all',
    String? targetAudienceLabel,
    String broadcastCategory = 'generalNotice',
    String? courseCode,
    String? instructorOrSpeaker,
    String? meetingLocation,
    DateTime? meetingTime,
  }) async {
    if (!canAccessDepartmentWrite(departmentId) && !isAdmin) return;

    final senderName = _currentUser.fullName;
    final senderRole = _currentUser.coordinatorProfile?.coordinatorTitle ?? (_currentUser.role == UserRole.admin ? 'Global Admin' : 'Coordinator');

    final audience = targetAudienceLabel ?? (targetBatch == 'all' ? 'All Students (ሁሉንም ተማሪዎች)' : 'Year $targetBatch Batch ($targetBatchኛ ዓመት ባች)');

    final broadcast = DepartmentBroadcastMessageModel(
      id: 'dmsg-${DateTime.now().microsecondsSinceEpoch}',
      departmentId: departmentId,
      title: title,
      body: body,
      senderName: senderName,
      senderRole: senderRole,
      sentAt: DateTime.now(),
      urgency: urgency,
      targetBatch: targetBatch,
      targetAudienceLabel: audience,
      broadcastCategory: broadcastCategory,
      courseCode: courseCode,
      instructorOrSpeaker: instructorOrSpeaker,
      meetingLocation: meetingLocation,
      meetingTime: meetingTime,
    );

    _departmentBroadcasts.insert(0, broadcast);

    // Also trigger an emergency/banner notification so students in that department see it
    final deptName = FellowshipDepartmentConstants.getNameAmharic(departmentId);
    if (targetBatch == 'all' && (urgency == 'urgent' || urgency == 'meeting')) {
      broadcastEmergency(
      title: '[$deptName] $title',
      description: body,
      category: urgency == 'meeting' ? 'Meeting Notice' : (urgency == 'urgent' ? 'Urgent Alert' : 'Department Announcement'),
      );
    }

    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('department_broadcasts').doc(broadcast.id).set(
        broadcast.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore sendDepartmentBroadcast success: ${broadcast.id}');
    } catch (e) {
      debugPrint('Firestore sendDepartmentBroadcast error: $e');
    }
  }

  Future<void> deleteDepartmentBroadcast(String id) async {
    final idx = _departmentBroadcasts.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _departmentBroadcasts.removeWhere((item) => item.id == id);
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('department_broadcasts').doc(id).delete();
        debugPrint('Firestore deleteDepartmentBroadcast success: $id');
      } catch (e) {
        debugPrint('Firestore deleteDepartmentBroadcast error: $e');
      }
    }
  }

  void publishSpecialGuestTeacherNotice({
    required String teacherName,
    required String teacherTitle,
    required String topic,
    required String venue,
    required DateTime dateAndTime,
    String targetBatch = 'all',
    String? targetAudienceLabel,
    String? description,
  }) {
    final formattedDate = "${dateAndTime.day}/${dateAndTime.month}/${dateAndTime.year} at ${dateAndTime.hour}:${dateAndTime.minute.toString().padLeft(2, '0')}";
    final bodyText = 'መምህር/መምህርት: $teacherTitle $teacherName\nርዕስ: $topic\nቦታ: $venue\nጊዜ: $formattedDate\n${description ?? ''}';

    final audience = targetAudienceLabel ?? (targetBatch == 'all' ? 'All Students (ሁሉንም ተማሪዎች)' : 'Year $targetBatch Batch ($targetBatchኛ ዓመት ባች)');

    sendDepartmentBroadcast(
      departmentId: FellowshipDepartmentConstants.deptEducation,
      title: '🌟 ልዩ የትምህርትና ስብከት መርሐ ግብር - $teacherTitle $teacherName',
      body: bodyText,
      urgency: 'meeting',
      targetBatch: targetBatch,
      targetAudienceLabel: audience,
      broadcastCategory: 'specialProgram',
      instructorOrSpeaker: '$teacherTitle $teacherName',
      meetingLocation: venue,
      meetingTime: dateAndTime,
    );
  }

  Future<void> submitFundraisingProposal({
    required String title,
    required String objective,
    required double targetAmount,
    double expectedExpenses = 0.0,
    required String proposedStrategy,
    required String targetAudience,
    String category = 'Bazaar & Exhibition',
    String timelineOrDuration = '1 Month',
  }) async {
    final proposal = FundraisingProposalModel(
      id: 'prop-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      objective: objective,
      targetAmount: targetAmount,
      expectedExpenses: expectedExpenses,
      proposedStrategy: proposedStrategy,
      targetAudience: targetAudience,
      category: category,
      timelineOrDuration: timelineOrDuration,
      submittedByName: _currentUser.fullName,
      submittedByDept: FellowshipDepartmentConstants.deptDevelopment,
      submittedAt: DateTime.now(),
      status: ProposalStatus.pending,
    );
    _fundraisingProposals.insert(0, proposal);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('fundraising_proposals').doc(proposal.id).set(
        proposal.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore submitFundraisingProposal success: ${proposal.id}');
    } catch (e) {
      debugPrint('Firestore submitFundraisingProposal error: $e');
    }
  }

  Future<void> updateFundraisingProposal(FundraisingProposalModel updatedProposal) async {
    final idx = _fundraisingProposals.indexWhere((p) => p.id == updatedProposal.id);
    if (idx != -1) {
      _fundraisingProposals[idx] = updatedProposal;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('fundraising_proposals').doc(updatedProposal.id).set(
          updatedProposal.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore updateFundraisingProposal success: ${updatedProposal.id}');
      } catch (e) {
        debugPrint('Firestore updateFundraisingProposal error: $e');
      }
    }
  }

  Future<void> deleteFundraisingProposal(String proposalId) async {
    final idx = _fundraisingProposals.indexWhere((p) => p.id == proposalId);
    if (idx != -1) {
      _fundraisingProposals.removeAt(idx);
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('fundraising_proposals').doc(proposalId).delete();
        debugPrint('Firestore deleteFundraisingProposal success: $proposalId');
      } catch (e) {
        debugPrint('Firestore deleteFundraisingProposal error: $e');
      }
    }
  }

  Future<void> reviewFundraisingProposal({
    required String proposalId,
    required ProposalStatus status,
    String? adminNotes,
  }) async {
    if (!isAdmin) return;
    final idx = _fundraisingProposals.indexWhere((p) => p.id == proposalId);
    if (idx != -1) {
      _fundraisingProposals[idx] = _fundraisingProposals[idx].copyWith(
        status: status,
        adminReviewNotes: adminNotes,
        reviewedAt: DateTime.now(),
      );
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('fundraising_proposals').doc(proposalId).set(
          _fundraisingProposals[idx].toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore reviewFundraisingProposal success: $proposalId');
      } catch (e) {
        debugPrint('Firestore reviewFundraisingProposal notice: $e');
      }
    }
  }

  List<VolunteerApplicationModel> getApplicationsForDepartment(String? deptId) {
    if (isAdmin || _currentUser.coordinatorProfile?.isReadOnlyAudit == true) {
      if (deptId == null || deptId.isEmpty) {
        return List.unmodifiable(_volunteerApplications);
      }
      return _volunteerApplications.where((a) => a.ministryId == deptId).toList();
    }
    if (_activeRole == UserRole.volunteerCoordinator) {
      final myDept = _currentUser.coordinatorProfile?.departmentId;
      if (deptId != null && deptId.isNotEmpty && deptId != myDept) {
        return []; // Scoped isolation: Denied access to other departments
      }
      return _volunteerApplications.where((a) => a.ministryId == myDept).toList();
    }
    // Normal students only see their own applications
    return _volunteerApplications.where((a) => a.studentId == _currentUser.id).toList();
  }

  List<DepartmentMemberModel> getMembersForDepartment(String? deptId) {
    if (isAdmin || _currentUser.coordinatorProfile?.isReadOnlyAudit == true) {
      if (deptId == null || deptId.isEmpty) {
        return List.unmodifiable(_departmentMembers);
      }
      return _departmentMembers.where((m) => m.departmentId == deptId).toList();
    }
    if (_activeRole == UserRole.volunteerCoordinator) {
      final myDept = _currentUser.coordinatorProfile?.departmentId;
      if (deptId != null && deptId.isNotEmpty && deptId != myDept) {
        return []; // Scoped isolation
      }
      return _departmentMembers.where((m) => m.departmentId == myDept).toList();
    }
    if (deptId == null || deptId.isEmpty) {
      return List.unmodifiable(_departmentMembers);
    }
    return _departmentMembers.where((m) => m.departmentId == deptId).toList();
  }

  Future<void> submitMinistryApplication({
    required String ministryId,
    required String reason,
    required String experience,
    required String availability,
    String studentYear = '2nd Year',
    String preferredSubWing = 'General',
    ChoirWingType? choirWing,
    List<String> languagesKnown = const [],
  }) async {
    final min = _ministries.firstWhere(
      (m) => m.id == ministryId,
      orElse: () => _ministries.first,
    );
    final application = VolunteerApplicationModel(
      id: 'app-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentDept: _currentUser.department,
      studentPhone: _currentUser.phoneNumber,
      studentYear: studentYear,
      ministryId: min.id,
      ministryTitle: min.titleEn,
      ministryAmharicTitle: min.titleAmharic,
      preferredSubWing: preferredSubWing,
      choirWing: choirWing,
      languagesKnown: languagesKnown,
      reason: reason,
      experience: experience,
      availability: availability,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
    );

    _volunteerApplications.insert(0, application);
    _currentUser = _currentUser.copyWith(
      ministryStatus: 'Pending Review (${min.titleAmharic})',
    );
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('department_applications').doc(application.id).set(
        application.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore submitMinistryApplication success: ${application.id}');
    } catch (e) {
      debugPrint('Firestore submitMinistryApplication notice: $e');
    }
  }

  Future<void> approveVolunteerApplication(
    String applicationId, {
    String? notes,
    String? reviewedBy,
  }) async {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final oldApp = _volunteerApplications[index];
    if (!canAccessDepartmentWrite(oldApp.ministryId) && !isAdmin) return;

    final app = oldApp.copyWith(
      status: ApplicationStatus.approved,
      reviewedAt: DateTime.now(),
      reviewedByCoordinator: reviewedBy ?? (_currentUser.coordinatorProfile?.coordinatorTitle ?? 'Department Coordinator'),
      coordinatorNotes: notes ?? 'Welcome to the department! Orientation details shared.',
    );
    _volunteerApplications[index] = app;

    // Add to department members roster
    final existingMemberIndex = _departmentMembers.indexWhere(
      (m) => m.studentId == app.studentId && m.departmentId == app.ministryId,
    );
    DepartmentMemberModel? newMem;
    if (existingMemberIndex == -1) {
      newMem = DepartmentMemberModel(
        id: 'mem-${DateTime.now().millisecondsSinceEpoch}',
        departmentId: app.ministryId,
        studentId: app.studentId,
        studentName: app.studentName,
        studentBaptismalName: app.studentBaptismalName,
        studentDept: app.studentDept,
        studentYear: app.studentYear,
        phoneNumber: app.studentPhone,
        subWing: app.preferredSubWing,
        choirWing: app.choirWing,
        roleInDepartment: 'Active Servant',
        joinedDate: DateTime.now(),
      );
      _departmentMembers.insert(
        0,
        newMem,
      );
    }

    // Increment active count on department
    final mIndex = _ministries.indexWhere((m) => m.id == app.ministryId);
    if (mIndex != -1) {
      final currentM = _ministries[mIndex];
      _ministries[mIndex] = MinistryModel(
        id: currentM.id,
        titleEn: currentM.titleEn,
        titleAmharic: currentM.titleAmharic,
        iconName: currentM.iconName,
        descriptionEn: currentM.descriptionEn,
        descriptionAmharic: currentM.descriptionAmharic,
        pillar: currentM.pillar,
        teamLead: currentM.teamLead,
        coordinatorBaptismalName: currentM.coordinatorBaptismalName,
        coordinatorPhone: currentM.coordinatorPhone,
        coordinatorRole: currentM.coordinatorRole,
        openSlots: currentM.openSlots > 0 ? currentM.openSlots - 1 : 0,
        activeCount: currentM.activeCount + 1,
        tags: currentM.tags,
        subWings: currentM.subWings,
        meetingSchedule: currentM.meetingSchedule,
        requirements: currentM.requirements,
      );
    }

    // Update student status
    final sIndex = _allStudents.indexWhere((s) => s.id == app.studentId);
    if (sIndex != -1) {
      _allStudents[sIndex] = _allStudents[sIndex].copyWith(
        ministryStatus: '${app.ministryTitle} Member',
      );
    }
    if (_currentUser.id == app.studentId) {
      _currentUser = _currentUser.copyWith(
        ministryStatus: '${app.ministryTitle} Member',
      );
    }
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('department_applications').doc(applicationId).set(
        app.toMap(),
        SetOptions(merge: true),
      );
      if (newMem != null) {
        await FirebaseFirestore.instance.collection('department_members').doc(newMem.id).set(
          newMem.toMap(),
          SetOptions(merge: true),
        );
      }
      debugPrint('Firestore approveVolunteerApplication success: $applicationId');
    } catch (e) {
      debugPrint('Firestore approveVolunteerApplication error: $e');
    }
  }

  Future<void> rejectVolunteerApplication(
    String applicationId, {
    String? notes,
    String? reviewedBy,
  }) async {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final oldApp = _volunteerApplications[index];
    if (!canAccessDepartmentWrite(oldApp.ministryId) && !isAdmin) return;

    final rejectedApp = oldApp.copyWith(
      status: ApplicationStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewedByCoordinator: reviewedBy ?? (_currentUser.coordinatorProfile?.coordinatorTitle ?? 'Department Coordinator'),
      coordinatorNotes: notes ?? 'Thank you for your interest. We encourage exploring alternative serving areas.',
    );
    _volunteerApplications[index] = rejectedApp;
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('department_applications').doc(applicationId).set(
        rejectedApp.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore rejectVolunteerApplication success: $applicationId');
    } catch (e) {
      debugPrint('Firestore rejectVolunteerApplication error: $e');
    }
  }

}


