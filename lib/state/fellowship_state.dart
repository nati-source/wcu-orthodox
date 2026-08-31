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
  // DOMAIN 7: VOLUNTARY SERVING AREAS
  // ----------------------------------------------------
  List<MinistryModel> _ministries = [];
  List<VolunteerApplicationModel> _volunteerApplications = [];

  List<MinistryModel> get ministries => List.unmodifiable(_ministries);
  List<VolunteerApplicationModel> get volunteerApplications => List.unmodifiable(_volunteerApplications);

  void submitMinistryApplication({
    required String ministryId,
    required String reason,
    required String experience,
    required String availability,
  }) {
    final min = _ministries.firstWhere((m) => m.id == ministryId);
    final application = VolunteerApplicationModel(
      id: 'app-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentDept: _currentUser.department,
      studentPhone: _currentUser.phoneNumber,
      ministryId: ministryId,
      ministryTitle: min.title,
      reason: reason,
      experience: experience,
      availability: availability,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
    );

    _volunteerApplications.insert(0, application);
    _currentUser = _currentUser.copyWith(ministryStatus: 'Application Pending (${min.title})');
    notifyListeners();
  }

  void approveVolunteerApplication(String applicationId) {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      final app = _volunteerApplications[index].copyWith(status: ApplicationStatus.approved);
      _volunteerApplications[index] = app;

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

  void rejectVolunteerApplication(String applicationId) {
    final index = _volunteerApplications.indexWhere((a) => a.id == applicationId);
    if (index != -1) {
      _volunteerApplications[index] = _volunteerApplications[index].copyWith(status: ApplicationStatus.rejected);
      notifyListeners();
    }
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

    // 7. Voluntary Serving Areas
    _ministries = [
      MinistryModel(
        id: 'min-choir',
        title: 'Yaredic Choir (Mezmur)',
        iconName: 'music_note',
        description: 'Serve through ancient Yaredic hymns, chants, drum (Kebero) and sistrum (Senasel) for liturgies and university evangelism.',
        teamLead: 'Dn. Henok Teshome',
        openSlots: 6,
        activeCount: 28,
        tags: ['Mezmur', 'Chants', 'Spiritual Songs'],
      ),
      MinistryModel(
        id: 'min-diaconia',
        title: 'Charity & Diaconia (ምጽዋት)',
        iconName: 'volunteer_activism',
        description: 'Visit hospitalized fellows, prepare meals for needy students on campus, and organize semester clothes/book donation drives.',
        teamLead: 'Wolete Gabriel Almaz',
        openSlots: 10,
        activeCount: 35,
        tags: ['Outreach', 'Care', 'Student Support'],
      ),
      MinistryModel(
        id: 'min-hospitality',
        title: 'Hospitality & Welcoming',
        iconName: 'handshake',
        description: 'Welcome new batch freshmen, coordinate fellowship Agape love-feasts, and provide orientation for new university arrivals.',
        teamLead: 'Kidanemariam Biratu',
        openSlots: 4,
        activeCount: 18,
        tags: ['Orientation', 'Agape', 'Events'],
      ),
      MinistryModel(
        id: 'min-media',
        title: 'Media, Sound & Tech',
        iconName: 'camera_alt',
        description: 'Manage live streaming, soundboard setup, Telegram channel announcements, digital library links, and photography.',
        teamLead: 'Alex Smith (Gebre Sellassie)',
        openSlots: 3,
        activeCount: 12,
        tags: ['Tech', 'Audio/Visual', 'Content'],
      ),
      MinistryModel(
        id: 'min-altar',
        title: 'Altar & Liturgical Care',
        iconName: 'church',
        description: 'Assist in sanctuary preparation, vestment care, candle service, and incense preparation for weekly Kidase.',
        teamLead: 'Dn. Ephrem Tadesse',
        openSlots: 5,
        activeCount: 15,
        tags: ['Liturgy', 'Altar Server', 'Sacred Care'],
      ),
    ];

    // Sample Volunteer Application
    _volunteerApplications = [
      VolunteerApplicationModel(
        id: 'app-sample-1',
        studentId: 'usr-1',
        studentName: 'Dawit Alemu',
        studentBaptismalName: 'Gebre Michael',
        studentDept: 'Engineering',
        studentPhone: '+251911223344',
        ministryId: 'min-media',
        ministryTitle: 'Media, Sound & Tech',
        reason: 'I have experience in audio editing and video streaming for campus fellowship.',
        experience: '2 years campus media volunteer',
        availability: 'Weekends & Friday evenings',
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      VolunteerApplicationModel(
        id: 'app-sample-2',
        studentId: 'usr-2',
        studentName: 'Hewan Bekele',
        studentBaptismalName: 'Walata Petros',
        studentDept: 'Law',
        studentPhone: '+251922334455',
        ministryId: 'min-hospitality',
        ministryTitle: 'Hospitality & Welcoming',
        reason: 'Eager to welcome freshmen and organize spiritual orientation seminars.',
        experience: 'Freshman orientation guide',
        availability: 'Tuesdays & Sundays',
        status: ApplicationStatus.approved,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
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
