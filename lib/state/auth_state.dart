part of 'fellowship_state.dart';

/// Feature slice managing Authentication, Active User, Theme, RBAC & Student Approvals.
class AuthState extends ChangeNotifier {
  final FellowshipState root; AuthState(this.root);
  void refresh() => notifyListeners();
}

mixin AuthStateMixin on ChangeNotifier {
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

  /// Returns the roles this user is authorized to access and switch between.
  /// - Admin: All 4 access points (Admin, Volunteer Coordinator, Spiritual Parent, Student).
  /// - Volunteer Coordinator: 2 access points (Volunteer Coordinator, Student).
  /// - Spiritual Parent: 2 access points (Spiritual Parent, Student).
  /// - Student: Student only (unless developer mode is explicitly enabled by Admin).
  List<UserRole> get availableRoles {
    final baseRole = _authenticatedRole != UserRole.student ? _authenticatedRole : _assignedRole;
    if (_showDevRoleSwitcher ||
        baseRole == UserRole.admin ||
        _authenticatedRole == UserRole.admin ||
        _assignedRole == UserRole.admin ||
        _currentUser.role == UserRole.admin ||
        _activeRole == UserRole.admin) {
      return [
        UserRole.admin,
        UserRole.volunteerCoordinator,
        UserRole.spiritualParent,
        UserRole.student,
      ];
    }
    if (baseRole == UserRole.volunteerCoordinator ||
        _authenticatedRole == UserRole.volunteerCoordinator ||
        _assignedRole == UserRole.volunteerCoordinator ||
        _currentUser.role == UserRole.volunteerCoordinator ||
        _currentUser.coordinatorProfile != null ||
        _activeRole == UserRole.volunteerCoordinator) {
      return [
        UserRole.volunteerCoordinator,
        UserRole.student,
      ];
    }
    if (baseRole == UserRole.spiritualParent ||
        _authenticatedRole == UserRole.spiritualParent ||
        _assignedRole == UserRole.spiritualParent ||
        _currentUser.role == UserRole.spiritualParent ||
        _activeRole == UserRole.spiritualParent) {
      return [
        UserRole.spiritualParent,
        UserRole.student,
      ];
    }
    return [UserRole.student];
  }

  bool get canSwitchRoles =>
      _authenticatedRole == UserRole.admin ||
      _assignedRole == UserRole.admin ||
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
    _isSeedingData = true;
    notifyListeners();

    int deleted = 0;
    try {
      final firestore = FirebaseFirestore.instance;
      final query = await firestore.collection('users').where('isTestRecord', isEqualTo: true).get();
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
    _isSeedingData = true;
    notifyListeners();

    int totalDocsPushed = 0;
    try {
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
  bool get isAdmin => _activeRole == UserRole.admin;
  bool get canManageApprovals => _activeRole == UserRole.admin || _activeRole == UserRole.volunteerCoordinator;
  bool get canManageFamilies => _activeRole == UserRole.admin || _activeRole == UserRole.spiritualParent;
  bool get canVerifyFinances => _activeRole == UserRole.admin;

  /// General student registration acceptance is strictly ADMIN only.
  bool get canApproveGeneralStudents => isAdmin;

  /// Priest / Confessor scheduling is strictly ADMIN / Clergy Liaison only.
  bool get canSchedulePriests => isAdmin;

  /// Assigning or promoting roles is strictly ADMIN only.
  bool get canAssignRoles => isAdmin;

  /// Emergency student aid review is strictly ADMIN or 'አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ' (deptMemberCare).
  bool get canManageEmergencyAid =>
      isAdmin || (_activeRole == UserRole.volunteerCoordinator && _currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptMemberCare);

  /// Pilgrimage trip payment verification is strictly ADMIN or 'ባችና መርሐ ግብራት' (deptBatchPrograms).
  bool get canManagePilgrimages =>
      isAdmin || (_activeRole == UserRole.volunteerCoordinator && _currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptBatchPrograms);

  bool get canManageCharityAndAid =>
      isAdmin || (_activeRole == UserRole.volunteerCoordinator && _currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptCharity);

  bool get canManageFamilyMatching =>
      isAdmin || (_activeRole == UserRole.volunteerCoordinator && _currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptMemberCare);

  bool get canPublishSpecialTeacherNotice =>
      isAdmin || (_activeRole == UserRole.volunteerCoordinator && _currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptEducation);

  bool get canSubmitFundraisingProposal =>
      isAdmin || (_activeRole == UserRole.volunteerCoordinator && _currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptDevelopment);

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
    if (_activeRole == UserRole.volunteerCoordinator) {
      final myDept = _currentUser.coordinatorProfile?.departmentId;
      final canApprove = _currentUser.coordinatorProfile?.canApproveApplicants ?? false;
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
      if (savedIndex != null && savedIndex >= 0 && savedIndex < AppThemePalette.values.length) {
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
    assignedFamilyId: 'fam-st-george',
    attendancePercentage: 0.0,
  );

  UserModel get currentUser => _currentUser;

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    _authenticatedRole = user.role;
    _assignedRole = user.role;
    _activeRole = user.role;
    final idx = _allStudents.indexWhere((u) => u.id == user.id || u.fullName.toLowerCase() == user.fullName.toLowerCase());
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
    _currentUser = _currentUser.copyWith(
      id: id ?? _currentUser.id,
      fullName: fullName,
      baptismalName: baptismalName ?? _currentUser.baptismalName,
      phoneNumber: phoneNumber ?? _currentUser.phoneNumber,
      department: department ?? _currentUser.department,
      academicYear: academicYear ?? _currentUser.academicYear,
      batchYear: batchYear ?? _currentUser.batchYear,
      role: role ?? _currentUser.role,
      isApproved: isApproved ?? _currentUser.isApproved,
      assignedFamilyId: assignedFamilyId ?? _currentUser.assignedFamilyId,
      ministryStatus: ministryStatus ?? _currentUser.ministryStatus,
      badges: badges ?? _currentUser.badges,
      avatarUrl: avatarUrl ?? _currentUser.avatarUrl,
      attendancePercentage: attendancePercentage ?? _currentUser.attendancePercentage,
      coordinatorProfile: coordinatorProfile ?? _currentUser.coordinatorProfile,
      gender: gender ?? _currentUser.gender,
    );
    if (role != null) {
      _activeRole = role;
      _authenticatedRole = role;
      _assignedRole = role;
    }
    final idx = _allStudents.indexWhere((u) => u.id == _currentUser.id || u.id == 'usr-current' || u.fullName.toLowerCase() == _currentUser.fullName.toLowerCase());
    if (idx >= 0) {
      _allStudents[idx] = _currentUser;
    } else {
      _allStudents.insert(0, _currentUser);
    }
    notifyListeners();
  }

  Future<void> updateFamilyTelegramLink(String familyId, String newTelegramUrl) async {
    final index = _families.indexWhere((f) => f.id == familyId);
    if (index >= 0) {
      _families[index] = _families[index].copyWith(telegramGroupUrl: newTelegramUrl);
      notifyListeners();
    }
    try {
      await FirebaseFirestore.instance.collection('families').doc(familyId).set({
        'telegramGroupUrl': newTelegramUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Fallback silently if offline
    }
  }

  void switchRole(UserRole newRole, {String? coordinatorDeptId}) {
    _activeRole = newRole;
    CoordinatorProfileModel? coordProfile = _currentUser.coordinatorProfile;

    if (newRole == UserRole.volunteerCoordinator) {
      final targetDept = coordinatorDeptId ?? coordProfile?.departmentId ?? FellowshipDepartmentConstants.deptChoirArts;
      final isAudit = targetDept == FellowshipDepartmentConstants.deptAudit;
      coordProfile = CoordinatorProfileModel(
        departmentId: targetDept,
        departmentNameAmharic: FellowshipDepartmentConstants.getNameAmharic(targetDept),
        departmentNameEn: FellowshipDepartmentConstants.getNameEn(targetDept),
        coordinatorTitle: isAudit ? 'Audit & Inspection Inspector' : 'Department Coordinator',
        appointedDate: DateTime(2024, 9, 1),
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
      assignedFamilyId: newRole == UserRole.spiritualParent ? 'fam-st-george' : _currentUser.assignedFamilyId,
    );
    notifyListeners();
  }

  void switchCoordinatorDepartment(String departmentId) {
    final isAudit = departmentId == FellowshipDepartmentConstants.deptAudit;
    final profile = CoordinatorProfileModel(
      departmentId: departmentId,
      departmentNameAmharic: FellowshipDepartmentConstants.getNameAmharic(departmentId),
      departmentNameEn: FellowshipDepartmentConstants.getNameEn(departmentId),
      coordinatorTitle: isAudit ? 'Audit & Inspection Inspector' : 'Department Coordinator',
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
    final newStudent = UserModel(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
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
      attendancePercentage: 100.0,
      gender: gender,
    );

    _pendingApprovals.add(newStudent);
    _currentUser = newStudent;
    notifyListeners();

    // Write to Firestore asynchronously; surface errors to log
    FirebaseFirestore.instance.collection('users').doc(newStudent.id).set(
      newStudent.toMap(),
      SetOptions(merge: true),
    ).then((_) {
      debugPrint('registerStudent: Firestore write succeeded for ${newStudent.id}');
    }).catchError((e) {
      debugPrint('Firestore registerStudent error (offline or permission): $e');
      // Data is already saved locally via _pendingApprovals & _currentUser.
      // The next time the user comes online, the Firestore stream will re-sync.
    });
  }

  void approveStudent(String studentId, {UserRole role = UserRole.student}) {
    if (!canApproveGeneralStudents) return;
    final index = _pendingApprovals.indexWhere((u) => u.id == studentId);
    if (index != -1) {
      final targetFamilyId = _families.isNotEmpty ? _families.first.id : null;
      final student = _pendingApprovals.removeAt(index).copyWith(
        isApproved: true,
        role: role,
        assignedFamilyId: targetFamilyId,
      );
      _allStudents.add(student);

      // Synchronize family roster by inserting student id into target family
      if (targetFamilyId != null) {
        final fIdx = _families.indexWhere((f) => f.id == targetFamilyId);
        if (fIdx != -1) {
          final f = _families[fIdx];
          if (!f.memberIds.contains(student.id)) {
            final updatedMembers = List<String>.from(f.memberIds)..add(student.id);
            _families[fIdx] = f.copyWith(memberIds: updatedMembers);
          }
        }
      }

      if (_currentUser.id == studentId) {
        _currentUser = student;
      }
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('users').doc(studentId).set({
          'isApproved': true,
          'role': role.name,
          'assignedFamilyId': targetFamilyId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore approveStudent notice: $e');
      }
    }
  }

  void approveMultipleStudents(List<String> studentIds, {UserRole role = UserRole.student}) {
    if (!canApproveGeneralStudents || studentIds.isEmpty) return;
    final targetFamilyId = _families.isNotEmpty ? _families.first.id : null;
    final Set<String> targetIds = studentIds.toSet();
    final List<UserModel> approvedList = [];

    _pendingApprovals.removeWhere((u) {
      if (targetIds.contains(u.id)) {
        final approvedStudent = u.copyWith(
          isApproved: true,
          role: role,
          assignedFamilyId: targetFamilyId,
        );
        approvedList.add(approvedStudent);
        if (_currentUser.id == u.id) {
          _currentUser = approvedStudent;
        }
        return true;
      }
      return false;
    });

    _allStudents.addAll(approvedList);

    // Synchronize family roster
    if (targetFamilyId != null && approvedList.isNotEmpty) {
      final fIdx = _families.indexWhere((f) => f.id == targetFamilyId);
      if (fIdx != -1) {
        final f = _families[fIdx];
        final newMemberIds = approvedList.map((s) => s.id).where((id) => !f.memberIds.contains(id)).toList();
        if (newMemberIds.isNotEmpty) {
          final updatedMembers = List<String>.from(f.memberIds)..addAll(newMemberIds);
          _families[fIdx] = f.copyWith(memberIds: updatedMembers);
        }
      }
    }

    notifyListeners();

    try {
      for (final s in approvedList) {
        FirebaseFirestore.instance.collection('users').doc(s.id).set({
          'isApproved': true,
          'role': role.name,
          'assignedFamilyId': targetFamilyId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Firestore approveMultipleStudents notice: $e');
    }
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

  void approveAllPendingStudents({UserRole role = UserRole.student}) {
    if (!canApproveGeneralStudents || _pendingApprovals.isEmpty) return;
    final allIds = _pendingApprovals.map((u) => u.id).toList();
    approveMultipleStudents(allIds, role: role);
  }

  Future<void> assignUserRole(String studentId, UserRole role) async {
    if (!isAdmin) return;
    final index = _allStudents.indexWhere((u) => u.id == studentId);
    if (index != -1) {
      CoordinatorProfileModel? coordProfile = _allStudents[index].coordinatorProfile;
      if (role == UserRole.volunteerCoordinator && coordProfile == null) {
        coordProfile = CoordinatorProfileModel(
          departmentId: FellowshipDepartmentConstants.deptChoirArts,
          departmentNameAmharic: FellowshipDepartmentConstants.getNameAmharic(FellowshipDepartmentConstants.deptChoirArts),
          departmentNameEn: FellowshipDepartmentConstants.getNameEn(FellowshipDepartmentConstants.deptChoirArts),
          coordinatorTitle: 'Department Coordinator',
          appointedDate: DateTime.now(),
        );
      }
      _allStudents[index] = _allStudents[index].copyWith(role: role, coordinatorProfile: coordProfile);
      if (_currentUser.id == studentId) {
        _currentUser = _allStudents[index];
        _assignedRole = role;
        _activeRole = role;
      }
      notifyListeners();
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(studentId).set({
        'role': role.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Fallback silently if offline
    }
  }

}


