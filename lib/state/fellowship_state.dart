import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_models.dart';

class FellowshipState extends ChangeNotifier {
  // ----------------------------------------------------
  // ACTIVE USER & ROLE SWITCHING
  // ----------------------------------------------------
  UserRole _activeRole = UserRole.student;
  UserRole get activeRole => _activeRole;

  UserModel _currentUser = UserModel(
    id: 'usr-current',
    fullName: 'Teklehaimanot Girma',
    baptismalName: 'Haile Meskel',
    phoneNumber: '+251912345678',
    batchYear: '2024',
    department: 'Computer Science',
    academicYear: 3,
    role: UserRole.student,
    isApproved: true,
    badges: ['Faith Foundations Level 1', 'Patristics Scholar', 'Active Servitor'],
    ministryStatus: 'Yaredic Choir Member',
    assignedFamilyId: 'fam-st-george',
    attendancePercentage: 88.5,
  );

  UserModel get currentUser => _currentUser;

  void switchRole(UserRole newRole) {
    _activeRole = newRole;
    _currentUser = _currentUser.copyWith(role: newRole);
    notifyListeners();
  }

  void updateCurrentUserProfile(UserModel updated) {
    _currentUser = updated;
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 1: AUTHENTICATION & DYNAMIC PROFILE
  // ----------------------------------------------------
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
    );

    _pendingApprovals.add(newStudent);
    _currentUser = newStudent;
    notifyListeners();
  }

  void approveStudent(String studentId, {UserRole role = UserRole.student}) {
    final index = _pendingApprovals.indexWhere((u) => u.id == studentId);
    if (index != -1) {
      final student = _pendingApprovals.removeAt(index).copyWith(
        isApproved: true,
        role: role,
        assignedFamilyId: _families.isNotEmpty ? _families.first.id : null,
      );
      _allStudents.add(student);
      if (_currentUser.id == studentId) {
        _currentUser = student;
      }
      notifyListeners();
    }
  }

  void rejectStudent(String studentId) {
    _pendingApprovals.removeWhere((u) => u.id == studentId);
    notifyListeners();
  }

  void assignUserRole(String studentId, UserRole role) {
    final index = _allStudents.indexWhere((u) => u.id == studentId);
    if (index != -1) {
      _allStudents[index] = _allStudents[index].copyWith(role: role);
      if (_currentUser.id == studentId) {
        _currentUser = _allStudents[index];
      }
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // DOMAIN 2: ORTHODOX FAMILY NETWORK
  // ----------------------------------------------------
  List<FamilyModel> _families = [];
  bool _isFamilyPublished = true; // Staged vs Published
  bool _isMatchingRunning = false;

  List<FamilyModel> get families => List.unmodifiable(_families);
  bool get isFamilyPublished => _isFamilyPublished;
  bool get isMatchingRunning => _isMatchingRunning;

  FamilyModel? get currentStudentFamily {
    final famId = _currentUser.assignedFamilyId;
    if (famId == null) return _families.isNotEmpty ? _families.first : null;
    try {
      return _families.firstWhere((f) => f.id == famId);
    } catch (_) {
      return _families.isNotEmpty ? _families.first : null;
    }
  }

  List<UserModel> get currentFamilySiblings {
    final fam = currentStudentFamily;
    if (fam == null) return [];
    return _allStudents.where((s) => fam.memberIds.contains(s.id) && s.id != _currentUser.id).toList();
  }

  void setFamilyPublished(bool published) {
    _isFamilyPublished = published;
    _families = _families.map((f) => f.copyWith(isPublished: published)).toList();
    notifyListeners();
  }

  Future<void> runSmartMatching() async {
    _isMatchingRunning = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    // Constrained Matching Engine:
    // 1. Group students by faculty/department affinity
    // 2. Distribute evenly across families according to capacity
    final unassigned = List<UserModel>.from(_allStudents);
    final updatedFamilies = _families.map((f) => f.copyWith(memberIds: [])).toList();

    // Map department to faculty cluster
    unassigned.sort((a, b) => a.department.compareTo(b.department));

    int familyIndex = 0;
    for (final student in unassigned) {
      if (updatedFamilies.isEmpty) break;
      final targetFamily = updatedFamilies[familyIndex % updatedFamilies.length];
      targetFamily.memberIds.add(student.id);
      familyIndex++;
    }

    _families = updatedFamilies;
    _isMatchingRunning = false;
    notifyListeners();
  }

  void swapStudentsBetweenFamilies({
    required String studentAId,
    required String familyAId,
    required String studentBId,
    required String familyBId,
  }) {
    final famAIndex = _families.indexWhere((f) => f.id == familyAId);
    final famBIndex = _families.indexWhere((f) => f.id == familyBId);

    if (famAIndex != -1 && famBIndex != -1) {
      final famA = _families[famAIndex];
      final famB = _families[famBIndex];

      final membersA = List<String>.from(famA.memberIds);
      final membersB = List<String>.from(famB.memberIds);

      membersA.remove(studentAId);
      membersA.add(studentBId);

      membersB.remove(studentBId);
      membersB.add(studentAId);

      _families[famAIndex] = famA.copyWith(memberIds: membersA);
      _families[famBIndex] = famB.copyWith(memberIds: membersB);

      // Update student assigned family id
      _updateStudentFamilyId(studentAId, familyBId);
      _updateStudentFamilyId(studentBId, familyAId);

      notifyListeners();
    }
  }

  void _updateStudentFamilyId(String studentId, String newFamilyId) {
    final index = _allStudents.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      _allStudents[index] = _allStudents[index].copyWith(assignedFamilyId: newFamilyId);
      if (_currentUser.id == studentId) {
        _currentUser = _currentUser.copyWith(assignedFamilyId: newFamilyId);
      }
    }
  }

  void publishAndBroadcastFamilies() {
    _isFamilyPublished = true;
    _families = _families.map((f) => f.copyWith(isPublished: true)).toList();
    _broadcastEmergency(
      title: 'Family Roster Released!',
      description: 'Your spiritual family assignment and Spiritual Parents contact cards are now live. Connect with your family group chat!',
      category: 'Fellowship Family',
    );
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 3: ATTENDANCE & ANALYTICS PIPELINE
  // ----------------------------------------------------
  late AttendanceSessionModel _activeSession;
  Timer? _pinTimer;
  int _pinCountdownSeconds = 30;

  AttendanceSessionModel get activeSession => _activeSession;
  int get pinCountdownSeconds => _pinCountdownSeconds;

  // Analytics Metrics
  int get totalRegisteredStudents => _allStudents.length + 300;
  double get averageAttendanceRate => 78.4;
  int get activeRoadmapsCount => _roadmaps.length + 20;
  int get atRiskStudentsCount => _allStudents.where((s) => s.attendancePercentage < 75.0).length + 15;

  List<UserModel> get atRiskStudents => _allStudents.where((s) => s.attendancePercentage < 75.0).toList();

  void _startPinRotation() {
    _pinTimer?.cancel();
    _pinCountdownSeconds = 30;
    _pinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_pinCountdownSeconds > 1) {
        _pinCountdownSeconds--;
        notifyListeners();
      } else {
        _pinCountdownSeconds = 30;
        _rotateSessionCode();
      }
    });
  }

  void _rotateSessionCode() {
    final randomPins = ['8421', '9103', '5284', '3749', '6192', '4580', '7315'];
    final nextPin = randomPins[(DateTime.now().second ~/ 4) % randomPins.length];
    _activeSession = _activeSession.copyWith(
      rollingPin: nextPin,
      code: 'CS301-2026-$nextPin',
      generatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  bool checkInStudent({
    required String studentId,
    required String enteredPinOrCode,
    AttendanceCheckInMethod method = AttendanceCheckInMethod.pin,
  }) {
    final cleanInput = enteredPinOrCode.trim().toUpperCase();
    final isValidPin = cleanInput == _activeSession.rollingPin;
    final isValidCode = cleanInput == _activeSession.code || cleanInput.contains(_activeSession.rollingPin);

    if (isValidPin || isValidCode) {
      final student = _allStudents.firstWhere(
        (s) => s.id == studentId,
        orElse: () => _currentUser,
      );

      // Check if already checked in
      final alreadyIn = _activeSession.scans.any((s) => s.studentId == student.id);
      if (!alreadyIn) {
        final newRecord = AttendanceRecordModel(
          id: 'att-${DateTime.now().millisecondsSinceEpoch}',
          studentId: student.id,
          studentName: student.fullName,
          timestamp: DateTime.now(),
          status: DateTime.now().minute % 10 > 7 ? AttendanceStatus.late : AttendanceStatus.present,
          method: method,
          courseName: _activeSession.courseName,
        );

        final updatedScans = List<AttendanceRecordModel>.from(_activeSession.scans)..insert(0, newRecord);
        _activeSession = _activeSession.copyWith(scans: updatedScans);
        notifyListeners();
        return true;
      }
      return true;
    }
    return false;
  }

  // ----------------------------------------------------
  // DOMAIN 4: COURSE ROADMAPS & PHASES
  // ----------------------------------------------------
  List<RoadmapPhaseModel> _roadmaps = [];
  List<RoadmapPhaseModel> get roadmaps => List.unmodifiable(_roadmaps);

  void toggleLessonDownload(String phaseId, String lessonId) {
    final pIndex = _roadmaps.indexWhere((p) => p.id == phaseId);
    if (pIndex != -1) {
      final phase = _roadmaps[pIndex];
      final lIndex = phase.weeklyLessons.indexWhere((l) => l.id == lessonId);
      if (lIndex != -1) {
        final lesson = phase.weeklyLessons[lIndex];
        final updatedLessons = List<LessonModel>.from(phase.weeklyLessons);
        updatedLessons[lIndex] = lesson.copyWith(isDownloaded: !lesson.isDownloaded);
        _roadmaps[pIndex] = phase.copyWith(weeklyLessons: updatedLessons);
        notifyListeners();
      }
    }
  }

  void addRoadmapPhase(RoadmapPhaseModel newPhase) {
    _roadmaps.add(newPhase);
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 5: DIGITAL LIBRARY (WITH TELEGRAM LINKS)
  // ----------------------------------------------------
  List<LibraryItemModel> _libraryItems = [];
  String _librarySearchQuery = '';
  LibraryCategory? _selectedCategory;
  String? _selectedLanguageTag;
  LibraryItemModel? _activeAudioMezmur;
  bool _isAudioPlaying = false;
  double _audioProgress = 0.35;

  List<LibraryItemModel> get libraryItems => List.unmodifiable(_libraryItems);
  String get librarySearchQuery => _librarySearchQuery;
  LibraryCategory? get selectedCategory => _selectedCategory;
  String? get selectedLanguageTag => _selectedLanguageTag;
  LibraryItemModel? get activeAudioMezmur => _activeAudioMezmur;
  bool get isAudioPlaying => _isAudioPlaying;
  double get audioProgress => _audioProgress;

  List<LibraryItemModel> get filteredLibraryItems {
    return _libraryItems.where((item) {
      if (_selectedCategory != null && item.category != _selectedCategory) {
        return false;
      }
      if (_selectedLanguageTag != null && !item.tags.contains(_selectedLanguageTag)) {
        return false;
      }
      if (_librarySearchQuery.isNotEmpty) {
        final q = _librarySearchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(q);
        final matchSub = item.subtitle.toLowerCase().contains(q);
        final matchTags = item.tags.any((t) => t.toLowerCase().contains(q));
        if (!matchTitle && !matchSub && !matchTags) return false;
      }
      return true;
    }).toList();
  }

  void setLibrarySearch(String query) {
    _librarySearchQuery = query;
    notifyListeners();
  }

  void setLibraryCategory(LibraryCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setLanguageTag(String? tag) {
    _selectedLanguageTag = tag;
    notifyListeners();
  }

  void addLibraryBookLink({
    required String title,
    required String subtitle,
    required String description,
    required LibraryCategory category,
    required List<String> tags,
    required String telegramUrl,
    String? sourceUrl,
    bool isRestricted = false,
  }) {
    final newItem = LibraryItemModel(
      id: 'lib-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      tags: tags,
      telegramUrl: telegramUrl,
      sourceUrl: sourceUrl,
      isRestricted: isRestricted,
    );
    _libraryItems.insert(0, newItem);
    notifyListeners();
  }

  void playMezmur(LibraryItemModel item) {
    _activeAudioMezmur = item;
    _isAudioPlaying = true;
    notifyListeners();
  }

  void toggleAudioPlayback() {
    _isAudioPlaying = !_isAudioPlaying;
    notifyListeners();
  }

  void setAudioProgress(double progress) {
    _audioProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 6: REAL-TIME CHURCH PROGRAMS & LITURGY
  // ----------------------------------------------------
  List<ChurchProgramModel> _programs = [];
  Timer? _countdownTimer;
  Duration _liturgyCountdown = const Duration(hours: 2, minutes: 15, seconds: 45);
  ChurchProgramModel? _latestEmergencyBroadcast;

  List<ChurchProgramModel> get programs => List.unmodifiable(_programs);
  Duration get liturgyCountdown => _liturgyCountdown;
  ChurchProgramModel? get latestEmergencyBroadcast => _latestEmergencyBroadcast;

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_liturgyCountdown.inSeconds > 0) {
        _liturgyCountdown = _liturgyCountdown - const Duration(seconds: 1);
        notifyListeners();
      }
    });
  }

  void _broadcastEmergency({
    required String title,
    required String description,
    String category = 'Emergency Alert',
  }) {
    final broadcast = ChurchProgramModel(
      id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      churchName: "St. Mary's Orthodox Church",
      dateTime: DateTime.now(),
      initialDurationRemaining: Duration.zero,
      isEmergency: true,
      description: description,
      category: category,
    );
    _latestEmergencyBroadcast = broadcast;
    _programs.insert(0, broadcast);
    notifyListeners();
  }

  void dismissEmergencyBanner() {
    _latestEmergencyBroadcast = null;
    notifyListeners();
  }

  void postEmergencyScheduleBroadcast({
    required String title,
    required String description,
    required String churchName,
  }) {
    _broadcastEmergency(title: title, description: description, category: 'Schedule Change');
  }

  // ----------------------------------------------------
  // DOMAIN 7: 10 EOTC FELLOWSHIP DEPARTMENTS & COORDINATOR DELEGATION
  // ----------------------------------------------------
  List<MinistryModel> _ministries = [];
  List<VolunteerApplicationModel> _volunteerApplications = [];
  List<DepartmentMemberModel> _departmentMembers = [];
  String? _selectedCoordinatorDepartmentId;

  List<MinistryModel> get ministries => List.unmodifiable(_ministries);
  List<VolunteerApplicationModel> get volunteerApplications => List.unmodifiable(_volunteerApplications);
  List<DepartmentMemberModel> get departmentMembers => List.unmodifiable(_departmentMembers);
  String? get selectedCoordinatorDepartmentId => _selectedCoordinatorDepartmentId;

  void setSelectedCoordinatorDepartment(String? deptId) {
    _selectedCoordinatorDepartmentId = deptId;
    notifyListeners();
  }

  List<VolunteerApplicationModel> getApplicationsForDepartment(String? deptId) {
    if (deptId == null || deptId.isEmpty) {
      return List.unmodifiable(_volunteerApplications);
    }
    return _volunteerApplications.where((a) => a.ministryId == deptId).toList();
  }

  List<DepartmentMemberModel> getMembersForDepartment(String? deptId) {
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
  }

  void approveVolunteerApplication(
    String applicationId, {
    String? notes,
    String? reviewedBy,
  }) {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      final oldApp = _volunteerApplications[index];
      final app = oldApp.copyWith(
        status: ApplicationStatus.approved,
        reviewedAt: DateTime.now(),
        reviewedByCoordinator: reviewedBy ?? 'Department Coordinator',
        coordinatorNotes: notes ?? 'Welcome to the department! Orientation details shared.',
      );
      _volunteerApplications[index] = app;

      // Add to department members roster
      final existingMemberIndex = _departmentMembers.indexWhere(
        (m) => m.studentId == app.studentId && m.departmentId == app.ministryId,
      );
      if (existingMemberIndex == -1) {
        _departmentMembers.insert(
          0,
          DepartmentMemberModel(
            id: 'mem-${DateTime.now().millisecondsSinceEpoch}',
            departmentId: app.ministryId,
            studentId: app.studentId,
            studentName: app.studentName,
            studentBaptismalName: app.studentBaptismalName,
            studentDept: app.studentDept,
            studentYear: app.studentYear,
            phoneNumber: app.studentPhone,
            subWing: app.preferredSubWing,
            roleInDepartment: 'Active Servant',
            joinedDate: DateTime.now(),
          ),
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
    }
  }

  void rejectVolunteerApplication(
    String applicationId, {
    String? notes,
    String? reviewedBy,
  }) {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      _volunteerApplications[index] = _volunteerApplications[index].copyWith(
        status: ApplicationStatus.rejected,
        reviewedAt: DateTime.now(),
        reviewedByCoordinator: reviewedBy ?? 'Department Coordinator',
        coordinatorNotes: notes ?? 'Thank you for your interest. We encourage exploring alternative serving areas.',
      );
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // DOMAIN 8: ETHIOPIAN LITURGICAL CALENDAR & FASTING
  // ----------------------------------------------------
  late EthiopianCalendarDay _currentCalendarDay;
  List<EthiopianCalendarDay> _calendarWeek = [];

  EthiopianCalendarDay get currentCalendarDay => _currentCalendarDay;
  List<EthiopianCalendarDay> get calendarWeek => List.unmodifiable(_calendarWeek);

  void selectCalendarDay(EthiopianCalendarDay day) {
    _currentCalendarDay = day;
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 9: DAILY PRAYER BOOK (WUDASE MARYAM & YEZEWETIR)
  // ----------------------------------------------------
  late PrayerBookModel _wudaseMaryam;
  late PrayerBookModel _yezewetirTselot;
  int _selectedPrayerDayIndex = (DateTime.now().weekday - 1).clamp(0, 6); // 0 = Mon, 1 = Tue, ..., 6 = Sun
  double _prayerFontSize = 16.0;

  PrayerBookModel get wudaseMaryam => _wudaseMaryam;
  PrayerBookModel get yezewetirTselot => _yezewetirTselot;
  int get selectedPrayerDayIndex => _selectedPrayerDayIndex;
  double get prayerFontSize => _prayerFontSize;

  void setPrayerDay(int dayIndex) {
    _selectedPrayerDayIndex = dayIndex.clamp(0, 6);
    notifyListeners();
  }

  void setPrayerFontSize(double size) {
    _prayerFontSize = size.clamp(12.0, 26.0);
    notifyListeners();
  }

  // ----------------------------------------------------
  // DOMAIN 10: FATHER CONFESSOR & SPIRITUAL COUNSELING
  // ----------------------------------------------------
  List<ConfessorFatherModel> _confessorFathers = [];
  List<ConfessionAppointmentModel> _confessionAppointments = [];
  List<AnonymousSpiritualQuestionModel> _spiritualQuestions = [];
  List<CommunionChecklistItem> _communionChecklist = [];

  List<ConfessorFatherModel> get confessorFathers => List.unmodifiable(_confessorFathers);
  List<ConfessionAppointmentModel> get confessionAppointments => List.unmodifiable(_confessionAppointments);
  List<AnonymousSpiritualQuestionModel> get spiritualQuestions => List.unmodifiable(_spiritualQuestions);
  List<CommunionChecklistItem> get communionChecklist => _communionChecklist;

  List<ConfessionAppointmentModel> get myConfessionAppointments =>
      _confessionAppointments.where((a) => a.studentId == _currentUser.id).toList();

  void bookConfessionAppointment({
    required String fatherId,
    required DateTime scheduledDate,
    required String timeSlot,
    required String topic,
    String? notes,
  }) {
    final father = _confessorFathers.firstWhere((f) => f.id == fatherId);
    final newAppt = ConfessionAppointmentModel(
      id: 'conf-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentPhone: _currentUser.phoneNumber,
      fatherId: father.id,
      fatherName: '${father.clericalTitle} ${father.fullName}',
      scheduledDate: scheduledDate,
      timeSlot: timeSlot,
      topic: topic,
      status: ConfessionAppointmentStatus.pending,
      notes: notes,
    );

    _confessionAppointments.insert(0, newAppt);
    notifyListeners();
  }

  void updateConfessionStatus(String apptId, ConfessionAppointmentStatus status) {
    final index = _confessionAppointments.indexWhere((a) => a.id == apptId);
    if (index != -1) {
      _confessionAppointments[index] = _confessionAppointments[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void cancelConfessionAppointment(String apptId) {
    updateConfessionStatus(apptId, ConfessionAppointmentStatus.cancelled);
  }

  void submitAnonymousQuestion({
    required String questionText,
    required String category,
  }) {
    final newQ = AnonymousSpiritualQuestionModel(
      id: 'q-${DateTime.now().millisecondsSinceEpoch}',
      questionText: questionText,
      category: category,
      askedAt: DateTime.now(),
      isAnswered: false,
    );
    _spiritualQuestions.insert(0, newQ);
    notifyListeners();
  }

  void answerSpiritualQuestion({
    required String questionId,
    required String answerText,
    required String answeredBy,
  }) {
    final index = _spiritualQuestions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      _spiritualQuestions[index] = _spiritualQuestions[index].copyWith(
        isAnswered: true,
        answerText: answerText,
        answeredBy: answeredBy,
      );
      notifyListeners();
    }
  }

  void toggleCommunionItem(String itemId) {
    final index = _communionChecklist.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _communionChecklist[index].isChecked = !_communionChecklist[index].isChecked;
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // DOMAIN 11: PILGRIMAGE & MONASTERY TRIP COORDINATOR
  // ----------------------------------------------------
  List<PilgrimageTripModel> _pilgrimageTrips = [];
  List<TripRegistrationModel> _tripRegistrations = [];

  List<PilgrimageTripModel> get pilgrimageTrips => List.unmodifiable(_pilgrimageTrips);
  List<TripRegistrationModel> get allTripRegistrations => List.unmodifiable(_tripRegistrations);

  List<TripRegistrationModel> get myTripRegistrations =>
      _tripRegistrations.where((r) => r.studentId == _currentUser.id).toList();

  void registerForTrip({
    required String tripId,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
  }) {
    final trip = _pilgrimageTrips.firstWhere((t) => t.id == tripId);
    final reg = TripRegistrationModel(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      tripId: trip.id,
      tripTitle: trip.title,
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentPhone: _currentUser.phoneNumber,
      department: _currentUser.department,
      academicYear: _currentUser.academicYear,
      busNumber: (trip.bookedSeats ~/ 45) + 1,
      seatNumber: (trip.bookedSeats % 45) + 1,
      feeAmount: trip.feeAmount,
      isFree: trip.isFree,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      paymentStatus: trip.isFree ? TripPaymentStatus.free : TripPaymentStatus.pendingVerification,
      qrTicketCode: 'PILGRIM-${trip.id.substring(0, 4).toUpperCase()}-${_currentUser.id.substring(0, 5).toUpperCase()}',
      registeredAt: DateTime.now(),
    );

    _tripRegistrations.insert(0, reg);

    // Update booked seats
    final tripIdx = _pilgrimageTrips.indexWhere((t) => t.id == tripId);
    if (tripIdx != -1) {
      _pilgrimageTrips[tripIdx] = _pilgrimageTrips[tripIdx].copyWith(
        bookedSeats: _pilgrimageTrips[tripIdx].bookedSeats + 1,
      );
    }
    notifyListeners();
  }

  void verifyTripPayment(String regId, bool approve) {
    final index = _tripRegistrations.indexWhere((r) => r.id == regId);
    if (index != -1) {
      _tripRegistrations[index] = _tripRegistrations[index].copyWith(
        paymentStatus: approve ? TripPaymentStatus.verified : TripPaymentStatus.rejected,
      );
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // DOMAIN 12: STUDENT MUTUAL AID & CHARITY FUND
  // ----------------------------------------------------
  List<CharityCampaignModel> _charityCampaigns = [];
  List<DuesPaymentModel> _duesPayments = [];
  List<EmergencyAidRequestModel> _emergencyAidRequests = [];

  List<CharityCampaignModel> get charityCampaigns => List.unmodifiable(_charityCampaigns);
  List<DuesPaymentModel> get duesPayments => List.unmodifiable(_duesPayments);
  List<EmergencyAidRequestModel> get emergencyAidRequests => List.unmodifiable(_emergencyAidRequests);

  List<EmergencyAidRequestModel> get myEmergencyAidRequests =>
      _emergencyAidRequests.where((r) => r.studentId == _currentUser.id).toList();

  void submitDuesPayment({
    required double amount,
    required String purpose,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
  }) {
    final payment = DuesPaymentModel(
      id: 'due-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      amount: amount,
      purpose: purpose,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: 'Pending Verification',
      submittedAt: DateTime.now(),
    );
    _duesPayments.insert(0, payment);
    notifyListeners();
  }

  void donateToCharityCampaign(String campaignId, double amount) {
    final index = _charityCampaigns.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      final camp = _charityCampaigns[index];
      _charityCampaigns[index] = CharityCampaignModel(
        id: camp.id,
        title: camp.title,
        description: camp.description,
        targetAmount: camp.targetAmount,
        raisedAmount: camp.raisedAmount + amount,
        donorsCount: camp.donorsCount + 1,
        deadline: camp.deadline,
        isEmergency: camp.isEmergency,
        category: camp.category,
      );
      notifyListeners();
    }
  }

  void submitEmergencyAidRequest({
    required EmergencyAidCategory category,
    required String description,
    required double amountRequested,
  }) {
    final req = EmergencyAidRequestModel(
      id: 'aid-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentPhone: _currentUser.phoneNumber,
      department: _currentUser.department,
      academicYear: _currentUser.academicYear,
      category: category,
      description: description,
      amountRequested: amountRequested,
      status: EmergencyAidStatus.underReview,
      submittedAt: DateTime.now(),
    );
    _emergencyAidRequests.insert(0, req);
    notifyListeners();
  }

  void updateAidRequestStatus(String reqId, EmergencyAidStatus status, {String? adminNote}) {
    final index = _emergencyAidRequests.indexWhere((r) => r.id == reqId);
    if (index != -1) {
      _emergencyAidRequests[index] = _emergencyAidRequests[index].copyWith(
        status: status,
        adminNote: adminNote,
      );
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // DOMAIN 13: DEPARTMENT MENTORSHIP MATCHING
  // ----------------------------------------------------
  List<AcademicMentorModel> _academicMentors = [];
  List<MentorshipRequestModel> _mentorshipRequests = [];

  List<AcademicMentorModel> get academicMentors => List.unmodifiable(_academicMentors);
  List<MentorshipRequestModel> get mentorshipRequests => List.unmodifiable(_mentorshipRequests);

  List<MentorshipRequestModel> get myMentorshipRequests =>
      _mentorshipRequests.where((r) => r.juniorStudentId == _currentUser.id).toList();

  void requestMentorship({
    required String mentorId,
    required String coursesNeeded,
  }) {
    final mentor = _academicMentors.firstWhere((m) => m.id == mentorId);
    final req = MentorshipRequestModel(
      id: 'mnt-${DateTime.now().millisecondsSinceEpoch}',
      juniorStudentId: _currentUser.id,
      juniorName: _currentUser.fullName,
      juniorBaptismalName: _currentUser.baptismalName,
      department: _currentUser.department,
      academicYear: _currentUser.academicYear,
      mentorId: mentor.id,
      mentorName: mentor.fullName,
      coursesNeeded: coursesNeeded,
      status: MentorshipStatus.pending,
      requestedAt: DateTime.now(),
    );
    _mentorshipRequests.insert(0, req);
    notifyListeners();
  }

  void updateMentorshipStatus(String reqId, MentorshipStatus status) {
    final index = _mentorshipRequests.indexWhere((r) => r.id == reqId);
    if (index != -1) {
      _mentorshipRequests[index] = _mentorshipRequests[index].copyWith(status: status);
      notifyListeners();
    }
  }

  // ----------------------------------------------------
  // DOMAIN 14: THEOLOGICAL FAITH CHALLENGE TRIVIA
  // ----------------------------------------------------
  List<TriviaQuizModel> _triviaQuizzes = [];
  List<QuizAttemptModel> _quizAttempts = [];
  List<FamilyLeaderboardEntry> _familyLeaderboard = [];

  List<TriviaQuizModel> get triviaQuizzes => List.unmodifiable(_triviaQuizzes);
  List<QuizAttemptModel> get quizAttempts => List.unmodifiable(_quizAttempts);
  List<FamilyLeaderboardEntry> get familyLeaderboard => List.unmodifiable(_familyLeaderboard);

  QuizAttemptModel? get myLatestQuizAttempt {
    if (_quizAttempts.isEmpty) return null;
    try {
      return _quizAttempts.firstWhere((a) => a.studentId == _currentUser.id);
    } catch (_) {
      return null;
    }
  }

  void submitQuizAttempt({
    required String quizId,
    required int score,
    required int totalQuestions,
  }) {
    final currentFam = currentStudentFamily;
    final attempt = QuizAttemptModel(
      id: 'att-quiz-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      familyId: currentFam?.id ?? 'fam-st-george',
      familyName: currentFam?.name ?? 'Family of St. George',
      quizId: quizId,
      score: score,
      totalQuestions: totalQuestions,
      completedAt: DateTime.now(),
    );
    _quizAttempts.insert(0, attempt);

    // Update family leaderboard
    final famIdx = _familyLeaderboard.indexWhere((f) => f.familyId == attempt.familyId);
    if (famIdx != -1) {
      final cur = _familyLeaderboard[famIdx];
      _familyLeaderboard[famIdx] = FamilyLeaderboardEntry(
        familyId: cur.familyId,
        familyName: cur.familyName,
        totalScore: cur.totalScore + (score * 20),
        participantsCount: cur.participantsCount + 1,
        rank: cur.rank,
      );
    }
    notifyListeners();
  }

  // ----------------------------------------------------
  // URL LAUNCHER SHORTCUTS (TELEGRAM, CALL, SMS)
  // ----------------------------------------------------
  Future<void> launchCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> launchSms(String phoneNumber, {String? body}) async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: body != null ? {'body': body} : null,
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> launchTelegram(String telegramUrl) async {
    final Uri uri = Uri.parse(telegramUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ----------------------------------------------------
  // INITIALIZATION & MOCK DATA SETUP
  // ----------------------------------------------------
  FellowshipState() {
    _initMockData();
    _startPinRotation();
    _startCountdownTicker();
  }

  void _initMockData() {
    // 1. Initial Students
    _allStudents = [
      _currentUser,
      UserModel(
        id: 'usr-1',
        fullName: 'Dawit Alemu',
        baptismalName: 'Gebre Michael',
        phoneNumber: '+251911223344',
        batchYear: '2025',
        department: 'Engineering',
        academicYear: 2,
        attendancePercentage: 92.0,
        ministryStatus: 'Diaconia Volunteer',
        assignedFamilyId: 'fam-st-george',
      ),
      UserModel(
        id: 'usr-2',
        fullName: 'Hewan Bekele',
        baptismalName: 'Walata Petros',
        phoneNumber: '+251922334455',
        batchYear: '2024',
        department: 'Law',
        academicYear: 3,
        attendancePercentage: 86.0,
        ministryStatus: 'Hospitality Team',
        assignedFamilyId: 'fam-st-george',
      ),
      UserModel(
        id: 'usr-3',
        fullName: 'Sarah Jenkins',
        baptismalName: 'Walata Maryam',
        phoneNumber: '+251933445566',
        batchYear: '2025',
        department: 'Medicine & Health',
        academicYear: 2,
        attendancePercentage: 68.0, // At-risk
        ministryStatus: 'General Fellow',
        assignedFamilyId: 'fam-st-george',
      ),
      UserModel(
        id: 'usr-4',
        fullName: 'Alex Smith',
        baptismalName: 'Gebre Sellassie',
        phoneNumber: '+251944556677',
        batchYear: '2023',
        department: 'Computer Science',
        academicYear: 4,
        attendancePercentage: 95.0,
        ministryStatus: 'Media & Sound',
        assignedFamilyId: 'fam-st-george',
      ),
      UserModel(
        id: 'usr-5',
        fullName: 'Michael Kim',
        baptismalName: 'Gebre Eyesus',
        phoneNumber: '+251955667788',
        batchYear: '2025',
        department: 'Business & Economics',
        academicYear: 2,
        attendancePercentage: 71.0, // At-risk
        ministryStatus: 'General Fellow',
        assignedFamilyId: 'fam-st-tekle',
      ),
      UserModel(
        id: 'usr-6',
        fullName: 'Jane Doe',
        baptismalName: 'Kidan Maryam',
        phoneNumber: '+251966778899',
        batchYear: '2024',
        department: 'Engineering',
        academicYear: 3,
        attendancePercentage: 89.0,
        ministryStatus: 'Yaredic Choir',
        assignedFamilyId: 'fam-st-tekle',
      ),
      UserModel(
        id: 'usr-7',
        fullName: 'David Brown',
        baptismalName: 'Gebre Giorgis',
        phoneNumber: '+251977889900',
        batchYear: '2026',
        department: 'Natural Sciences',
        academicYear: 1,
        attendancePercentage: 64.0, // At-risk
        ministryStatus: 'General Fellow',
        assignedFamilyId: 'fam-st-tekle',
      ),
    ];

    // Pending Approvals Queue
    _pendingApprovals = [
      UserModel(
        id: 'usr-p1',
        fullName: 'Yared Tesfaye',
        baptismalName: 'Habte Mariam',
        phoneNumber: '+251911882233',
        batchYear: '2026',
        department: 'Civil Engineering',
        academicYear: 1,
        isApproved: false,
      ),
      UserModel(
        id: 'usr-p2',
        fullName: 'Selamawit Tilahun',
        baptismalName: 'Wolete Kidan',
        phoneNumber: '+251922993344',
        batchYear: '2026',
        department: 'Pharmacy',
        academicYear: 1,
        isApproved: false,
      ),
      UserModel(
        id: 'usr-p3',
        fullName: 'Kidus Yohannes',
        baptismalName: 'Yohannes',
        phoneNumber: '+251933004455',
        batchYear: '2025',
        department: 'Information Tech',
        academicYear: 2,
        isApproved: false,
      ),
    ];

    // 2. Orthodox Families
    _families = [
      FamilyModel(
        id: 'fam-st-george',
        name: 'Family of St. George',
        formedDate: 'Formed Sept 2023',
        spiritualFather: SpiritualParentModel(
          id: 'sp-1',
          fullName: 'Ephrem Tadesse',
          baptismalName: 'Gebre Kristos',
          department: 'Theology Department',
          faculty: 'Faculty of Theology & Tradition',
          phoneNumber: '+251911554433',
          roleTitle: 'Spiritual Father',
        ),
        spiritualMother: SpiritualParentModel(
          id: 'sp-2',
          fullName: 'Lidia Solomon',
          baptismalName: 'Wolete Mariam',
          department: 'Medical Faculty',
          faculty: 'College of Health Sciences',
          phoneNumber: '+251922665544',
          roleTitle: 'Spiritual Mother',
        ),
        maxCapacity: 10,
        telegramGroupUrl: 'https://t.me/WCU_StGeorge_Family',
        whatsappGroupUrl: 'https://chat.whatsapp.com/sample_st_george',
        isPublished: true,
        memberIds: ['usr-current', 'usr-1', 'usr-2', 'usr-3', 'usr-4'],
      ),
      FamilyModel(
        id: 'fam-st-tekle',
        name: 'Family of St. Teklehaimanot',
        formedDate: 'Formed Oct 2023',
        spiritualFather: SpiritualParentModel(
          id: 'sp-3',
          fullName: 'Johnathan Samuel',
          baptismalName: 'Tekle Tsion',
          department: 'Computer Science',
          faculty: 'Faculty of Informatics',
          phoneNumber: '+251933776655',
          roleTitle: 'Spiritual Father',
        ),
        spiritualMother: SpiritualParentModel(
          id: 'sp-4',
          fullName: 'Sara Berhanu',
          baptismalName: 'Kristos Samra',
          department: 'Economics',
          faculty: 'Business & Economics',
          phoneNumber: '+251944887766',
          roleTitle: 'Spiritual Mother',
        ),
        maxCapacity: 10,
        telegramGroupUrl: 'https://t.me/WCU_StTekle_Family',
        whatsappGroupUrl: 'https://chat.whatsapp.com/sample_st_tekle',
        isPublished: true,
        memberIds: ['usr-5', 'usr-6', 'usr-7'],
      ),
    ];

    // 3. Live Attendance Session
    _activeSession = AttendanceSessionModel(
      sessionId: 'sess-cs301',
      courseName: 'Patristics & Church History',
      courseCode: 'CS301 - Data Structures & Patristics',
      faculty: 'College of Natural Sciences & Theology',
      code: 'CS301-2026-8421',
      rollingPin: '8421',
      generatedAt: DateTime.now(),
      refreshIntervalSeconds: 30,
      totalEnrolled: 50,
      scans: [
        AttendanceRecordModel(
          id: 'rec-1',
          studentId: 'usr-6',
          studentName: 'Jane Doe',
          timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Patristics & Church History',
        ),
        AttendanceRecordModel(
          id: 'rec-2',
          studentId: 'usr-4',
          studentName: 'Alex Smith',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.pin,
          courseName: 'Patristics & Church History',
        ),
        AttendanceRecordModel(
          id: 'rec-3',
          studentId: 'usr-5',
          studentName: 'Michael Kim',
          timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Patristics & Church History',
        ),
        AttendanceRecordModel(
          id: 'rec-4',
          studentId: 'usr-3',
          studentName: 'Sarah Jenkins',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          status: AttendanceStatus.late,
          method: AttendanceCheckInMethod.pin,
          courseName: 'Patristics & Church History',
        ),
        AttendanceRecordModel(
          id: 'rec-5',
          studentId: 'usr-1',
          studentName: 'Dawit Alemu',
          timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Patristics & Church History',
        ),
        AttendanceRecordModel(
          id: 'rec-6',
          studentId: 'usr-2',
          studentName: 'Hewan Bekele',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          status: AttendanceStatus.present,
          method: AttendanceCheckInMethod.qr,
          courseName: 'Patristics & Church History',
        ),
        AttendanceRecordModel(
          id: 'rec-7',
          studentId: 'usr-7',
          studentName: 'David Brown',
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          status: AttendanceStatus.late,
          method: AttendanceCheckInMethod.pin,
          courseName: 'Patristics & Church History',
        ),
      ],
    );

    // 4. Course Roadmaps
    _roadmaps = [
      RoadmapPhaseModel(
        id: 'phase-1',
        title: 'Foundations of Faith',
        description: 'An introduction to Orthodox theology, the Nicene Creed, and the structural beauty of the Divine Liturgy.',
        status: RoadmapStatus.completed,
        progress: 1.0,
        instructor: 'Dn. Ephrem Tadesse',
        batchYear: '2024',
        semester: 'Semester 1',
        weeklyLessons: [
          LessonModel(
            id: 'l1',
            title: 'Week 1: The Nicene-Constantinopolitan Creed',
            summary: 'Comprehensive line-by-line exposition of the 12 articles of Christian Orthodox belief.',
            readingList: ['Creed Commentary - St. Athanasius', 'Faith of the 318 Fathers'],
            isDownloaded: true,
          ),
          LessonModel(
            id: 'l2',
            title: 'Week 2: Order of the Divine Liturgy',
            summary: 'Understanding the Preparatory rites, Anaphora of the Apostles, and Eucharistic communion.',
            readingList: ['Serate Kidase Manual', 'Liturgical Theology Notes'],
            isDownloaded: true,
          ),
        ],
      ),
      RoadmapPhaseModel(
        id: 'phase-2',
        title: 'Patristics',
        description: 'Deep dive into the writings of the Early Church Fathers, desert spirituality, and ascetic practice.',
        status: RoadmapStatus.inProgress,
        progress: 0.45,
        instructor: 'Memhir Yohannes Kidan',
        batchYear: '2024',
        semester: 'Semester 2',
        prerequisites: ['Foundations of Faith'],
        weeklyLessons: [
          LessonModel(
            id: 'l3',
            title: 'Week 1: St. Athanasius on the Incarnation',
            summary: 'Exegesis of De Incarnatione Verbi Dei and victory over death.',
            readingList: ['On the Incarnation Chapters 1-4', 'St. Cyril Letters to Nestorius'],
            isDownloaded: false,
          ),
          LessonModel(
            id: 'l4',
            title: 'Week 2: The Desert Fathers & Asceticism',
            summary: 'Sayings of Abba Anthony, Macarius, and monastic spirituality in Christian fellowship.',
            readingList: ['Apophthegmata Patrum', 'Spiritual Ladder of St. John Climacus'],
            isDownloaded: false,
          ),
          LessonModel(
            id: 'l5',
            title: 'Week 3: Haymanote Abew (Faith of the Fathers)',
            summary: 'Compilation of patristic homilies and Christology preserved in Ge\'ez tradition.',
            readingList: ['Haymanote Abew Homily 12-18'],
            isDownloaded: false,
          ),
        ],
      ),
      RoadmapPhaseModel(
        id: 'phase-3',
        title: 'Church Tradition & Canon Law',
        description: 'Understanding iconology, hymnography (St. Yared), fasts, and the living tradition passed down through generations.',
        status: RoadmapStatus.locked,
        progress: 0.0,
        instructor: 'Dr. Lidia Solomon',
        batchYear: '2025',
        semester: 'Semester 1',
        prerequisites: ['Patristics'],
        weeklyLessons: [
          LessonModel(
            id: 'l6',
            title: 'Week 1: St. Yaredic Musical Notation & Deggua',
            summary: 'Introduction to Geez, Ezel, and Araray modes and Ethiopian hymnology.',
            readingList: ['Tsome Deggua Guide', 'Life of St. Yared'],
            isDownloaded: false,
          ),
        ],
      ),
      RoadmapPhaseModel(
        id: 'phase-4',
        title: 'Orthodox Dogmatics & Apologetics',
        description: 'Systematic theology, Holy Sacraments (Misteerat), and answering contemporary philosophical queries.',
        status: RoadmapStatus.locked,
        progress: 0.0,
        instructor: 'Archpriest Gebre Meskel',
        batchYear: '2025',
        semester: 'Semester 2',
        prerequisites: ['Church Tradition & Canon Law'],
        weeklyLessons: [],
      ),
    ];

    // 5. Digital Library (With Direct Telegram Links!)
    _libraryItems = [
      LibraryItemModel(
        id: 'lib-1',
        title: 'The Faith of the Fathers',
        subtitle: 'Haymanote Abew (ሃይማኖተ አበው)',
        description: 'A foundational compilation of theological treatises and homilies from the early Church Fathers, carefully preserved in Ge\'ez and translated for modern university study.',
        category: LibraryCategory.patristics,
        tags: ['Patristics', 'Ge\'ez / Amharic', 'Theology'],
        telegramUrl: 'https://t.me/WCU_Orthodox_Library/101',
        sourceUrl: 'https://t.me/WCU_Orthodox_Library',
        readTime: '45 mins reading',
        coverAssetPath: 'asset/screen5 - Copy.png',
      ),
      LibraryItemModel(
        id: 'lib-2',
        title: 'Wudase Mariam',
        subtitle: 'Daily Praises of St. Mary (ውዳሴ ማርያም)',
        description: 'Traditional 7-day liturgical praises composed by St. Ephrem the Syrian with commentary by Abba Giyorgis of Gasicha.',
        category: LibraryCategory.liturgical,
        tags: ['Amharic', 'Liturgical', 'Daily Prayer'],
        telegramUrl: 'https://t.me/WCU_Orthodox_Library/102',
        sourceUrl: 'https://t.me/WCU_Orthodox_Library',
        readTime: '20 mins daily',
      ),
      LibraryItemModel(
        id: 'lib-3',
        title: 'The Divine Liturgy',
        subtitle: 'Kidase Text with Parallel Translations (መጽሐፈ ቅዳሴ)',
        description: 'The complete order of the Divine Liturgy including the 14 Eucharistic Anaphoras with side-by-side Ge\'ez, Amharic, and English translations.',
        category: LibraryCategory.liturgical,
        tags: ['Ge\'ez / Eng', 'Liturgical', 'Sacraments'],
        telegramUrl: 'https://t.me/WCU_Orthodox_Library/103',
        sourceUrl: 'https://t.me/WCU_Orthodox_Library',
        readTime: '90 mins',
      ),
      LibraryItemModel(
        id: 'lib-4',
        title: 'Mezmur Compilation',
        subtitle: 'Tsome Digua & Yaredic Hymns (ፃመ ድጓ እና ዝማሬ)',
        description: 'Spiritual audio hymns and chants composed in ancient liturgical modes by St. Yared, cataloged for fellowship choirs and individual prayer.',
        category: LibraryCategory.mezmur,
        tags: ['Audio', 'Mezmur', 'St. Yared'],
        telegramUrl: 'https://t.me/WCU_Orthodox_Library/104',
        sourceUrl: 'https://t.me/WCU_Orthodox_Library',
        audioDuration: '38 mins',
        lyricsOrExcerpts: 'በስመ አብ ወወልድ ወመንፈስ ቅዱስ አሐዱ አምላክ\nምስጋና ለቅድስት ድንግል ማርያም ይሁን...',
      ),
      LibraryItemModel(
        id: 'lib-5',
        title: 'Intro to Dogma',
        subtitle: 'Year 1 Fellowship Course Material',
        description: 'Comprehensive introduction to the 5 Pillars of Mystery (Misteerate Bete Christian): Trinity, Incarnation, Baptism, Holy Eucharist, Resurrection.',
        category: LibraryCategory.dogma,
        tags: ['English', 'Dogma', 'Academic'],
        telegramUrl: 'https://t.me/WCU_Orthodox_Library/105',
        sourceUrl: 'https://t.me/WCU_Orthodox_Library',
        readTime: '30 mins module',
      ),
    ];

    // 6. Church Programs & Feasts
    _programs = [
      ChurchProgramModel(
        id: 'prog-1',
        title: 'Upcoming Sunday Divine Liturgy',
        churchName: 'St. Mary\'s Orthodox Church',
        dateTime: DateTime.now().add(const Duration(hours: 2, minutes: 15)),
        initialDurationRemaining: const Duration(hours: 2, minutes: 15, seconds: 45),
        description: 'Solemn Kidase gathering for WCU university students with morning sermon and Eucharistic communion.',
        category: 'Liturgy',
      ),
      ChurchProgramModel(
        id: 'prog-2',
        title: 'Feast of Saint George (Lideta Giorgis)',
        churchName: 'Debre Menkrat Saint George Church',
        dateTime: DateTime.now().add(const Duration(days: 3)),
        initialDurationRemaining: const Duration(days: 3),
        description: 'Annual feast celebration with nighttime vigil (Mahlet) and fellowship agape banquet.',
        category: 'Feast',
      ),
      ChurchProgramModel(
        id: 'prog-3',
        title: 'Mid-Week Prayer & Bible Study Feed',
        churchName: 'Campus Fellowship Hall',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        initialDurationRemaining: const Duration(days: 1),
        description: 'Deep study of the Epistle to the Romans with Father Ephrem Tadesse.',
        category: 'Bible Study',
      ),
    ];

    // 7. 10 Official EOTC Fellowship Departments (የግቢ ጉባኤ 10ሩ ንዑሳን ክፍሎች)
    _ministries = [
      MinistryModel(
        id: 'dept-apostolic',
        titleEn: 'Education & Apostolic Ministry',
        titleAmharic: 'ትምህርትና ሐዋርያዊ አገልግሎት',
        iconName: 'menu_book',
        descriptionEn: 'Organizes orthodox dogma courses, campus evangelism, patristics study circles, and scripture preaching.',
        descriptionAmharic: 'የነገረ መለኮት፣ የቤተክርስቲያን ታሪክና የቀኖና ትምህርቶችን ማዘጋጀት፣ ሐዋርያዊ አገልግሎትና የመጽሐፍ ቅዱስ ጥናት መርሐ ግብራትን ማስተባበር።',
        pillar: MinistryPillar.spiritualEducation,
        teamLead: 'Yared Tadesse',
        coordinatorBaptismalName: 'Gebre Meskel',
        coordinatorPhone: '+251911223344',
        coordinatorRole: 'Apostolic Ministry Coordinator',
        openSlots: 8,
        activeCount: 34,
        tags: ['Dogma', 'Evangelism', 'Bible Study', 'Patristics'],
        subWings: [
          'Dogmatics & Canon (ነገረ መለኮት)',
          'Scripture Study (የመጽሐፍ ቅዱስ ጥናት)',
          'Apostolic Outreach (ሐዋርያዊ ስብከት)',
          'Patristics & Library (የአበው ታሪክ)',
        ],
        meetingSchedule: 'Tuesdays 5:30 PM & Sundays 2:00 PM',
        requirements: 'Foundational church course completion; dedicated heart for gospel teaching.',
      ),
      MinistryModel(
        id: 'dept-membercare',
        titleEn: 'Member Care, Counseling & Capacity',
        titleAmharic: 'አባላት እንክብካቤ ፤ምክክርና አቅም ማጎልበቻ',
        iconName: 'favorite_border',
        descriptionEn: 'Follows up on students spiritual and moral well-being, conducts peer counseling, and organizes leadership workshops.',
        descriptionAmharic: 'የተማሪዎችን መንፈሳዊና ማኅበራዊ ሕይወት መከታተል፣ የምክር አገልግሎት መስጠት እና የአመራር ክህሎት ማጎልበቻ ስልጠናዎችን ማዘጋጀት።',
        pillar: MinistryPillar.memberCareSocial,
        teamLead: 'Selamawit Desta',
        coordinatorBaptismalName: 'Walata Maryam',
        coordinatorPhone: '+251922334455',
        coordinatorRole: 'Member Care Coordinator',
        openSlots: 6,
        activeCount: 28,
        tags: ['Care', 'Counseling', 'Freshmen', 'Leadership'],
        subWings: [
          'Freshman Follow-up (የአዳዲስ ተማሪዎች ክትትል)',
          'Spiritual Counseling (የምክርና ማጽናናት)',
          'Capacity Building (የአቅም ማጎልበቻ)',
          'Sisterhood Care (የእህቶች ሕብረት)',
        ],
        meetingSchedule: 'Thursdays 6:00 PM',
        requirements: 'Empathy, confidentiality, and active commitment to fellowship life.',
      ),
      MinistryModel(
        id: 'dept-music',
        titleEn: 'Music & Arts',
        titleAmharic: 'መዝሙርና ስነ ጥበባት',
        iconName: 'music_note',
        descriptionEn: 'Prepares spiritual hymns, liturgical chants (Zema), sacred Begena/Kirar instruments, Christian drama, and iconography.',
        descriptionAmharic: 'የኦርቶዶክሳዊ ዝማሬዎችን ማጥናት፣ የበገናና ክራር ትምህርት፣ መንፈሳዊ ድራማ፣ ስነ ጽሑፍ እና ስዕለ አድኅኖ ስነ ጥበባት።',
        pillar: MinistryPillar.spiritualEducation,
        teamLead: 'Dawit Fikadu',
        coordinatorBaptismalName: 'Gebre Yohannes',
        coordinatorPhone: '+251933445566',
        coordinatorRole: 'Music & Arts Coordinator',
        openSlots: 12,
        activeCount: 52,
        tags: ['Mezmur', 'Zema', 'Begena', 'Drama', 'Poetry'],
        subWings: [
          'Choir Vocal & Zema (የዝማሬና ዜማ ዘርፍ)',
          'Begena & Instruments (የበገናና መሳሪያዎች)',
          'Spiritual Drama (መንፈሳዊ ቴአትር)',
          'Literature & Poetry (ስነ ጽሑፍና ስንኝ)',
        ],
        meetingSchedule: 'Wednesdays & Saturdays 4:00 PM',
        requirements: 'Punctual rehearsal attendance; dedication to ancient Yaredic traditions.',
      ),
      MinistryModel(
        id: 'dept-development',
        titleEn: 'Development & Revenue Collection',
        titleAmharic: 'ልማትና ገቢ አሰባሰብ',
        iconName: 'monetization_on_outlined',
        descriptionEn: 'Plans and coordinates fundraising initiatives, holiday sales, spiritual publications distribution, and donor campaigns.',
        descriptionAmharic: 'የገቢ ማስገኛ ፕሮጀክቶችን መንደፍ፣ የበዓላት ባዛርና የንዋየ ቅድሳት ሽያጭ ማስተባበር፣ የበጎ አድራጊዎች ድጋፍ ማሰባሰብ።',
        pillar: MinistryPillar.operationsFinance,
        teamLead: 'Ermias Berhanu',
        coordinatorBaptismalName: 'Habte Maryam',
        coordinatorPhone: '+251944556677',
        coordinatorRole: 'Development Coordinator',
        openSlots: 5,
        activeCount: 22,
        tags: ['Fundraising', 'Bazaar', 'Alumni', 'Projects'],
        subWings: [
          'Fundraising Projects (የገቢ ፕሮጀክቶች)',
          'Holiday Bazaars & Sales (የበዓላት ባዛር)',
          'Alumni Relations (የቀድሞ ተማሪዎች)',
          'Merchandise & Books (የመጻሕፍትና ንዋያተ ቅድሳት)',
        ],
        meetingSchedule: 'Fridays 5:00 PM',
        requirements: 'Project management, marketing creativity, or sales enthusiasm.',
      ),
      MinistryModel(
        id: 'dept-accounting',
        titleEn: 'Accounting & Property',
        titleAmharic: 'ሒሳብና ንብረት',
        iconName: 'account_balance_wallet',
        descriptionEn: 'Maintains meticulous accounting ledgers, manages fellowship assets, sound systems, robes, and campus church property.',
        descriptionAmharic: 'የፋይናንስና የሂሳብ መዛግብትን መያዝ፣ የድምፅ መሳሪያዎችን፣ አልባሳትና የግብረ ጽድቅ ንብረቶችን በአግባቡ ማስተዳደር።',
        pillar: MinistryPillar.operationsFinance,
        teamLead: 'Bethlehem Girma',
        coordinatorBaptismalName: 'Walata Tsion',
        coordinatorPhone: '+251955667788',
        coordinatorRole: 'Accounting & Property Coordinator',
        openSlots: 4,
        activeCount: 16,
        tags: ['Finance', 'Ledger', 'Audio Gear', 'Inventory'],
        subWings: [
          'Bookkeeping & Finance (የሂሳብ መዝገብ)',
          'Sound & Audio Equipment (የድምፅ መሳሪያዎች)',
          'Church Vestments & Robes (የአልባሳት ንብረት)',
          'Procurement & Logistics (ግዢና አቅርቦት)',
        ],
        meetingSchedule: 'Saturdays 10:00 AM',
        requirements: 'High integrity and diligence; Accounting/Economics background preferred.',
      ),
      MinistryModel(
        id: 'dept-programs',
        titleEn: 'Batch & Program Coordination',
        titleAmharic: 'ባችና መርሐ ግብራት ማስተባበሪያ',
        iconName: 'event_available',
        descriptionEn: 'Coordinates year batches (1st to graduating class), reserves campus auditoriums, and manages overall fellowship schedules.',
        descriptionAmharic: 'የየክፍለ ዓመቱን (የባች) ተወካዮች ማስተባበር፣ የአዳራሽና የቦታ ፈቃድ ማመቻቸት፣ ሳምንታዊና ወርሃዊ መርሐ ግብራትን ማቀናጀት።',
        pillar: MinistryPillar.memberCareSocial,
        teamLead: 'Abel Solomon',
        coordinatorBaptismalName: 'Tekle Haymanot',
        coordinatorPhone: '+251966778899',
        coordinatorRole: 'Batch & Programs Coordinator',
        openSlots: 7,
        activeCount: 30,
        tags: ['Batch Reps', 'Hall Booking', 'Conferences', 'Events'],
        subWings: [
          'Freshman Batch Reps (የ1ኛ ዓመት ተወካዮች)',
          'Senior & Graduating Reps (የተመራቂዎች)',
          'Hall Booking & Protocol (የአዳራሽና ፕሮቶኮል)',
          'Vigil & Feast Logistics (የጉባኤያት አቀነባባሪ)',
        ],
        meetingSchedule: 'Mondays 6:00 PM',
        requirements: 'Punctuality, strong organizational communication across batches.',
      ),
      MinistryModel(
        id: 'dept-charity',
        titleEn: 'Vocational & Charitable Activities',
        titleAmharic: 'ሙያ ና በጎ አድራጎት',
        iconName: 'volunteer_activism',
        descriptionEn: 'Manages student mutual aid, hospital & orphanage visits, blood drives, dorm welfare visits, and vocational peer tutoring.',
        descriptionAmharic: 'ለተቸገሩ ተማሪዎች የምግብና የትምህርት ድጋፍ ማድረግ፣ የሆስፒታልና የአቅመ ደካሞች ጥየቃ፣ የደም ልገሳና የሙያ ማጋራት።',
        pillar: MinistryPillar.memberCareSocial,
        teamLead: 'Rahel Tesfaye',
        coordinatorBaptismalName: 'Walata Michael',
        coordinatorPhone: '+251977889900',
        coordinatorRole: 'Charity Coordinator',
        openSlots: 10,
        activeCount: 40,
        tags: ['Charity', 'Mutual Aid', 'Hospital Visit', 'Blood Drive'],
        subWings: [
          'Student Emergency Fund (የተማሪዎች ድጋፍ)',
          'Hospital & Prison Outreach (የሕሙማን ጥየቃ)',
          'Community Blood Drive (የደም ልገሳ)',
          'Vocational Tutoring (የትምህርትና ሙያ ማጋራት)',
        ],
        meetingSchedule: 'Saturdays 2:00 PM',
        requirements: 'Compassionate heart for charity, active attendance in welfare visits.',
      ),
      MinistryModel(
        id: 'dept-language',
        titleEn: 'Language & Special Needs',
        titleAmharic: 'ቋንቋና ልዩ ልዩ ፍላጎት',
        iconName: 'translate',
        descriptionEn: 'Provides multilingual liturgical services (Afan Oromo, Tigrinya, English), sign language translation, and accessibility for disabled members.',
        descriptionAmharic: 'በተለያዩ ቋንቋዎች (በአፋን ኦሮሞ፣ በትግርኛ፣ በእንግሊዝኛ) ትምህርቶችን ማዘጋጀት፣ የምልክት ቋንቋ አገልግሎትና አካል ጉዳተኞችን ማገዝ።',
        pillar: MinistryPillar.spiritualEducation,
        teamLead: 'Gemechu Bekele',
        coordinatorBaptismalName: 'Haile Maryam',
        coordinatorPhone: '+251988990011',
        coordinatorRole: 'Language & Special Needs Coordinator',
        openSlots: 8,
        activeCount: 25,
        tags: ['Afan Oromo', 'Sign Language', 'Tigrinya', 'English', 'Inclusion'],
        subWings: [
          'Afan Oromo Ministry (የአፋን ኦሮሞ አገልግሎት)',
          'Tigrinya & Other Languages (የትግርኛና ሌሎች)',
          'Sign Language (የምልክት ቋንቋ)',
          'Accessibility Support (የልዩ ፍላጎት ድጋፍ)',
        ],
        meetingSchedule: 'Sundays 4:00 PM',
        requirements: 'Language fluency or willingness to learn sign language.',
      ),
      MinistryModel(
        id: 'dept-planning',
        titleEn: 'Planning & Monitoring',
        titleAmharic: 'እቅድና ክትትል',
        iconName: 'insights',
        descriptionEn: 'Prepares semester/annual strategic plans, tracks project KPIs, monitors department execution, and evaluates performance.',
        descriptionAmharic: 'የግቢ ጉባኤውን ዓመታዊና ሴሚስተራዊ እቅድ ማዘጋጀት፣ የክፍላትን አፈፃፀም መከታተልና የግምገማ ሪፖርቶችን ማቅረብ።',
        pillar: MinistryPillar.governanceAudit,
        teamLead: 'Nahom Assefa',
        coordinatorBaptismalName: 'Gebre Kidan',
        coordinatorPhone: '+251999001122',
        coordinatorRole: 'Planning & Monitoring Coordinator',
        openSlots: 3,
        activeCount: 14,
        tags: ['Strategy', 'KPIs', 'Reports', 'Evaluation'],
        subWings: [
          'Strategic Planning (የስትራቴጂክ እቅድ)',
          'Department Tracking (የክፍላት አፈፃፀም)',
          'Statistical Analysis (የስታቲስቲክስ ትንተና)',
          'Evaluation Seminars (የግምገማ መድረኮች)',
        ],
        meetingSchedule: 'Sundays 6:00 PM',
        requirements: 'Analytical thinking, organizational discipline, 2nd year or above.',
      ),
      MinistryModel(
        id: 'dept-audit',
        titleEn: 'Audit & Inspection',
        titleAmharic: 'ኦዲት ና ኢንስፔክሽን',
        iconName: 'fact_check_outlined',
        descriptionEn: 'Conducts independent financial audits, verifies property registries, and ensures adherence to EOTC fellowship bylaws and canons.',
        descriptionAmharic: 'ገለልተኛ የፋይናንስና የሂሳብ ምርመራ ማካሄድ፣ የንብረት ቆጠራና ማረጋገጫ፣ የደንብና መመሪያ ተገዢነትን መቆጣጠር።',
        pillar: MinistryPillar.governanceAudit,
        teamLead: 'Kaleb Worku',
        coordinatorBaptismalName: 'Wolde Rufael',
        coordinatorPhone: '+251910112233',
        coordinatorRole: 'Audit & Inspection Coordinator',
        openSlots: 3,
        activeCount: 12,
        tags: ['Audit', 'Finance Check', 'Inventory Audit', 'Compliance'],
        subWings: [
          'Financial Audit (የፋይናንስ ቁጥጥር)',
          'Asset Inspection (የንብረት ፍተሻ)',
          'Bylaw Compliance (የመተዳደሪያ ደንብ)',
          'Quarterly Reports (የሩብ ዓመት ሪፖርት)',
        ],
        meetingSchedule: 'Bi-weekly Saturdays 9:00 AM',
        requirements: 'Uncompromising integrity, 3rd/4th year student, background in Accounting/Law/Management.',
      ),
    ];

    // Seeded Department Members (Active Servants)
    _departmentMembers = [
      DepartmentMemberModel(
        id: 'mem-1',
        departmentId: 'dept-music',
        studentId: 'usr-101',
        studentName: 'Yohannes Girma',
        studentBaptismalName: 'Haile Selassie',
        studentDept: 'Civil Engineering',
        studentYear: '3rd Year',
        phoneNumber: '+251911445566',
        subWing: 'Choir Vocal & Zema (የዝማሬና ዜማ ዘርፍ)',
        roleInDepartment: 'Lead Chanter (አዝማሪ)',
        joinedDate: DateTime.now().subtract(const Duration(days: 180)),
      ),
      DepartmentMemberModel(
        id: 'mem-2',
        departmentId: 'dept-music',
        studentId: 'usr-102',
        studentName: 'Martha Tedla',
        studentBaptismalName: 'Walata Petros',
        studentDept: 'Medicine',
        studentYear: '4th Year',
        phoneNumber: '+251922556677',
        subWing: 'Begena & Instruments (የበገናና መሳሪያዎች)',
        roleInDepartment: 'Begena Instructor',
        joinedDate: DateTime.now().subtract(const Duration(days: 220)),
      ),
      DepartmentMemberModel(
        id: 'mem-3',
        departmentId: 'dept-accounting',
        studentId: 'usr-103',
        studentName: 'Amanuel Tadesse',
        studentBaptismalName: 'Gebre Gabriel',
        studentDept: 'Accounting & Finance',
        studentYear: '3rd Year',
        phoneNumber: '+251933667788',
        subWing: 'Bookkeeping & Finance (የሂሳብ መዝገብ)',
        roleInDepartment: 'Assistant Auditor',
        joinedDate: DateTime.now().subtract(const Duration(days: 90)),
      ),
      DepartmentMemberModel(
        id: 'mem-4',
        departmentId: 'dept-charity',
        studentId: 'usr-104',
        studentName: 'Hanna Solomon',
        studentBaptismalName: 'Walata Maryam',
        studentDept: 'Nursing',
        studentYear: '2nd Year',
        phoneNumber: '+251944778899',
        subWing: 'Hospital & Prison Outreach (የሕሙማን ጥየቃ)',
        roleInDepartment: 'Hospital Visit Lead',
        joinedDate: DateTime.now().subtract(const Duration(days: 120)),
      ),
    ];

    // Seeded Volunteer Applications routed to coordinators
    _volunteerApplications = [
      VolunteerApplicationModel(
        id: 'app-sample-1',
        studentId: 'usr-1',
        studentName: 'Dawit Alemu',
        studentBaptismalName: 'Gebre Michael',
        studentDept: 'Electrical Engineering',
        studentPhone: '+251911223344',
        studentYear: '2nd Year',
        ministryId: 'dept-music',
        ministryTitle: 'Music & Arts',
        ministryAmharicTitle: 'መዝሙርና ስነ ጥበባት',
        preferredSubWing: 'Begena & Instruments (የበገናና መሳሪያዎች)',
        reason: 'I have been learning traditional Begena hymnody for 2 years and wish to serve in campus spiritual nights.',
        experience: 'Parish youth choir Begena player in Debre Markos',
        availability: 'Wednesday evenings & Sunday afternoons',
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      VolunteerApplicationModel(
        id: 'app-sample-2',
        studentId: 'usr-2',
        studentName: 'Hewan Bekele',
        studentBaptismalName: 'Walata Petros',
        studentDept: 'Accounting & Finance',
        studentPhone: '+251922334455',
        studentYear: '3rd Year',
        ministryId: 'dept-accounting',
        ministryTitle: 'Accounting & Property',
        ministryAmharicTitle: 'ሒሳብና ንብረት',
        preferredSubWing: 'Bookkeeping & Finance (የሂሳብ መዝገብ)',
        reason: 'Eager to apply my accounting skills to ensure transparent, audited fellowship property and ledgers.',
        experience: 'Accounting student, familiarity with Excel & Peachtree',
        availability: 'Saturdays & Friday afternoons',
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      VolunteerApplicationModel(
        id: 'app-sample-3',
        studentId: 'usr-3',
        studentName: 'Mikias Haile',
        studentBaptismalName: 'Gebre Kristos',
        studentDept: 'Pharmacy',
        studentPhone: '+251933445566',
        studentYear: '1st Year Freshman',
        ministryId: 'dept-charity',
        ministryTitle: 'Vocational & Charitable Activities',
        ministryAmharicTitle: 'ሙያ ና በጎ አድራጎት',
        preferredSubWing: 'Student Emergency Fund (የተማሪዎች ድጋፍ)',
        reason: 'I want to help needy freshman students adapt to university life and coordinate meal ticket support.',
        experience: 'Red Cross high school volunteer leader',
        availability: 'Saturdays and free afternoons',
        status: ApplicationStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
        reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
        reviewedByCoordinator: 'Rahel Tesfaye (Charity Coordinator)',
        coordinatorNotes: 'Welcome aboard Mikias! Please join the Saturday 2:00 PM briefing.',
      ),
    ];

    // 8. Liturgical Calendar & Fasting Engine Mock Data
    _calendarWeek = [
      EthiopianCalendarDay(
        geezDateString: 'ጳጉሜን ፫ / 3',
        geezMonth: 'ጳጉሜን (Pagumen)',
        geezDay: 3,
        geezYear: 2016,
        gregorianDate: DateTime.now(),
        saintOfToday: 'Archangel St. Raphael (ሩፋኤል) & Melchizedek (መልከ ጼዴቅ)',
        saintOfTodayGeEz: 'ሩፋኤል ሊቀ መላእክት ወመልከ ጼዴቅ ካህን',
        isFasting: true,
        fastName: 'Wednesday Fast (የረቡዕ ጾም)',
        fastRules: 'Strictly vegan, fast until 3:00 PM (9:00 LT). Repentance & prayer.',
        isFishAllowed: false,
        fastingUntilHour: '3:00 PM',
        scriptures: const DailyScriptureModel(
          epistle: 'ሮሜ 8፥14-30 (Romans 8:14-30)',
          catholicEpistle: '1 ጴጥሮስ 2፥1-10 (1 Peter 2:1-10)',
          acts: 'ግብረ ሐዋርያት 10፥34-48 (Acts 10:34-48)',
          psalm: 'መዝሙረ ዳዊት 102፥20-22 (Psalm 102:20-22)',
          gospel: 'ዮሐንስ 14፥1-14 (John 14:1-14)',
          reflection: '“በመንፈስ የሚመሩ ሁሉ የእግዚአብሔር ልጆች ናቸው።” — ሮሜ 8፥14',
          synaxariumExcerpt: 'በዚህች ዕለት ክብሩ ከፍ ከፍ ያለ ሊቀ መላእክት ቅዱስ ሩፋኤል መታሰቢያው ሆነ። እርሱም በሽተኞችን የሚፈውስና የሰዎችን ጸሎት ወደ እግዚአብሔር ዙፋን የሚያደርስ ነው።',
        ),
      ),
      EthiopianCalendarDay(
        geezDateString: 'ጳጉሜን ፬ / 4',
        geezMonth: 'ጳጉሜን (Pagumen)',
        geezDay: 4,
        geezYear: 2016,
        gregorianDate: DateTime.now().add(const Duration(days: 1)),
        saintOfToday: 'St. Titus & St. Abba Isaiah (አባ ኢሳይያስ)',
        saintOfTodayGeEz: 'ቅዱስ ቲቶ ሐዋርያ ወአባ ኢሳይያስ ገዳማዊ',
        isFasting: false,
        fastName: 'Non-Fasting Day (ፈታሕ)',
        fastRules: 'Regular dietary observance. Morning prayer & scripture reading.',
        isFishAllowed: true,
        fastingUntilHour: 'None',
        scriptures: const DailyScriptureModel(
          epistle: 'ቲቶ 1፥1-9 (Titus 1:1-9)',
          catholicEpistle: 'ያዕቆብ 1፥12-20 (James 1:12-20)',
          acts: 'ግብረ ሐዋርያት 16፥1-10 (Acts 16:1-10)',
          psalm: 'መዝሙረ ዳዊት 89፥1-6 (Psalm 89:1-6)',
          gospel: 'ማቴዎስ 10፥1-15 (Matthew 10:1-15)',
          reflection: '“በፈተና የሚጸና ሰው የተባረከ ነው፤ ፈተናውን ባሸነፈ ጊዜ የሕይወትን አክሊል ይቀበላል።”',
          synaxariumExcerpt: 'በዚህች ዕለት ሐዋርያው ቅዱስ ቲቶና ታላቁ ገዳማዊ አባ ኢሳይያስ እረፍታቸው ሆነ።',
        ),
      ),
      EthiopianCalendarDay(
        geezDateString: 'ጳጉሜን ፭ / 5',
        geezMonth: 'ጳጉሜን (Pagumen)',
        geezDay: 5,
        geezYear: 2016,
        gregorianDate: DateTime.now().add(const Duration(days: 2)),
        saintOfToday: 'Eve of Enkutatash (የዘመን መለወጫ ዋዜማ) & St. John the Baptist',
        saintOfTodayGeEz: 'ዋዜማሁ ለርእሰ ዓውደ ዓመት ወዮሐንስ መጥምቅ',
        isFasting: true,
        fastName: 'Friday Fast (የዓርብ ጾም)',
        fastRules: 'Fasting until 3:00 PM (9:00 LT). Thanksgiving for the passing year.',
        isFishAllowed: false,
        fastingUntilHour: '3:00 PM',
        scriptures: const DailyScriptureModel(
          epistle: 'ዕብራውያን 11፥32-40 (Hebrews 11:32-40)',
          catholicEpistle: '1 ዮሐንስ 2፥12-17 (1 John 2:12-17)',
          acts: 'ግብረ ሐዋርያት 19፥1-10 (Acts 19:1-10)',
          psalm: 'መዝሙረ ዳዊት 65፥9-13 (Psalm 65:9-13)',
          gospel: 'ሉቃስ 1፥57-80 (Luke 1:57-80)',
          reflection: '“ዓመቱን በቸርነትህ ታቀዳጃለህ፤ ዱካዎችህም ስብን ያንጠባጥባሉ።” — መዝሙረ ዳዊት 65፥11',
          synaxariumExcerpt: 'ይህች ቀን የዓመቱ መጨረሻ ናት፤ የእግዚአብሔርን ቸርነት የምናመሰግንበትና መጥምቁ ቅዱስ ዮሐንስን የምናስብበት ነው።',
        ),
      ),
    ];
    _currentCalendarDay = _calendarWeek.first;

    // 9. Daily Prayer Book (Wudase Maryam & Yezewetir Tselot)
    _wudaseMaryam = const PrayerBookModel(
      id: 'bk-wudase',
      title: 'Wudase Maryam (Praise of St. Mary)',
      titleGeEz: 'ውዳሴ ማርያም (ዘሰባቱ ዕለታት)',
      description: 'Daily praises composed by St. Ephrem the Syrian and St. Cyriacus of Behnesa.',
      sections: [
        PrayerSectionModel(
          id: 'wud-mon',
          titleGeEz: 'ውዳሴ ዘሰኑይ (ሰኞ)',
          titleAmharic: 'የሰኞ ውዳሴ ማርያም',
          titleEn: 'Monday Praises of St. Mary',
          geEzText: '''ፈቀደ እግዚእ ያግዕዞ ለአዳም ኅዙነ ወትኩዘ ልብ፡ ወያግብኦ ኀበ ዘቀዳሚ መንበሩ።
አክሊለ ሠነይትኪ ኦ ድንግል ንጽሕት።
ተፈሥሒ ኦ ድንግል ንጽሕት ዘአልቦታ ሙስና፡ ዘተወልደ እምኔኪ አምላከ ቅዱሳን።
ዘአልቦ ጥንት ወዘአልቦ ማኅለቅት ዘከማሁ።
እስመ ውእቱ አክበረኪ ወአልዐለኪ እምኩሉ ፍጥረት።
ኪሩቤል ወሱራፌል ይሰግዱ ለኪ ወይዌድሱኪ በዕለተ ዕረፍት።''',
          amharicText: '''ጌታ ልቡ ያዘነና የተከዘ አዳምን ነፃ ያወጣው ዘንድ፥ ወደ ቀደመ ቦታውም ይመልሰው ዘንድ ወደደ።
ንጽሕት ድንግል ሆይ፥ መልካም አክሊላችን አንቺ ነሽ።
ጥፋት የሌለብሽ ንጽሕት ድንግል ሆይ ደስ ይበልሽ፤ ከአንቺ የተወለደው የቅዱሳን አምላክ ነው።
እርሱ መጀመሪያና መጨረሻ የሌለው ነው።
ከፍጡራን ሁሉ በላይ አክብሮሻልና፥ ከፍ ከፍም አድርጎሻልና።
ኪሩቤልና ሱራፌል በሰንበት ቀን ይሰግዱልሻል፥ ያመሰግኑሻልም።''',
        ),
        PrayerSectionModel(
          id: 'wud-tue',
          titleGeEz: 'ውዳሴ ዘሠሉስ (ማክሰኞ)',
          titleAmharic: 'የማክሰኞ ውዳሴ ማርያም',
          titleEn: 'Tuesday Praises of St. Mary',
          geEzText: '''አክሊለ ምክሕነ ወቀዳሚተ መድኃኒትነ፡ ወመሠረተ ንጽሕነ ኮነ በማርያም ድንግል፡ እንተ ወለደት ለነ ዘእግዚአብሔር ቃለ።
ዘኮነ ሰብአ በእንተ መድኃኒትነ።
እምድኅረ ኮነ ሰብአ ፈጸመ ኩሎ ሕገ ወትእዛዘ።
ዘአልቦ ኃጢአት ወዘኢረከበ ቦቱ ዐመፃ።
ተፈሥሒ ኦ ማርያም ድንግል ዘተፀነሰ በማኅፀንኪ መድኅነ ዓለም።''',
          amharicText: '''የመመኪያችን ዘውድ፥ የመዳናችን መጀመሪያ፥ የንጽሕናችን መሠረት የእግዚአብሔርን ቃል በወለደችልን በድንግል ማርያም ሆነ።
እርሱ ስለ እኛ መዳን ሰው ሆነ።
ሰው ከሆነም በኋላ ሕግንና ትእዛዝን ሁሉ ፈጸመ።
ኃጢአት የሌለበትና በደል ያልተገኘበት ነው።
የዓለም መድኃኒት በማኅፀንሽ የተፀነሰ ድንግል ማርያም ሆይ ደስ ይበልሽ።''',
        ),
        PrayerSectionModel(
          id: 'wud-wed',
          titleGeEz: 'ውዳሴ ዘረቡዕ (ረቡዕ)',
          titleAmharic: 'የረቡዕ ውዳሴ ማርያም',
          titleEn: 'Wednesday Praises of St. Mary',
          geEzText: '''ኩሉ ሠራዊተ ሰማያት ይብሉ ብፅዕት አንቲ፡ ታቦት ንጽሕት ዘአልቦታ ርኩስ።
ዘአስተርአየ ውስቴታ ማኅደረ መለኮት።
አንቲ ውእቱ ደብተራ ዘተሰመይኪ ቅድስተ ቅዱሳን።
ዘውስቴታ ታቦት ዘወርቅ ጽሩይ፡ ዘአልቦታ ጥልቀት።
ጽላተ ኪዳን ዘጸሐፎን በአጻብዒሁ እግዚአብሔር።''',
          amharicText: '''የሰማይ ሠራዊት ሁሉ እድለኛ ነሽ ይላሉ፤ እድፍ ጉድፍ የሌለብሽ ንጽሕት ታቦት ነሽና።
የመለኮት ማደሪያ በእርሷ የታየባት።
ቅድስተ ቅዱሳን የተባልሽ ድንኳን አንቺ ነሽ።
በውስጧ ምንም ጉድለት የሌለበት የጠራ የወርቅ ታቦት አለ።
እግዚአብሔር በጣቶቹ የጻፋቸው የኪዳን ጽላት በውስጧ አሉ።''',
        ),
        PrayerSectionModel(
          id: 'wud-thu',
          titleGeEz: 'ውዳሴ ዘሐሙስ (ሐሙስ)',
          titleAmharic: 'የሐሙስ ውዳሴ ማርያም',
          titleEn: 'Thursday Praises of St. Mary',
          geEzText: '''ዕፀ ጳጦስ እንተ ርእያ ሙሴ በነደ እሳት እንዘ ተነድድ ወኢትውዒ፡ ማርያም ይእቲ።
ዘነደ እሳተ መለኮቱ ኢያውዓያ።
ተፈሥሒ ኦ ምልዕተ ጸጋ ዘተወልደ እምኔኪ ክርስቶስ።
ብርሃን ዘእምብርሃን፡ አምላክ ዘእምአምላክ ዘበአማን።
ወልደ እግዚአብሔር ሕያው።''',
          amharicText: '''ሙሴ በእሳት ነበልባል ስትነድድ ሳለች ያልተቃጠለች ያያት ዛፍ (ዕፀ ጳጦስ) ማርያም ናት።
የመለኮቱ እሳት ነበልባል አላቃጠላትምና።
ጸጋን የተመላሽ ሆይ ደስ ይበልሽ፤ ከአንቺ የተወለደው ክርስቶስ ነው።
ከብርሃን የተገኘ ብርሃን፥ ከእውነተኛ አምላክ የተገኘ እውነተኛ አምላክ ነው።
የሕያው እግዚአብሔር ልጅ።''',
        ),
        PrayerSectionModel(
          id: 'wud-fri',
          titleGeEz: 'ውዳሴ ዘዓርብ (ዓርብ)',
          titleAmharic: 'የዓርብ ውዳሴ ማርያም',
          titleEn: 'Friday Praises of St. Mary',
          geEzText: '''ብፅዕት አንቲ ኦ ማርያም ወቡሩክ ፍሬ ከርሥኪ።
ድንግል ማርያም ወላዲተ አምላክ።
ዘአልቦ ሙስና ወዘኢይማስን በውሳጣ።
ተፈሥሒ ኦ ቅድስት ድንግል ዘበእንቲአኪ ተሣሃለነ እግዚአብሔር።
ወአድኃነነ እምደይን።''',
          amharicText: '''ማርያም ሆይ አንቺ የተባረክሽ ነሽ፥ የማኅፀንሽም ፍሬ የተባረከ ነው።
አምላክን የወለድሽ ድንግል ማርያም ሆይ።
በውስጧ ጥፋት የሌለባትና የማትጠፋ።
ቅድስት ድንግል ሆይ ደስ ይበልሽ፤ በአንቺ ምክንያት እግዚአብሔር ይቅር አለን።
ከፍርድም አዳነን።''',
        ),
        PrayerSectionModel(
          id: 'wud-sat',
          titleGeEz: 'ውዳሴ ዘቀዳሚት (ቅዳሜ)',
          titleAmharic: 'የቅዳሜ ውዳሴ ማርያም',
          titleEn: 'Saturday Praises of St. Mary',
          geEzText: '''ቅድስት ወብፅዕት አንቲ ድንግል ማርያም፡ ታቦተ ጽድቅ ወማኅደረ ሰላም።
እስመ እምኔኪ ተወልደ ፀሐየ ጽድቅ።
ዘአብርሃ ለኩሉ ፍጥረት በብርሃነ መለኮቱ።
ተፈሥሒ ኦ ድንግል ንጽሕት ዘአስተርአየ በላዕሌኪ ስብሐተ እግዚአብሔር።''',
          amharicText: '''ድንግል ማርያም ሆይ አንቺ ቅድስትና የተመሰገንሽ ነሽ፤ የእውነት ታቦትና የሰላም ማደሪያ ነሽ።
ከአንቺ የጽድቅ ፀሐይ ተወልዷልና።
በመለኮቱ ብርሃን ለፍጥረት ሁሉ ያበራ።
የእግዚአብሔር ክብር በአንቺ ላይ የታየ ንጽሕት ድንግል ሆይ ደስ ይበልሽ።''',
        ),
        PrayerSectionModel(
          id: 'wud-sun',
          titleGeEz: 'ውዳሴ ዘእሑድ (እሑድ)',
          titleAmharic: 'የእሑድ ውዳሴ ማርያም',
          titleEn: 'Sunday Praises of St. Mary',
          geEzText: '''ይዌድስዋ መላእክት ለማርያም በውስተ መንጦላዕት፡ ወይብሉ ብፅዕት አንቲ እምኩሎን አንስት።
እስመ ተወልደ እምኔኪ መድኅነ ዓለም።
ተፈሥሒ ኦ ድንግል ምልዕተ ጸጋ፡ እግዚአብሔር ምስሌኪ።
ኪሩቤል ወሱራፌል ይሰግዱ ለኪ።''',
          amharicText: '''መላእክት በመጋረጃው ውስጥ ሆነው ማርያምን ያመሰግኗታል፤ ከሴቶች ሁሉ አንቺ የተባረክሽ ነሽ ይላሉ።
የዓለም መድኃኒት ከአንቺ ተወልዷልና።
ጸጋን የተመላሽ ድንግል ሆይ ደስ ይበልሽ፤ እግዚአብሔር ከአንቺ ጋር ነው።
ኪሩቤልና ሱራፌል ይሰግዱልሻል።''',
        ),
      ],
    );

    _yezewetirTselot = const PrayerBookModel(
      id: 'bk-yezewetir',
      title: 'Yezewetir Tselot (Daily Prayers)',
      titleGeEz: 'ጸሎት ዘዘወትር',
      description: 'Canonical Daily Prayers chanted by Orthodox faithful morning and evening.',
      sections: [
        PrayerSectionModel(
          id: 'yzt-1',
          titleGeEz: 'በስመ አብ ወወልድ ወመንፈስ ቅዱስ',
          titleAmharic: 'የመክፈቻ ጸሎት',
          titleEn: 'Introductory Trinitarian Prayer',
          geEzText: '''በስመ አብ ወወልድ ወመንፈስ ቅዱስ አሐዱ አምላክ አሜን።
ስብሐት ለአብ ስብሐት ለወልድ ስብሐት ለመንፈስ ቅዱስ።
ስብሐት ለእግዝእትነ ማርያም ድንግል ወላዲተ አምላክ።
ስብሐት ለመስቀለ ክርስቶስ ዕፀ መድኃኒት።''',
          amharicText: '''በአብ በወልድ በመንፈስ ቅዱስ አንድ አምላክ ስም አሜን።
ለአብ ምስጋና ይሁን፥ ለወልድ ምስጋና ይሁን፥ ለመንፈስ ቅዱስ ምስጋና ይሁን።
አምላክን ለወለደች ለእመቤታችን ለድንግል ማርያም ምስጋና ይሁን።
ለመድኃኒት እንጨት ለክርስቶስ መስቀል ምስጋና ይሁን።''',
        ),
        PrayerSectionModel(
          id: 'yzt-2',
          titleGeEz: 'አቡነ ዘበሰማያት',
          titleAmharic: 'የጌታ ጸሎት (አባታችን ሆይ)',
          titleEn: 'The Lord’s Prayer (Our Father)',
          geEzText: '''አቡነ ዘበሰማያት፡ ይቀደስ ስምከ፡ ትምጻእ መንግሥትከ፡ ለይኩን ፈቃድከ በከመ በሰማይ ከማሁ በምድር።
ሲሳየነ ዘለለ ዕለትነ ሀበነ ዮም፡ ኅድግ ለነ አበሳነ ወጌጋየነ በከመ ንሕነኒ ንኅድግ ለዘአበሰ ለነ።
ኢታብአነ እግዚኦ ውስተ መንሱት፡ አላ አድኅነነ ወባልሐነ እምኩሉ እኩይ።
እስመ ዚአከ ይእቲ መንግሥት ኃይል ወስብሐት ለዓለመ ዓለም አሜን።''',
          amharicText: '''በሰማያት የምትኖር አባታችን ሆይ፥ ስምህ ይቀደስ፤ መንግሥትህ ትምጣ፤ ፈቃድህ በሰማይ እንደ ሆነች እንዲሁም በምድር ትሁን።
የዕለት እንጀራችንን ዛሬ ስጠን፤ እኛም የበደሉንን ይቅር እንደምንል በደላችንን ይቅር በለን።
አቤቱ ወደ ፈተና አታግባን፥ ከክፉ ሁሉ አድነን እንጂ።
መንግሥት ያንተ ናትና ኃይልም ክብርም ለዘለዓለሙ አሜን።''',
        ),
      ],
    );

    // 10. Father Confessor & Spiritual Guidance Mock Data
    _confessorFathers = const [
      ConfessorFatherModel(
        id: 'fat-1',
        fullName: 'Kesis Yohannes Teshome',
        clericalTitle: 'መልአከ ሰላም ቀሲስ (Melake Selam Kesis)',
        churchName: "St. Mary's Orthodox Church (Hosanna WCU)",
        phoneNumber: '+251911456789',
        availableDays: ['Wednesday', 'Saturday', 'Sunday'],
        availableTimeSlots: ['9:00 AM - 11:30 AM', '3:00 PM - 5:30 PM'],
        bio: 'Campus fellowship Confession Father with 15+ years guiding university students in repentance, prayer, and Christian discipline.',
      ),
      ConfessorFatherModel(
        id: 'fat-2',
        fullName: 'Abba Gebre Selassie',
        clericalTitle: 'ቆሞስ አባ (Komos Abba)',
        churchName: 'Debre Mewi Medhanealem Church',
        phoneNumber: '+251912987654',
        availableDays: ['Thursday', 'Saturday', 'Sunday'],
        availableTimeSlots: ['2:00 PM - 4:30 PM', '5:00 PM - 7:00 PM'],
        bio: 'Spiritual director specialized in Patristic counseling, youth moral guidance, and preparation for the Holy Mysteries.',
      ),
    ];

    _confessionAppointments = [
      ConfessionAppointmentModel(
        id: 'conf-1',
        studentId: _currentUser.id,
        studentName: _currentUser.fullName,
        studentBaptismalName: _currentUser.baptismalName,
        studentPhone: _currentUser.phoneNumber,
        fatherId: 'fat-1',
        fatherName: 'መልአከ ሰላም ቀሲስ Yohannes Teshome',
        scheduledDate: DateTime.now().add(const Duration(days: 3)),
        timeSlot: '3:00 PM - 5:30 PM',
        topic: 'Communion Preparation & General Confession',
        status: ConfessionAppointmentStatus.confirmed,
        notes: 'Please read Psalm 50 (መዝሙረ ዳዊት 50) before arriving.',
      ),
    ];

    _spiritualQuestions = [
      AnonymousSpiritualQuestionModel(
        id: 'q-1',
        questionText: 'How should a university student observe fasting and prayer while having heavy laboratory and exam schedules?',
        category: 'Fasting & Campus Life',
        askedAt: DateTime.now().subtract(const Duration(days: 2)),
        isAnswered: true,
        answerText: 'Fasting is spiritual discipline combined with love and obedience. Eat nutritious vegan meals (legumes, vegetables, bread) after breaking your fast, maintain morning and evening prayer rules, and consult your Confession Father for canonical adjustments during strict exam weeks.',
        answeredBy: 'መልአከ ሰላም ቀሲስ Yohannes',
        isPublic: true,
      ),
      AnonymousSpiritualQuestionModel(
        id: 'q-2',
        questionText: 'What is the significance of receiving the Holy Eucharist with fasting from the previous midnight?',
        category: 'Sacraments & Canon',
        askedAt: DateTime.now().subtract(const Duration(days: 4)),
        isAnswered: true,
        answerText: 'Receiving the Holy Body and Blood of our Lord Jesus Christ requires complete physical and spiritual preparation (minimum 9 hours fasting, reconciliation with all brethren, sincere confession).',
        answeredBy: 'ቆሞስ አባ Gebre Selassie',
        isPublic: true,
      ),
    ];

    _communionChecklist = [
      CommunionChecklistItem(
        id: 'chk-1',
        title: 'Confession with Spiritual Father (ንስሐ መግባት)',
        description: 'Have a valid, recent confession and spiritual absolution.',
        isChecked: true,
      ),
      CommunionChecklistItem(
        id: 'chk-2',
        title: 'Reconciliation with Brethren (ከሰው ሁሉ ጋር መታረቅ)',
        description: 'Forgive anyone who wronged you and seek forgiveness from those you offended.',
        isChecked: true,
      ),
      CommunionChecklistItem(
        id: 'chk-3',
        title: '18-Hour / Midnight Fasting (የቁርባን ጾም መጠበቅ)',
        description: 'Abstain from all food and drink from midnight until Liturgy completion.',
        isChecked: false,
      ),
      CommunionChecklistItem(
        id: 'chk-4',
        title: 'Spiritual Focus & Cleanliness (ንጽሕናና ጸሎት)',
        description: 'Refrain from worldly disputes, keep pure thoughts, and recite Psalm 50.',
        isChecked: false,
      ),
    ];

    // 11. Pilgrimage & Monastery Trip Coordinator Mock Data
    _pilgrimageTrips = [
      PilgrimageTripModel(
        id: 'trip-kulubi',
        title: 'Annual Kulubi St. Gabriel Pilgrimage (የቁልቢ ቅዱስ ገብርኤል ንግሥ)',
        destination: 'Kulubi St. Gabriel Monastery (Harar Route)',
        departureDate: DateTime.now().add(const Duration(days: 14)),
        returnDate: DateTime.now().add(const Duration(days: 17)),
        departurePoint: 'WCU Main Campus Student Center Gate',
        isFree: false,
        feeAmount: 650.0,
        telebirrNumber: '+251911223344',
        telebirrAccountName: 'WCU Orthodox Student Fellowship (የተማሪዎች ግቢ ጉባኤ)',
        cbeAccountNumber: '1000234567890',
        cbeAccountName: 'WCU Orthodox Tewahedo Fellowship',
        totalSeats: 90,
        bookedSeats: 68,
        itinerary: [
          'Day 1 (Thursday 5:00 AM): Departure from WCU Gate via Awash route',
          'Day 2 (Friday): Arrival at Kulubi, Evening Mahlet & Prayer Vigil',
          'Day 3 (Saturday): Divine Liturgy (Kidase) & Holy Communion at St. Gabriel',
          'Day 4 (Sunday): Return journey and testimony sharing',
        ],
        packingList: [
          'Netela / Gabi (ነጠላ / ጋቢ)',
          'Prayer Book (የጸሎት መጽሐፍ)',
          'Warm clothing for night vigil',
          'Personal medication & water bottle',
          'WCU Student ID card',
        ],
        coordinatorName: 'Dn. Biruk Tadesse',
        coordinatorPhone: '+251911887766',
      ),
      PilgrimageTripModel(
        id: 'trip-gishen',
        title: 'Gishen Debre Kerbe Holy Cross Pilgrimage (ግሸን ደብረ ከርቤ)',
        destination: 'Gishen Mariam Holy Cross Monastery (Wollo)',
        departureDate: DateTime.now().add(const Duration(days: 28)),
        returnDate: DateTime.now().add(const Duration(days: 32)),
        departurePoint: 'WCU Main Campus Gate 1',
        isFree: false,
        feeAmount: 850.0,
        telebirrNumber: '+251911223344',
        telebirrAccountName: 'WCU Orthodox Student Fellowship',
        cbeAccountNumber: '1000234567890',
        cbeAccountName: 'WCU Orthodox Tewahedo Fellowship',
        totalSeats: 45,
        bookedSeats: 32,
        itinerary: [
          'Day 1: Departure from Hosanna via Dessie',
          'Day 2: Ascent to Gishen Amba, veneration of True Cross (ግማደ መስቀል)',
          'Day 3: Festal Kidase & blessing from Monastery elders',
          'Day 4: Safe return to campus',
        ],
        packingList: [
          'Comfortable mountain hiking shoes',
          'Netela & prayer rope',
          'Warm jacket (High altitude)',
          'Student Fellowship Pass',
        ],
        coordinatorName: 'Yared Teshome',
        coordinatorPhone: '+251922334455',
      ),
      PilgrimageTripModel(
        id: 'trip-local',
        title: 'Local Monastery Blessing & Prayer Retreat (የአካባቢ ገዳማት ጉብኝት)',
        destination: 'St. George & Debre Tsion Local Monastery (Gurage/Hosanna)',
        departureDate: DateTime.now().add(const Duration(days: 7)),
        returnDate: DateTime.now().add(const Duration(days: 7, hours: 10)),
        departurePoint: 'WCU Library Square',
        isFree: true, // Free Fellowship Trip
        feeAmount: 0.0,
        telebirrNumber: '+251911223344',
        telebirrAccountName: 'WCU Orthodox Student Fellowship',
        cbeAccountNumber: '1000234567890',
        cbeAccountName: 'WCU Orthodox Tewahedo Fellowship',
        totalSeats: 50,
        bookedSeats: 41,
        itinerary: [
          '7:00 AM: Morning bus departure',
          '8:30 AM: Liturgy & spiritual teaching with Monastery Abbot',
          '1:00 PM: Agape fellowship lunch',
          '5:00 PM: Return to WCU dormitories',
        ],
        packingList: ['Netela (ነጠላ)', 'Notebook & Bible', 'Fellowship ID'],
        coordinatorName: 'Kidanemariam Biratu',
        coordinatorPhone: '+251933445566',
      ),
    ];

    _tripRegistrations = [
      TripRegistrationModel(
        id: 'reg-sample-1',
        tripId: 'trip-local',
        tripTitle: 'Local Monastery Blessing & Prayer Retreat',
        studentId: _currentUser.id,
        studentName: _currentUser.fullName,
        studentBaptismalName: _currentUser.baptismalName,
        studentPhone: _currentUser.phoneNumber,
        department: _currentUser.department,
        academicYear: _currentUser.academicYear,
        busNumber: 1,
        seatNumber: 14,
        feeAmount: 0.0,
        isFree: true,
        paymentMethod: PaymentMethodType.free,
        transactionReference: 'FREE-ENTRY-WCU-2026',
        paymentStatus: TripPaymentStatus.free,
        qrTicketCode: 'PILGRIM-TRIP-LOCAL-USR-CURRENT',
        registeredAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TripRegistrationModel(
        id: 'reg-sample-2',
        tripId: 'trip-kulubi',
        tripTitle: 'Annual Kulubi St. Gabriel Pilgrimage',
        studentId: 'usr-1',
        studentName: 'Dawit Alemu',
        studentBaptismalName: 'Gebre Michael',
        studentPhone: '+251911223344',
        department: 'Engineering',
        academicYear: 2,
        busNumber: 2,
        seatNumber: 22,
        feeAmount: 650.0,
        isFree: false,
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TB-982347102938',
        paymentStatus: TripPaymentStatus.verified,
        qrTicketCode: 'PILGRIM-KULU-USR-1',
        registeredAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    // 12. Student Mutual Aid & Charity Fund Mock Data
    _charityCampaigns = [
      CharityCampaignModel(
        id: 'camp-student-aid',
        title: 'Campus Student Mutual Aid & Emergency Fund (የተማሪዎች መረዳጃ ፈንድ)',
        description: 'Confidential emergency financial aid supporting fellow university students facing medical emergencies, cafeteria meal distress, and urgent travel needs.',
        targetAmount: 50000.0,
        raisedAmount: 34200.0,
        donorsCount: 142,
        deadline: DateTime.now().add(const Duration(days: 45)),
        isEmergency: true,
        category: 'Student Mutual Aid',
      ),
      CharityCampaignModel(
        id: 'camp-orphan',
        title: 'Semester Orphanage & Hospital Care Outreach (የሆስፒታልና የህፃናት ማሳደጊያ)',
        description: 'Provide hygiene supplies, books, clothing, and spiritual companionship to hospitalized patients and orphaned children in Hosanna town.',
        targetAmount: 25000.0,
        raisedAmount: 18750.0,
        donorsCount: 88,
        deadline: DateTime.now().add(const Duration(days: 20)),
        category: 'Orphanage Outreach',
      ),
    ];

    _duesPayments = [
      DuesPaymentModel(
        id: 'due-1',
        studentId: _currentUser.id,
        studentName: _currentUser.fullName,
        amount: 50.0,
        purpose: 'Monthly Fellowship Dues (የአባልነት መዋጮ)',
        paymentMethod: PaymentMethodType.telebirr,
        transactionReference: 'TB-87491028374',
        status: 'Verified',
        submittedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    _emergencyAidRequests = [
      EmergencyAidRequestModel(
        id: 'aid-1',
        studentId: 'usr-2',
        studentName: 'Hewan Bekele',
        studentBaptismalName: 'Walata Petros',
        studentPhone: '+251922334455',
        department: 'Law',
        academicYear: 2,
        category: EmergencyAidCategory.medical,
        description: 'Emergency prescription medication and medical exam cost following sudden malaria illness at WCU clinic.',
        amountRequested: 1200.0,
        status: EmergencyAidStatus.approved,
        submittedAt: DateTime.now().subtract(const Duration(days: 2)),
        adminNote: 'Approved by Charity Committee. Disbursed via Telebirr.',
      ),
    ];

    // 13. Department Mentorship Matching Mock Data
    _academicMentors = const [
      AcademicMentorModel(
        id: 'mnt-1',
        studentId: 'usr-senior-1',
        fullName: 'Abel Tesfaye',
        baptismalName: 'Gebre Kristos',
        department: 'Computer Science',
        academicYear: 4,
        specialties: ['Data Structures & Algorithms', 'Flutter & Mobile App Dev', 'Database Systems'],
        telegramHandle: '@abel_fellowship_cs',
        phoneNumber: '+251911335577',
        activeMenteesCount: 2,
        maxMentees: 3,
        isAvailable: true,
      ),
      AcademicMentorModel(
        id: 'mnt-2',
        studentId: 'usr-senior-2',
        fullName: 'Dr. (Intern) Selamawit G/Medhin',
        baptismalName: 'Walata Maryam',
        department: 'Medicine & Health Sciences',
        academicYear: 5,
        specialties: ['Anatomy & Physiology', 'Pathology & Pharmacology', 'Clinical Study Skills'],
        telegramHandle: '@selam_med_mentor',
        phoneNumber: '+251922446688',
        activeMenteesCount: 1,
        maxMentees: 3,
        isAvailable: true,
      ),
      AcademicMentorModel(
        id: 'mnt-3',
        studentId: 'usr-senior-3',
        fullName: 'Ermias Berhanu',
        baptismalName: 'Haile Georgis',
        department: 'Civil Engineering',
        academicYear: 4,
        specialties: ['Structural Analysis', 'Fluid Mechanics', 'Engineering Mathematics'],
        telegramHandle: '@ermias_civil_wcu',
        phoneNumber: '+251933557799',
        activeMenteesCount: 2,
        maxMentees: 3,
        isAvailable: true,
      ),
      AcademicMentorModel(
        id: 'mnt-4',
        studentId: 'usr-senior-4',
        fullName: 'Mahlet Assefa',
        baptismalName: 'Kirstos Samra',
        department: 'Accounting & Finance',
        academicYear: 3,
        specialties: ['Cost Accounting', 'Financial Management', 'Business Statistics'],
        telegramHandle: '@mahlet_acct',
        phoneNumber: '+251944668800',
        activeMenteesCount: 0,
        maxMentees: 3,
        isAvailable: true,
      ),
    ];

    _mentorshipRequests = [
      MentorshipRequestModel(
        id: 'mnt-req-1',
        juniorStudentId: _currentUser.id,
        juniorName: _currentUser.fullName,
        juniorBaptismalName: _currentUser.baptismalName,
        department: _currentUser.department,
        academicYear: _currentUser.academicYear,
        mentorId: 'mnt-1',
        mentorName: 'Abel Tesfaye',
        coursesNeeded: 'Data Structures and Algorithm optimization in C++ / Dart',
        status: MentorshipStatus.matched,
        requestedAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];

    // 14. Faith Challenge Trivia & Leaderboard Mock Data
    _triviaQuizzes = const [
      TriviaQuizModel(
        id: 'quiz-wk-1',
        weekNumber: 1,
        title: 'Week 1: Orthodox Dogma & The Holy Trinity',
        description: 'Test your understanding of Orthodox Christology, the Trinity, and Church Traditions.',
        timeLimitMinutes: 5,
        questions: [
          TriviaQuestionModel(
            id: 'tq-1',
            questionAmharic: 'በኢትዮጵያ ኦርቶዶክስ ተዋሕዶ ቤተክርስቲያን እምነት መሠረት እግዚአብሔር በስም፣ በአካል፣ በግብር ሦስት ሲሆን በምን አንድ ነው?',
            questionEnglish: 'According to Orthodox Dogmatics, God is three in Name, Person, and Attribute. In what is God ONE?',
            options: ['በባሕርይ፣ በህልውና እና በመለኮት (In Essence, Existence & Divinity)', 'በአካል ብቻ (In Person only)', 'በግብር ብቻ (In Attribute only)', 'በስም ብቻ (In Name only)'],
            correctOptionIndex: 0,
            explanation: 'እግዚአብሔር በአንድ መለኮት፣ በአንድ ባሕርይ፣ በአንድ ፈቃድና ሥልጣን አንዲት አምላክ ነው። (Deut 6:4, John 10:30)',
            bibleReference: 'ዘዳግም 6፥4 / ዮሐንስ 10፥30',
          ),
          TriviaQuestionModel(
            id: 'tq-2',
            questionAmharic: 'የእመቤታችን ቅድስት ድንግል ማርያም የዘወትር ውዳሴ (ውዳሴ ማርያም) የደረሰው ቅዱስ አባት ማን ይባላል?',
            questionEnglish: 'Which Saint composed the daily praises of St. Mary (Wudase Maryam)?',
            options: ['ቅዱስ ኤፍሬም ሶርያዊ (St. Ephrem the Syrian)', 'ቅዱስ ዮሐንስ አፈወርቅ (St. John Chrysostom)', 'ቅዱስ ያሬድ (St. Yared)', 'ቅዱስ ዲዮስቆሮስ (St. Dioscorus)'],
            correctOptionIndex: 0,
            explanation: 'ውዳሴ ማርያምን በሰባቱ ዕለታት የደረሰው ቅዱስ ኤፍሬም ሶርያዊ ሲሆን፣ ቅዱስ ጊዮርጊስ ዘጋስቻና ሌሎችም ተቀብለውታል።',
            bibleReference: 'ሉቃስ 1፥48',
          ),
          TriviaQuestionModel(
            id: 'tq-3',
            questionAmharic: 'በኦርቶዶክስ ተዋሕዶ ቤተክርስቲያን ከሰባቱ ምሥጢራተ ቤተክርስቲያን ውስጥ የማይደገመው የትኛው ነው?',
            questionEnglish: 'Which of the Seven Sacraments cannot be repeated once received?',
            options: ['ምሥጢረ ጥምቀት (Holy Baptism)', 'ምሥጢረ ንስሐ (Holy Confession)', 'ምሥጢረ ቁርባን (Holy Eucharist)', 'ምሥጢረ ቀንዲል (Holy Unction)'],
            correctOptionIndex: 0,
            explanation: 'ጥምቀት አንዲት ናት፤ አትደገምም። “አንድ ጌታ፥ አንድ እምነት፥ አንዲት ጥምቀት” (ኤፌሶን 4፥5)።',
            bibleReference: 'ኤፌሶን 4፥5',
          ),
          TriviaQuestionModel(
            id: 'tq-4',
            questionAmharic: 'በኢትዮጵያ ኦርቶዶክስ ተዋሕዶ የቀኖና ሕግ መሠረት በዓመት ውስጥ ስንት የአዋጅ አጽዋማት አሉ?',
            questionEnglish: 'According to the Canons of the Ethiopian Orthodox Tewahedo Church, how many official fasting seasons (አጽዋማት) exist?',
            options: ['7 አጽዋማት (Seven Fasting Seasons)', '5 አጽዋማት', '3 አጽዋማት', '10 አጽዋማት'],
            correctOptionIndex: 0,
            explanation: 'ሰባቱ አጽዋማት፡ ዐቢይ ጾም፣ ጾመ ሐዋርያት፣ ጾመ ፍልሰታ፣ ጾመ ነቢያት፣ ጾመ ገሃድ፣ ጾመ ነነዌ እና የረቡዕና ዓርብ ጾም ናቸው።',
            bibleReference: 'ፍትሐ ነገሥት አንቀጽ 15',
          ),
          TriviaQuestionModel(
            id: 'tq-5',
            questionAmharic: 'በቅዳሴ ጊዜ ኅብስቱና ወይኑ ወደ ክርስቶስ ሥጋና ደም የሚለወጥበት ምሥጢር ምን ይባላል?',
            questionEnglish: 'What is the holy transformation of the bread and wine into the Body and Blood of Christ during Liturgy called?',
            options: ['ምሥጢረ ቁርባን / ተውላጦ (Holy Eucharist / Epiclesis Transformation)', 'ምሥጢረ ክህነት', 'ምሥጢረ ሜሮን', 'ምሥጢረ ተክሊል'],
            correctOptionIndex: 0,
            explanation: 'በመንፈስ ቅዱስ ኃይልና በካህኑ ጸሎት ኅብስቱ ወደ እውነተኛው የክርስቶስ ሥጋ፥ ወይኑ ወደ እውነተኛው የክርስቶስ ደም ይለወጣል።',
            bibleReference: '1 ቆሮንቶስ 11፥23-26',
          ),
        ],
      ),
    ];

    _familyLeaderboard = [
      const FamilyLeaderboardEntry(
        familyId: 'fam-st-george',
        familyName: 'Family of St. George (የቅዱስ ጊዮርጊስ ቤተሰብ)',
        totalScore: 1420,
        participantsCount: 18,
        rank: 1,
      ),
      const FamilyLeaderboardEntry(
        familyId: 'fam-st-mary',
        familyName: "Family of St. Mary (የእመቤታችን ቤተሰብ)",
        totalScore: 1280,
        participantsCount: 16,
        rank: 2,
      ),
      const FamilyLeaderboardEntry(
        familyId: 'fam-st-michael',
        familyName: 'Family of St. Michael (የቅዱስ ሚካኤል ቤተሰብ)',
        totalScore: 1150,
        participantsCount: 14,
        rank: 3,
      ),
      const FamilyLeaderboardEntry(
        familyId: 'fam-st-tekla',
        familyName: 'Family of Abune Teklehaimanot (የአቡነ ተክለሃይማኖት ቤተሰብ)',
        totalScore: 980,
        participantsCount: 12,
        rank: 4,
      ),
    ];
  }

  @override
  void dispose() {
    _pinTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
