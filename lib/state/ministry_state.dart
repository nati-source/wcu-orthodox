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
  void broadcastEmergency({required String title, required String description, String churchName, String category});

  // ----------------------------------------------------
  // DOMAIN 7: 10 EOTC FELLOWSHIP DEPARTMENTS & COORDINATOR DELEGATION
  // ----------------------------------------------------
  List<MinistryModel> _ministries = [];
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

  void sendDepartmentBroadcast({
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
  }) {
    if (!canAccessDepartmentWrite(departmentId) && !isAdmin) return;

    final senderName = _currentUser.fullName;
    final senderRole = _currentUser.coordinatorProfile?.coordinatorTitle ?? (_currentUser.role == UserRole.admin ? 'Global Admin' : 'Coordinator');

    final audience = targetAudienceLabel ?? (targetBatch == 'all' ? 'All Students (ሁሉንም ተማሪዎች)' : 'Year $targetBatch Batch ($targetBatchኛ ዓመት ባች)');

    final broadcast = DepartmentBroadcastMessageModel(
      id: 'dmsg-${DateTime.now().millisecondsSinceEpoch}',
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
    broadcastEmergency(
      title: '[$deptName] $title',
      description: body,
      category: urgency == 'meeting' ? 'Meeting Notice' : (urgency == 'urgent' ? 'Urgent Alert' : 'Department Announcement'),
    );

    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('department_broadcasts').doc(broadcast.id).set(
        broadcast.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore sendDepartmentBroadcast notice: $e');
    }
  }

  void deleteDepartmentBroadcast(String id) {
    final idx = _departmentBroadcasts.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final b = _departmentBroadcasts[idx];
      if (canAccessDepartmentWrite(b.departmentId) || isAdmin) {
        _departmentBroadcasts.removeAt(idx);
        notifyListeners();

        try {
          FirebaseFirestore.instance.collection('department_broadcasts').doc(id).delete();
        } catch (e) {
          debugPrint('Firestore deleteDepartmentBroadcast notice: $e');
        }
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
    if (!canPublishSpecialTeacherNotice) return;

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

  void submitFundraisingProposal({
    required String title,
    required String objective,
    required double targetAmount,
    double expectedExpenses = 0.0,
    required String proposedStrategy,
    required String targetAudience,
    String category = 'Bazaar & Exhibition',
    String timelineOrDuration = '1 Month',
  }) {
    if (!canSubmitFundraisingProposal) return;
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
      FirebaseFirestore.instance.collection('fundraising_proposals').doc(proposal.id).set(
        proposal.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submitFundraisingProposal notice: $e');
    }
  }

  void updateFundraisingProposal(FundraisingProposalModel updatedProposal) {
    if (!canSubmitFundraisingProposal && !isAdmin) return;
    final idx = _fundraisingProposals.indexWhere((p) => p.id == updatedProposal.id);
    if (idx != -1) {
      _fundraisingProposals[idx] = updatedProposal;
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('fundraising_proposals').doc(updatedProposal.id).set(
          updatedProposal.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore updateFundraisingProposal notice: $e');
      }
    }
  }

  void deleteFundraisingProposal(String proposalId) {
    if (!canSubmitFundraisingProposal && !isAdmin) return;
    final idx = _fundraisingProposals.indexWhere((p) => p.id == proposalId);
    if (idx != -1) {
      _fundraisingProposals.removeAt(idx);
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('fundraising_proposals').doc(proposalId).delete();
      } catch (e) {
        debugPrint('Firestore deleteFundraisingProposal notice: $e');
      }
    }
  }

  void reviewFundraisingProposal({
    required String proposalId,
    required ProposalStatus status,
    String? adminNotes,
  }) {
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
        FirebaseFirestore.instance.collection('fundraising_proposals').doc(proposalId).set(
          _fundraisingProposals[idx].toMap(),
          SetOptions(merge: true),
        );
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

  void submitMinistryApplication({
    required String ministryId,
    required String reason,
    required String experience,
    required String availability,
    String studentYear = '2nd Year',
    String preferredSubWing = 'General',
    ChoirWingType? choirWing,
    List<String> languagesKnown = const [],
  }) {
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
      FirebaseFirestore.instance.collection('department_applications').doc(application.id).set(
        application.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submitMinistryApplication notice: $e');
    }
  }

  void approveVolunteerApplication(
    String applicationId, {
    String? notes,
    String? reviewedBy,
  }) {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final oldApp = _volunteerApplications[index];
    // Scoped RBAC Guard: Verify write authorization for target department
    if (!canAccessDepartmentWrite(oldApp.ministryId)) return;

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
      FirebaseFirestore.instance.collection('department_applications').doc(applicationId).set(
        app.toMap(),
        SetOptions(merge: true),
      );
      if (newMem != null) {
        FirebaseFirestore.instance.collection('department_members').doc(newMem.id).set(
          newMem.toMap(),
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      debugPrint('Firestore approveVolunteerApplication notice: $e');
    }
  }

  void rejectVolunteerApplication(
    String applicationId, {
    String? notes,
    String? reviewedBy,
  }) {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index == -1) return;

    final oldApp = _volunteerApplications[index];
    // Scoped RBAC Guard: Verify write authorization for target department
    if (!canAccessDepartmentWrite(oldApp.ministryId)) return;

    final rejectedApp = oldApp.copyWith(
      status: ApplicationStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewedByCoordinator: reviewedBy ?? (_currentUser.coordinatorProfile?.coordinatorTitle ?? 'Department Coordinator'),
      coordinatorNotes: notes ?? 'Thank you for your interest. We encourage exploring alternative serving areas.',
    );
    _volunteerApplications[index] = rejectedApp;
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('department_applications').doc(applicationId).set(
        rejectedApp.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore rejectVolunteerApplication notice: $e');
    }
  }

}


