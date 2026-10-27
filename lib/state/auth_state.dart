part of 'fellowship_state.dart';

/// Feature slice managing Authentication, Active User, Theme, RBAC & Student Approvals.
class AuthState extends ChangeNotifier {
  final FellowshipState root;
  AuthState(this.root);
  void refresh() => notifyListeners();
}

mixin AuthStateMixin on ChangeNotifier {
  bool get isDemoMode;
  FirestoreService get firestoreService;
  FirestoreService get _firestoreService => firestoreService;
  List<FamilyModel> get _families;
  set _selectedCoordinatorDepartmentId(String? value);
  FamilyModel? get currentStudentFamily;
  List<PilgrimageTripModel> get _pilgrimageTrips;
  List<TripRegistrationModel> get _tripRegistrations;
  List<LibraryItemModel> get _libraryItems;
  List<ChurchProgramModel> get _programs;
  List<DepartmentBroadcastMessageModel> get _departmentBroadcasts;
  List<FundraisingProposalModel> get _fundraisingProposals;
  List<VolunteerApplicationModel> get _volunteerApplications;
  List<DepartmentMemberModel> get _departmentMembers;
  List<ConfessorFatherModel> get _confessorFathers;
  List<ConfessionAppointmentModel> get _confessionAppointments;
  List<AnonymousSpiritualQuestionModel> get _spiritualQuestions;
  List<CharityCampaignModel> get _charityCampaigns;
  List<DuesPaymentModel> get _duesPayments;
  List<CharityDisbursementModel> get _charityDisbursements;
  List<EmergencyAidRequestModel> get _emergencyAidRequests;
  List<AcademicMentorModel> get _academicMentors;
  List<MentorshipRequestModel> get _mentorshipRequests;
  List<QuizAttemptModel> get _quizAttempts;
  List<TriviaQuizModel> get _triviaQuizzes;
  AttendanceSessionModel get _activeSession;

  // ----------------------------------------------------
  // ACTIVE USER, THEME & ROLE SWITCHING
  // ----------------------------------------------------
  static const String _themePrefKey = 'selected_theme_palette_index';

  UserRole _activeRole = UserRole.student;
  UserRole get activeRole => _activeRole;

  UserRole _assignedRole = UserRole.student;
  UserRole get assignedRole => _assignedRole;

  UserRole _authenticatedRole = UserRole.student;
  UserRole get authenticatedRole => _authenticatedRole;

  bool _isOriginalAdmin = false;
  bool get isOriginalAdmin => _isOriginalAdmin;

  void markAsOriginalAdmin() {
    _isOriginalAdmin = true;
    _authenticatedRole = UserRole.admin;
    _assignedRole = UserRole.admin;
    _activeRole = UserRole.admin;
    notifyListeners();
  }

  bool get isAuthorizedAdmin {
    String? authEmail;
    try {
      authEmail = FirebaseAuth.instance.currentUser?.email;
    } catch (_) {}
    return _isOriginalAdmin ||
        _currentUser.role == UserRole.admin ||
        _authenticatedRole == UserRole.admin ||
        _assignedRole == UserRole.admin ||
        AppAdminConstants.isAdminEmail(_currentUser.email) ||
        AppAdminConstants.isAdminEmail(authEmail);
  }

  void revokeAdminPrivileges() {
    _isOriginalAdmin = false;
    _authenticatedRole = UserRole.student;
    _assignedRole = UserRole.student;
    _activeRole = UserRole.student;
    notifyListeners();
    // Reset the admin-mode stream flag so _listenToRegisteredUsers recreates
    // the stream in personal-profile mode instead of staying in collection mode.
    if (this is FellowshipState) {
      (this as FellowshipState).resetUsersSubscription();
    }
  }

  /// Returns the roles this user is authorized to access and switch between.
  /// - Admin: All 4 access points (Admin, Volunteer Coordinator, Spiritual Parent, Student).
  /// - Volunteer Coordinator: 2 access points (Volunteer Coordinator, Student).
  /// - Spiritual Parent: 2 access points (Spiritual Parent, Student).
  /// - Student: Student only (unless developer mode is explicitly enabled by Admin).
  List<UserRole> get availableRoles {
    if (_currentUser.role == UserRole.admin ||
        _authenticatedRole == UserRole.admin ||
        _showDevRoleSwitcher) {
      return [
        UserRole.admin,
        UserRole.volunteerCoordinator,
        UserRole.spiritualParent,
        UserRole.student,
      ];
    }
    if (_currentUser.role == UserRole.volunteerCoordinator ||
        _authenticatedRole == UserRole.volunteerCoordinator ||
        _currentUser.coordinatorProfile != null) {
      return [UserRole.volunteerCoordinator, UserRole.student];
    }
    if (_currentUser.role == UserRole.spiritualParent ||
        _authenticatedRole == UserRole.spiritualParent) {
      return [UserRole.spiritualParent, UserRole.student];
    }
    return [UserRole.student];
  }

  bool get canSwitchRoles =>
      _currentUser.role == UserRole.admin ||
      _showDevRoleSwitcher ||
      availableRoles.length > 1;

  bool _showDevRoleSwitcher = false;
  bool get showDevRoleSwitcher => _showDevRoleSwitcher;

  void toggleDevRoleSwitcher([bool? value]) {
    _showDevRoleSwitcher = value ?? !_showDevRoleSwitcher;
    notifyListeners();
  }

  bool _isSeedingData = false;
  bool get isSeedingData => _isSeedingData;

  /// Bulk seed realistic sample Orthodox campus students directly to Firestore users collection
  Future<int> seedTestStudentsToFirestore({int count = 15}) async {
    if (!kDebugMode || !isDemoMode || !isAdmin) return 0;
    _isSeedingData = true;
    notifyListeners();

    final List<Map<String, dynamic>> mockRegistrants = [
      {
        'id': 'test-usr-1',
        'fullName': 'Yohannes Haile',
        'baptismalName': 'Haile Giorgis',
        'email': 'yohannes.haile@wcu.edu.et',
        'phoneNumber': '+251911334455',
        'studentId': 'WCU/1042/14',
        'department': 'Computer Science',
        'academicYear': 4,
        'batchYear': '2023',
        'role': 'spiritualParent',
        'isApproved': true,
      },
      {
        'id': 'test-usr-2',
        'fullName': 'Selamawit Bekele',
        'baptismalName': 'Walata Maryam',
        'email': 'selamawit.bekele@wcu.edu.et',
        'phoneNumber': '+251922445566',
        'studentId': 'WCU/1105/14',
        'department': 'Civil Engineering',
        'academicYear': 4,
        'batchYear': '2023',
        'role': 'spiritualParent',
        'isApproved': true,
      },
      {
        'id': 'test-usr-3',
        'fullName': 'Ephrem Desta',
        'baptismalName': 'Gebre Kristos',
        'email': 'ephrem.desta@wcu.edu.et',
        'phoneNumber': '+251933556677',
        'studentId': 'WCU/2012/15',
        'department': 'Medicine & Surgery',
        'academicYear': 3,
        'batchYear': '2024',
        'role': 'spiritualParent',
        'isApproved': true,
      },
      {
        'id': 'test-usr-4',
        'fullName': 'Martha Solomon',
        'baptismalName': 'Walata Petros',
        'email': 'martha.solomon@wcu.edu.et',
        'phoneNumber': '+251944667788',
        'studentId': 'WCU/2099/15',
        'department': 'Pharmacy',
        'academicYear': 3,
        'batchYear': '2024',
        'role': 'spiritualParent',
        'isApproved': true,
      },
      {
        'id': 'test-usr-5',
        'fullName': 'Tewodros Girma',
        'baptismalName': 'Gebre Eyesus',
        'email': 'tewodros.girma@wcu.edu.et',
        'phoneNumber': '+251955778899',
        'studentId': 'WCU/3011/16',
        'department': 'Mechanical Engineering',
        'academicYear': 2,
        'batchYear': '2025',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-6',
        'fullName': 'Kiros Tadesse',
        'baptismalName': 'Habte Michael',
        'email': 'kiros.tadesse@wcu.edu.et',
        'phoneNumber': '+251966889900',
        'studentId': 'WCU/3055/16',
        'department': 'Electrical Engineering',
        'academicYear': 2,
        'batchYear': '2025',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-7',
        'fullName': 'Birtukan Assefa',
        'baptismalName': 'Kidan Maryam',
        'email': 'birtukan.assefa@wcu.edu.et',
        'phoneNumber': '+251977990011',
        'studentId': 'WCU/3091/16',
        'department': 'Law',
        'academicYear': 2,
        'batchYear': '2025',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-8',
        'fullName': 'Daniel Kassa',
        'baptismalName': 'Tekle Tsion',
        'email': 'daniel.kassa@wcu.edu.et',
        'phoneNumber': '+251988001122',
        'studentId': 'WCU/4015/17',
        'department': 'Accounting & Finance',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-9',
        'fullName': 'Bethlehem Tesfaye',
        'baptismalName': 'Walata Sellassie',
        'email': 'bethlehem.tesfaye@wcu.edu.et',
        'phoneNumber': '+251911224466',
        'studentId': 'WCU/4033/17',
        'department': 'Computer Science',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-10',
        'fullName': 'Henok Mengistu',
        'baptismalName': 'Gebre Rufael',
        'email': 'henok.mengistu@wcu.edu.et',
        'phoneNumber': '+251922335577',
        'studentId': 'WCU/4067/17',
        'department': 'Civil Engineering',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-11',
        'fullName': 'Marta Wolde',
        'baptismalName': 'Walata Yohannes',
        'email': 'marta.wolde@wcu.edu.et',
        'phoneNumber': '+251933446688',
        'studentId': 'WCU/4088/17',
        'department': 'Medicine & Surgery',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-12',
        'fullName': 'Abel Berhanu',
        'baptismalName': 'Haile Meskel',
        'email': 'abel.berhanu@wcu.edu.et',
        'phoneNumber': '+251944557799',
        'studentId': 'WCU/4112/17',
        'department': 'Economics',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-13',
        'fullName': 'Genet Alemayehu',
        'baptismalName': 'Walata Tsion',
        'email': 'genet.alemayehu@wcu.edu.et',
        'phoneNumber': '+251955668800',
        'studentId': 'WCU/4134/17',
        'department': 'Nursing',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-14',
        'fullName': 'Surafel Negash',
        'baptismalName': 'Gebre Gabriel',
        'email': 'surafel.negash@wcu.edu.et',
        'phoneNumber': '+251966779911',
        'studentId': 'WCU/4156/17',
        'department': 'Agriculture & Horticulture',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
      {
        'id': 'test-usr-15',
        'fullName': 'Meron Fikre',
        'baptismalName': 'Walata Kidan',
        'email': 'meron.fikre@wcu.edu.et',
        'phoneNumber': '+251977880022',
        'studentId': 'WCU/4180/17',
        'department': 'Information Systems',
        'academicYear': 1,
        'batchYear': '2026',
        'role': 'student',
        'isApproved': true,
      },
    ];

    int inserted = 0;
    try {
      final firestore = FirebaseFirestore.instance;
      for (final data in mockRegistrants.take(count)) {
        await firestore.collection('users').doc(data['id'] as String).set({
          ...data,
          'campus': 'Main Campus (ዋናው ግቢ)',
          'isTestRecord': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        inserted++;
      }
    } catch (e) {
      debugPrint('Firestore bulk seed notice: $e');
    } finally {
      _isSeedingData = false;
      notifyListeners();
    }
    return inserted;
  }

  /// Wipe all seeded test records from Firestore users collection to free the database
  Future<int> clearTestStudentsFromFirestore() async {
    if (!kDebugMode || !isDemoMode || !isAdmin) return 0;
    _isSeedingData = true;
    notifyListeners();

    int deleted = 0;
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore
          .collection('users')
          .where('isTestRecord', isEqualTo: true)
          .get();
      for (final doc in query.docs) {
        await doc.reference.delete();
        deleted++;
      }
      _allStudents.removeWhere((u) => u.id.startsWith('test-usr-'));
    } catch (e) {
      debugPrint('Firestore clear test records notice: $e');
    } finally {
      _isSeedingData = false;
      notifyListeners();
    }
    return deleted;
  }

  /// Bulk seed all 20 fellowship domains directly into Firestore so the database is fully populated
  Future<int> seedEntireDatabaseToFirestore() async {
    if (!kDebugMode || !isDemoMode || !isAdmin) return 0;
    _isSeedingData = true;
    notifyListeners();

    int totalDocsPushed = 0;
    try {
      // Templates ready in firestoreService if memory lists are empty
      totalDocsPushed = await _firestoreService.seedCompleteDatabase(
        students: List.from(_allStudents),
        pendingApprovals: List.from(_pendingApprovals),
        families: List.from(_families),
        pilgrimageTrips: List.from(_pilgrimageTrips),
        tripRegistrations: List.from(_tripRegistrations),
        libraryItems: List.from(_libraryItems),
        programs: List.from(_programs),
        broadcasts: List.from(_departmentBroadcasts),
        proposals: List.from(_fundraisingProposals),
        applications: List.from(_volunteerApplications),
        members: List.from(_departmentMembers),
        confessors: List.from(_confessorFathers),
        appointments: List.from(_confessionAppointments),
        questions: List.from(_spiritualQuestions),
        campaigns: List.from(_charityCampaigns),
        dues: List.from(_duesPayments),
        disbursements: List.from(_charityDisbursements),
        aidRequests: List.from(_emergencyAidRequests),
        mentors: List.from(_academicMentors),
        mentorshipRequests: List.from(_mentorshipRequests),
        quizAttempts: List.from(_quizAttempts),
        triviaQuizzes: List.from(_triviaQuizzes),
        activeSession: _activeSession,
      );
    } catch (e) {
      debugPrint('Firestore seedEntireDatabase notice: $e');
    } finally {
      _isSeedingData = false;
      notifyListeners();
    }
    return totalDocsPushed;
  }

  // ----------------------------------------------------
  // ROLE CAPABILITIES & PERMISSION CHECKERS (SCOPED RBAC)
  // ----------------------------------------------------
  bool get isAdmin {
    if (_activeRole != UserRole.admin && _currentUser.role != UserRole.admin) {
      return false;
    }
    String? authEmail;
    try {
      authEmail = FirebaseAuth.instance.currentUser?.email;
    } catch (_) {}
    return _isOriginalAdmin ||
        _activeRole == UserRole.admin ||
        _currentUser.role == UserRole.admin ||
        _authenticatedRole == UserRole.admin ||
        AppAdminConstants.isAdminEmail(_currentUser.email) ||
        AppAdminConstants.isAdminEmail(authEmail);
  }

  bool get isCoordinator =>
      _activeRole == UserRole.volunteerCoordinator ||
      _currentUser.role == UserRole.volunteerCoordinator;

  bool isCoordinatorOf(String deptId) {
    if (isAdmin) return true;
    if (_activeRole == UserRole.volunteerCoordinator &&
        _currentUser.coordinatorProfile != null &&
        _currentUser.coordinatorProfile!.isReadOnlyAudit != true &&
        deptId != FellowshipDepartmentConstants.deptAudit) {
      final userDept = _currentUser.coordinatorProfile!.departmentId;
      return userDept == deptId;
    }
    return false;
  }

  /// General student approval is strictly ADMIN only (matches firestore.rules users write restriction)
  bool get canManageApprovals => isAuthorizedAdmin || isAdmin;
  bool get canApproveGeneralStudents => isAuthorizedAdmin || isAdmin;

  /// Spiritual families management (Admin, Spiritual Parent, or Member Care Coordinator)
  bool get canManageFamilies =>
      isAdmin ||
      _activeRole == UserRole.spiritualParent ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptMemberCare);

  /// Financial verification (Admin, Charity Coordinator, or Accounting/Finance Coordinator)
  bool get canVerifyFinances =>
      isAdmin ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptCharity) ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptFinanceProperty);

  /// Priest / Confessor scheduling (Admin only in firestore.rules confessors write)
  bool get canSchedulePriests => isAuthorizedAdmin || isAdmin;

  /// Assigning or promoting roles is strictly ADMIN only.
  bool get canAssignRoles => isAuthorizedAdmin || isAdmin;

  /// Emergency student aid review (Admin, Member Care, Charity, or Accounting Coordinators)
  bool get canManageEmergencyAid =>
      isAdmin ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptMemberCare) ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptCharity) ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptFinanceProperty);

  /// Pilgrimage trip management (Admin or Batch & Programs Coordinator)
  bool get canManagePilgrimages =>
      isAdmin ||
      isCoordinatorOf(FellowshipDepartmentConstants.deptBatchPrograms);

  /// Charity campaigns management (Admin or Charity Coordinator)
  bool get canManageCharityAndAid =>
      isAdmin || isCoordinatorOf(FellowshipDepartmentConstants.deptCharity);

  /// Family matching (Admin or Member Care Coordinator)
  bool get canManageFamilyMatching =>
      isAdmin || isCoordinatorOf(FellowshipDepartmentConstants.deptMemberCare);

  /// Special teacher notices / Apostolic broadcasts (Admin or Apostolic Education Coordinator)
  bool get canPublishSpecialTeacherNotice =>
      isAdmin || isCoordinatorOf(FellowshipDepartmentConstants.deptEducation);

  /// Fundraising proposals (Admin or Development Coordinator)
  bool get canSubmitFundraisingProposal =>
      isAdmin || isCoordinatorOf(FellowshipDepartmentConstants.deptDevelopment);

  /// Scoped RBAC: Checks if current user can view applications & roster of a department.
  /// - Global Admins: Read access to all departments.
  /// - Audit Coordinators (DEPT_AUDIT): Read-only inspection access to all departments.
  /// - Volunteer Coordinators: Confined strictly to their assigned department.
  /// - Normal Students: Denied.
  bool canAccessDepartmentRead(String? targetDeptId) {
    if (isAdmin) return true;
    if (_activeRole == UserRole.volunteerCoordinator) {
      if (_currentUser.coordinatorProfile?.isReadOnlyAudit == true) return true;
      if (targetDeptId == null || targetDeptId.isEmpty) return true;
      final myDept = _currentUser.coordinatorProfile?.departmentId;
      return myDept == targetDeptId;
    }
    return false;
  }

  /// Scoped RBAC: Checks if current user can write/mutate (Approve/Reject) in a department.
  /// - Global Admins: Write access to all departments.
  /// - Audit Coordinators: Strictly BLOCKED (Read-Only Inspection).
  /// - Volunteer Coordinators: Allowed ONLY for their assigned department if canApproveApplicants is true.
  /// - Normal Students: Denied.
  bool canAccessDepartmentWrite(String? targetDeptId) {
    if (isAdmin) return true;
    if (_currentUser.coordinatorProfile?.isReadOnlyAudit == true) return false;
    if (targetDeptId == FellowshipDepartmentConstants.deptAudit) return false;
    if (_activeRole == UserRole.volunteerCoordinator) {
      final myDept = _currentUser.coordinatorProfile?.departmentId;
      if (myDept == FellowshipDepartmentConstants.deptAudit) return false;
      final canApprove =
          _currentUser.coordinatorProfile?.canApproveApplicants ?? false;
      return canApprove && myDept == targetDeptId;
    }
    return false;
  }

  /// Scoped RBAC: Checks if current user can view a student's spiritual roadmap progress.
  /// - Global Admins & Self: Full access.
  /// - Spiritual Parents: Access confined ONLY to spiritual children within their assigned family.
  /// - Others: Denied access to other students' roadmaps.
  bool canAccessStudentRoadmap(String targetStudentId) {
    if (isAdmin) return true;
    if (_currentUser.id == targetStudentId) return true;
    if (_activeRole == UserRole.spiritualParent) {
      final myFamily = currentStudentFamily;
      if (myFamily != null && myFamily.memberIds.contains(targetStudentId)) {
        return true;
      }
      return false;
    }
    return false;
  }

  AppThemePalette _currentThemePalette = AppThemePalette.midnightFellowship;
  AppThemePalette get currentThemePalette => _currentThemePalette;

  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_themePrefKey);
      if (savedIndex != null &&
          savedIndex >= 0 &&
          savedIndex < AppThemePalette.values.length) {
        _currentThemePalette = AppThemePalette.values[savedIndex];
        notifyListeners();
      }
    } catch (_) {
      // Fallback silently if storage unavailable
    }
  }

  Future<void> setThemePalette(AppThemePalette palette) async {
    _currentThemePalette = palette;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefKey, palette.index);
    } catch (_) {}
  }

  UserModel _currentUser = UserModel(
    id: 'usr-pending',
    fullName: 'Fellowship Student',
    baptismalName: '',
    phoneNumber: '',
    batchYear: '2024',
    department: 'General',
    academicYear: 1,
    role: UserRole.student,
    isApproved: false,
    badges: const [],
    ministryStatus: 'New Member',
  );

  UserModel get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    if (user.role == UserRole.admin) {
      _isOriginalAdmin = true;
    } else {
      _isOriginalAdmin = false;
    }
    _authenticatedRole = user.role;
    _assignedRole = user.role;
    _activeRole = user.role;
    final idx = _allStudents.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      _allStudents[idx] = _currentUser;
    } else {
      _allStudents.insert(0, _currentUser);
    }
    notifyListeners();
  }

  void updateCurrentUserProfile({
    String? id,
    required String fullName,
    String? baptismalName,
    String? phoneNumber,
    String? department,
    int? academicYear,
    String? batchYear,
    UserRole? role,
    bool? isApproved,
    String? assignedFamilyId,
    String? ministryStatus,
    List<String>? badges,
    String? avatarUrl,
    double? attendancePercentage,
    CoordinatorProfileModel? coordinatorProfile,
    String? gender,
  }) {
    // Capture previous values BEFORE mutating state so we can detect meaningful changes.
    final previousId = _currentUser.id;
    final previousRole = _currentUser.role;
    final previousApproved = _currentUser.isApproved;

    final effectiveRole = role ?? _currentUser.role;
    if (effectiveRole == UserRole.admin) {
      _isOriginalAdmin = true;
    } else {
      _isOriginalAdmin = false;
    }

    _currentUser = _currentUser.copyWith(
      id: id ?? _currentUser.id,
      fullName: fullName,
      baptismalName: baptismalName ?? _currentUser.baptismalName,
      phoneNumber: phoneNumber ?? _currentUser.phoneNumber,
      department: department ?? _currentUser.department,
      academicYear: academicYear ?? _currentUser.academicYear,
      batchYear: batchYear ?? _currentUser.batchYear,
      role: effectiveRole,
      isApproved: isApproved ?? _currentUser.isApproved,
      assignedFamilyId: assignedFamilyId ?? _currentUser.assignedFamilyId,
      ministryStatus: ministryStatus ?? _currentUser.ministryStatus,
      badges: badges ?? _currentUser.badges,
      avatarUrl: avatarUrl ?? _currentUser.avatarUrl,
      attendancePercentage:
          attendancePercentage ?? _currentUser.attendancePercentage,
      coordinatorProfile: coordinatorProfile ?? _currentUser.coordinatorProfile,
      gender: gender ?? _currentUser.gender,
    );

    if (role != null) {
      _activeRole = role;
      _authenticatedRole = role;
      _assignedRole = role;
      if (role == UserRole.admin) {
        _isOriginalAdmin = true;
      } else {
        _isOriginalAdmin = false;
      }
    }

    final idx = _allStudents.indexWhere((u) => u.id == _currentUser.id);
    if (idx >= 0) {
      _allStudents[idx] = _currentUser;
    } else {
      _allStudents.insert(0, _currentUser);
    }
    notifyListeners();
    // Only re-scope Firestore streams when the UID, role, or approval status
    // actually changed — avoids tearing down all listeners on every profile edit.
    final idChanged = (id != null && id != previousId);
    final roleChanged = (role != null && role != previousRole);
    final approvalChanged = (isApproved != null && isApproved != previousApproved);
    if ((idChanged || roleChanged || approvalChanged) && this is FellowshipState) {
      (this as FellowshipState).refreshScopedStreams();
    }
  }

  /// Updates current user profile in state and persists the changes directly to Firestore
  Future<void> saveUserProfile({
    required String fullName,
    required String baptismalName,
    required String phoneNumber,
    required String department,
    required int academicYear,
    required String batchYear,
    String? gender,
  }) async {
    updateCurrentUserProfile(
      fullName: fullName.trim(),
      baptismalName: baptismalName.trim(),
      phoneNumber: phoneNumber.trim(),
      department: department.trim(),
      academicYear: academicYear,
      batchYear: batchYear.trim(),
      gender: gender?.trim().toLowerCase(),
    );

    final uid = _currentUser.id.trim().isNotEmpty
        ? _currentUser.id.trim()
        : FirebaseAuth.instance.currentUser?.uid;

    if (uid != null && uid.isNotEmpty) {
      final updateData = <String, dynamic>{
        'fullName': fullName.trim(),
        'baptismalName': baptismalName.trim(),
        'phoneNumber': phoneNumber.trim(),
        'department': department.trim(),
        'academicYear': academicYear,
        'batchYear': batchYear.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (gender != null && gender.trim().isNotEmpty) {
        updateData['gender'] = gender.trim().toLowerCase();
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(updateData, SetOptions(merge: true));
      } catch (e) {
        debugPrint('saveUserProfile Firestore error: $e');
      }
    }
  }

  Future<void> updateFamilyTelegramLink(
    String familyId,
    String newTelegramUrl,
  ) async {
    if (!canManageFamilies)
      throw StateError(
        'You do not have permission to edit family group links.',
      );
    final familyIndex = _families.indexWhere((family) => family.id == familyId);
    if (familyIndex < 0) throw StateError('This family no longer exists.');
    final uri = Uri.tryParse(newTelegramUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host != 't.me') {
      throw FormatException(
        'Enter a Telegram invite link that starts with https://t.me/.',
      );
    }

    await _firestoreService.updateFamilyTelegramLink(familyId, uri.toString());
    _families[familyIndex] = _families[familyIndex].copyWith(
      telegramGroupUrl: uri.toString(),
    );
    notifyListeners();
  }

  void switchRole(UserRole newRole, {String? coordinatorDeptId}) {
    if (_activeRole == UserRole.admin ||
        _authenticatedRole == UserRole.admin ||
        _currentUser.role == UserRole.admin) {
      _isOriginalAdmin = true;
    }

    _activeRole = newRole;
    CoordinatorProfileModel? coordProfile = _currentUser.coordinatorProfile;

    if (newRole == UserRole.volunteerCoordinator) {
      final targetDept =
          coordinatorDeptId ??
          coordProfile?.departmentId ??
          FellowshipDepartmentConstants.deptEducation;
      final isAudit = targetDept == FellowshipDepartmentConstants.deptAudit;
      coordProfile = CoordinatorProfileModel(
        departmentId: targetDept,
        departmentNameAmharic: FellowshipDepartmentConstants.getNameAmharic(
          targetDept,
        ),
        departmentNameEn: FellowshipDepartmentConstants.getNameEn(targetDept),
        coordinatorTitle: isAudit
            ? 'Audit & Inspection Inspector'
            : 'Department Coordinator',
        appointedDate: coordProfile?.appointedDate ?? DateTime(2024, 9, 1),
        canApproveApplicants: !isAudit,
        canManageRoster: !isAudit,
        canPublishAnnouncements: true,
        isReadOnlyAudit: isAudit,
      );
      _selectedCoordinatorDepartmentId = targetDept;
    }

    _currentUser = _currentUser.copyWith(
      role: newRole,
      coordinatorProfile: coordProfile ?? _currentUser.coordinatorProfile,
      assignedFamilyId: newRole == UserRole.spiritualParent
          ? 'fam-st-george'
          : _currentUser.assignedFamilyId,
    );
    notifyListeners();
  }

  void switchCoordinatorDepartment(String departmentId) {
    final isAudit = departmentId == FellowshipDepartmentConstants.deptAudit;
    final profile = CoordinatorProfileModel(
      departmentId: departmentId,
      departmentNameAmharic: FellowshipDepartmentConstants.getNameAmharic(
        departmentId,
      ),
      departmentNameEn: FellowshipDepartmentConstants.getNameEn(departmentId),
      coordinatorTitle: isAudit
          ? 'Audit & Inspection Inspector'
          : 'Department Coordinator',
      appointedDate: DateTime(2024, 9, 1),
      canApproveApplicants: !isAudit,
      canManageRoster: !isAudit,
      canPublishAnnouncements: true,
      isReadOnlyAudit: isAudit,
    );
    _currentUser = _currentUser.copyWith(
      role: UserRole.volunteerCoordinator,
      coordinatorProfile: profile,
    );
    _activeRole = UserRole.volunteerCoordinator;
    _selectedCoordinatorDepartmentId = departmentId;
    notifyListeners();
  }

  void updateCurrentUserModel(UserModel updated) {
    _currentUser = updated;
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 1: AUTHENTICATION & DYNAMIC PROFILE
  // ----------------------------------------------------
  // ignore: prefer_final_fields
  List<UserModel> _allStudents = [];
  List<UserModel> _pendingApprovals = [];

  List<UserModel> get allStudents => List.unmodifiable(_allStudents);
  List<UserModel> get pendingApprovals => List.unmodifiable(_pendingApprovals);

  void registerStudent({
    required String fullName,
    required String baptismalName,
    required String phoneNumber,
    required String batchYear,
    required String department,
    required int academicYear,
    String gender = 'male',
  }) {
    String? authUid;
    try {
      authUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    final newStudent = UserModel(
      id: authUid ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      baptismalName: baptismalName,
      phoneNumber: phoneNumber,
      batchYear: batchYear,
      department: department,
      academicYear: academicYear,
      role: UserRole.student,
      isApproved: false, // Requires admin verification
      badges: ['New Fellow'],
      ministryStatus: 'General Member',
      gender: gender,
    );

    _pendingApprovals.add(newStudent);
    _currentUser = newStudent;
    notifyListeners();

    if (authUid == null || authUid.isEmpty) {
      return;
    }

    // Write to Firestore asynchronously; surface errors to log
    try {
      FirebaseFirestore.instance
          .collection('users')
          .doc(authUid)
          .set(newStudent.toMap(), SetOptions(merge: true))
          .then((_) {
            debugPrint(
              'registerStudent: Firestore write succeeded for $authUid',
            );
          })
          .catchError((e) {
            debugPrint(
              'Firestore registerStudent error (offline or permission): $e',
            );
          });
    } catch (e) {
      debugPrint('Firestore registerStudent notice: $e');
    }
  }

  Future<bool> approveStudent(
    String studentId, {
    UserRole role = UserRole.student,
    String? departmentId,
  }) async {
    if (!canApproveGeneralStudents) {
      return false;
    }
    final index = _pendingApprovals.indexWhere((u) => u.id == studentId);
    if (index == -1) return false;

    final originalPendingStudent = _pendingApprovals[index];
    CoordinatorProfileModel? coordProfile;
    if (role == UserRole.volunteerCoordinator) {
      final targetDept = departmentId ??
          originalPendingStudent.coordinatorProfile?.departmentId ??
          FellowshipDepartmentConstants.deptEducation;
      final isAudit = targetDept == FellowshipDepartmentConstants.deptAudit;
      coordProfile = CoordinatorProfileModel(
        departmentId: targetDept,
        departmentNameAmharic:
            FellowshipDepartmentConstants.getNameAmharic(targetDept),
        departmentNameEn: FellowshipDepartmentConstants.getNameEn(targetDept),
        coordinatorTitle: isAudit
            ? 'Audit & Inspection Inspector'
            : 'Department Coordinator',
        appointedDate: DateTime.now(),
        canApproveApplicants: !isAudit,
        canManageRoster: !isAudit,
        canPublishAnnouncements: true,
        isReadOnlyAudit: isAudit,
      );
    }

    final approvedStudent = originalPendingStudent.copyWith(
      isApproved: true,
      role: role,
      coordinatorProfile: coordProfile,
    );

    // Optimistically update local lists
    _pendingApprovals.removeAt(index);
    final previousAllStudentIndex = _allStudents.indexWhere((user) => user.id == studentId);
    final previousAllStudent = previousAllStudentIndex >= 0 ? _allStudents[previousAllStudentIndex] : null;
    if (previousAllStudentIndex >= 0) {
      _allStudents[previousAllStudentIndex] = approvedStudent;
    } else {
      _allStudents.add(approvedStudent);
    }
    final previousCurrentUser = _currentUser;
    if (_currentUser.id == studentId) {
      _currentUser = approvedStudent;
    }
    notifyListeners();

    try {
      final updateData = <String, dynamic>{
        'isApproved': true,
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (coordProfile != null) {
        updateData['coordinatorProfile'] = coordProfile.toMap();
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .set(updateData, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Firestore approveStudent failed: $e');
      // Rollback optimistic update
      if (index <= _pendingApprovals.length) {
        _pendingApprovals.insert(index, originalPendingStudent);
      } else {
        _pendingApprovals.add(originalPendingStudent);
      }
      _allStudents.removeWhere((user) => user.id == studentId);
      if (previousAllStudent != null) {
        _allStudents.add(previousAllStudent);
      }
      if (_currentUser.id == studentId) {
        _currentUser = previousCurrentUser;
      }
      notifyListeners();
      return false;
    }
  }

  Future<int> approveMultipleStudents(
    List<String> studentIds, {
    UserRole role = UserRole.student,
  }) async {
    if (!canApproveGeneralStudents ||
        studentIds.isEmpty ||
        role == UserRole.volunteerCoordinator)
      return 0;
    final requestedIds = studentIds.toSet();
    final pending = _pendingApprovals
        .where((u) => requestedIds.contains(u.id))
        .toList();
    if (pending.isEmpty) return 0;

    final approvedIds = <String>{};
    final firestore = FirebaseFirestore.instance;
    for (var start = 0; start < pending.length; start += 450) {
      final chunk = pending.skip(start).take(450).toList();
      final batch = firestore.batch();
      for (final user in chunk) {
        batch.update(firestore.collection('users').doc(user.id), {
          'isApproved': true,
          'role': role.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      try {
        await batch.commit();
        approvedIds.addAll(chunk.map((user) => user.id));
      } catch (e) {
        debugPrint('Firestore approveMultipleStudents failed for batch: $e');
        break;
      }
    }

    if (approvedIds.isEmpty) return 0;
    final approvedUsers = _pendingApprovals
        .where((user) => approvedIds.contains(user.id))
        .map((user) => user.copyWith(isApproved: true, role: role))
        .toList();
    _pendingApprovals.removeWhere((user) => approvedIds.contains(user.id));
    _allStudents.removeWhere((user) => approvedIds.contains(user.id));
    _allStudents.addAll(approvedUsers);
    for (final user in approvedUsers) {
      if (_currentUser.id == user.id) _currentUser = user;
    }
    notifyListeners();
    return approvedUsers.length;
  }

  void rejectStudent(String studentId) {
    if (!canApproveGeneralStudents) return;
    _pendingApprovals.removeWhere((u) => u.id == studentId);
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('users').doc(studentId).delete();
    } catch (e) {
      debugPrint('Firestore rejectStudent notice: $e');
    }
  }

  void rejectMultipleStudents(List<String> studentIds) {
    if (!canApproveGeneralStudents || studentIds.isEmpty) return;
    final Set<String> targetIds = studentIds.toSet();
    _pendingApprovals.removeWhere((u) => targetIds.contains(u.id));
    notifyListeners();

    try {
      for (final id in studentIds) {
        FirebaseFirestore.instance.collection('users').doc(id).delete();
      }
    } catch (e) {
      debugPrint('Firestore rejectMultipleStudents notice: $e');
    }
  }

  Future<int> approveAllPendingStudents({
    UserRole role = UserRole.student,
  }) async {
    if (!canApproveGeneralStudents || _pendingApprovals.isEmpty) return 0;
    final allIds = _pendingApprovals.map((u) => u.id).toList();
    return approveMultipleStudents(allIds, role: role);
  }

  Future<bool> assignUserRole(
    String studentId,
    UserRole role, {
    String? departmentId,
  }) async {
    if (!isAuthorizedAdmin && !isAdmin) return false;
    final index = _allStudents.indexWhere((u) => u.id == studentId);
    UserModel targetStudent;
    bool wasPending = false;
    if (index >= 0) {
      targetStudent = _allStudents[index];
    } else {
      final pIndex = _pendingApprovals.indexWhere((u) => u.id == studentId);
      if (pIndex >= 0) {
        targetStudent = _pendingApprovals[pIndex];
        wasPending = true;
      } else {
        return false;
      }
    }

    CoordinatorProfileModel? coordProfile;
    if (role == UserRole.volunteerCoordinator) {
      final targetDept =
          departmentId ?? targetStudent.coordinatorProfile?.departmentId ?? FellowshipDepartmentConstants.deptEducation;
      final isAudit = targetDept == FellowshipDepartmentConstants.deptAudit;
      coordProfile = CoordinatorProfileModel(
        departmentId: targetDept,
        departmentNameAmharic: FellowshipDepartmentConstants.getNameAmharic(
          targetDept,
        ),
        departmentNameEn: FellowshipDepartmentConstants.getNameEn(targetDept),
        coordinatorTitle: isAudit
            ? 'Audit & Inspection Inspector'
            : 'Department Coordinator',
        appointedDate:
            targetStudent.coordinatorProfile?.appointedDate ??
            DateTime.now(),
        canApproveApplicants: !isAudit,
        canManageRoster: !isAudit,
        canPublishAnnouncements: true,
        isReadOnlyAudit: isAudit,
      );
    }

    try {
      final updateData = <String, dynamic>{
        'isApproved': true,
        'role': role.name,
        'coordinatorProfile': coordProfile?.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore assignUserRole failed: $e');
      return false;
    }

    final updatedUser = targetStudent.copyWith(
      isApproved: true,
      role: role,
      coordinatorProfile: coordProfile,
    );
    if (wasPending) {
      _pendingApprovals.removeWhere((u) => u.id == studentId);
      _allStudents.add(updatedUser);
    } else {
      _allStudents[index] = updatedUser;
    }
    if (_currentUser.id == studentId) {
      _currentUser = updatedUser;
      _assignedRole = role;
      _activeRole = role;
    }
    notifyListeners();
    return true;
  }

  /// Admin-specific scope reassignment for volunteer coordinators
  Future<bool> updateCoordinatorScope(
    String studentId,
    String newDepartmentId,
  ) async {
    return assignUserRole(
      studentId,
      UserRole.volunteerCoordinator,
      departmentId: newDepartmentId,
    );
  }

  /// Admin revocation of coordinator access, reverting to general student role
  Future<bool> revokeCoordinatorAccess(String studentId) async {
    return assignUserRole(studentId, UserRole.student);
  }
}
