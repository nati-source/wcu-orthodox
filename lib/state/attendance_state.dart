part of 'fellowship_state.dart';

/// Feature slice managing Live Attendance Sessions, QR/PIN Rotation & Analytics.
class AttendanceState extends ChangeNotifier {
  final FellowshipState root;
  AttendanceState(this.root);
  void refresh() => notifyListeners();
}

mixin AttendanceStateMixin on ChangeNotifier {
  List<UserModel> get _allStudents;
  UserModel get _currentUser;
  List<RoadmapPhaseModel> get _roadmaps;

  // ----------------------------------------------------
  // DOMAIN 3: ATTENDANCE & ANALYTICS PIPELINE
  // ----------------------------------------------------
  AttendanceSessionModel _activeSession = AttendanceSessionModel(
    sessionId: 'sess-orth301',
    courseName: 'Patristics & Church History (የነገረ አበው ትምህርት)',
    courseCode: 'ORTH-301: Patristics & Church History',
    faculty: 'Orthodox Fellowship Education Department',
    code: 'ORTH-301-STANDBY',
    rollingPin: '----',
    generatedAt: DateTime.now(),
    refreshIntervalSeconds: 30,
    totalEnrolled: 0,
    scans: const [],
    isActive: false,
    isExpired: false,
  );
  Timer? _pinTimer;
  final ValueNotifier<int> pinCountdownNotifier = ValueNotifier<int>(30);

  AttendanceSessionModel get activeSession => _activeSession;
  int get pinCountdownSeconds => pinCountdownNotifier.value;

  // Analytics Metrics
  int get totalRegisteredStudents => _allStudents.length;
  double get averageAttendanceRate {
    final recordedStudents = _allStudents
        .where((student) => student.hasAttendanceData)
        .toList();
    if (recordedStudents.isEmpty) return 0.0;
    final total = recordedStudents.fold<double>(
      0.0,
      (sum, s) => sum + s.attendancePercentage,
    );
    return double.parse((total / recordedStudents.length).toStringAsFixed(1));
  }

  int get activeRoadmapsCount => _roadmaps.length;
  int get atRiskStudentsCount => _allStudents
      .where((s) => s.hasAttendanceData && s.attendancePercentage < 75.0)
      .length;

  List<UserModel> get atRiskStudents => _allStudents
      .where((s) => s.hasAttendanceData && s.attendancePercentage < 75.0)
      .toList();

  /// Starts the 30-second live attendance window with a fresh PIN and QR code.
  /// Once the 30 seconds elapse, the session automatically expires and stops
  /// accepting check-ins until the admin starts the next round.
  void startAttendanceWindow({int durationSeconds = 30}) {
    _pinTimer?.cancel();
    final nextPin = (1000 + Random.secure().nextInt(9000)).toString();
    final code = 'ORTH-301-2026-$nextPin';
    final now = DateTime.now();
    final expiresAt = now.add(Duration(seconds: durationSeconds));
    final previousSession = _activeSession;
    if (previousSession.expiresAt != null ||
        previousSession.sessionId != 'sess-orth301') {
      unawaited(
        _persistAttendanceSession(
          session: previousSession.copyWith(isActive: false, isExpired: true),
          isActive: false,
          isExpired: true,
        ),
      );
    }
    final enrolledStudents = _allStudents
        .where(
          (student) => student.role == UserRole.student && student.isApproved,
        )
        .map(
          (student) => AttendanceEnrollmentSnapshot(
            studentId: student.id,
            department: student.department.trim().isEmpty
                ? 'General'
                : student.department.trim(),
          ),
        )
        .toList();

    pinCountdownNotifier.value = durationSeconds;
    _activeSession = _activeSession.copyWith(
      sessionId: 'attendance-${now.microsecondsSinceEpoch}',
      rollingPin: nextPin,
      code: code,
      generatedAt: now,
      expiresAt: expiresAt,
      totalEnrolled: enrolledStudents.length,
      enrollmentSnapshot: enrolledStudents,
      isActive: true,
      isExpired: false,
    );
    notifyListeners();

    unawaited(
      _persistAttendanceSession(
        session: _activeSession,
        isActive: true,
        isExpired: false,
      ),
    );

    _pinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (pinCountdownNotifier.value > 1) {
        pinCountdownNotifier.value = pinCountdownNotifier.value - 1;
      } else {
        timer.cancel();
        _pinTimer = null;
        expireAttendanceWindow();
      }
    });
  }

  /// Closes the attendance window when 30s expires or when admin clicks Stop.
  void expireAttendanceWindow() {
    _pinTimer?.cancel();
    _pinTimer = null;
    pinCountdownNotifier.value = 0;
    _activeSession = _activeSession.copyWith(isActive: false, isExpired: true);
    notifyListeners();

    unawaited(
      _persistAttendanceSession(
        session: _activeSession,
        isActive: false,
        isExpired: true,
      ),
    );
  }

  /// Resets the session back to standby mode
  void resetAttendanceSession() {
    _pinTimer?.cancel();
    _pinTimer = null;
    pinCountdownNotifier.value = 30;
    _activeSession = _activeSession.copyWith(
      rollingPin: '----',
      code: 'ORTH-301-STANDBY',
      isActive: false,
      isExpired: false,
    );
    notifyListeners();

    unawaited(
      _persistAttendanceSession(
        session: _activeSession,
        isActive: false,
        isExpired: false,
      ),
    );
  }

  Future<void> _persistAttendanceSession({
    required AttendanceSessionModel session,
    required bool isActive,
    required bool isExpired,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final privateRef = firestore
          .collection('attendance_sessions')
          .doc(session.sessionId);
      final statusRef = firestore
          .collection('attendance_session_status')
          .doc(session.sessionId);
      final common = <String, dynamic>{
        'sessionId': session.sessionId,
        'courseName': session.courseName,
        'courseCode': session.courseCode,
        'faculty': session.faculty,
        'generatedAt': Timestamp.fromDate(session.generatedAt),
        'expiresAt': session.expiresAt == null
            ? null
            : Timestamp.fromDate(session.expiresAt!),
        'isActive': isActive,
        'isExpired': isExpired,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final batch = firestore.batch();
      batch.set(privateRef, {
        ...common,
        'totalEnrolled': session.totalEnrolled,
        'enrollmentSnapshot': session.enrollmentSnapshot
            .map((student) => student.toMap())
            .toList(),
        'rollingPin': isActive ? session.rollingPin : '----',
        'code': isActive ? session.code : 'ORTH-301-STANDBY',
      }, SetOptions(merge: true));
      batch.set(statusRef, common, SetOptions(merge: true));
      await batch.commit();
    } catch (e) {
      debugPrint('Firestore attendance session persist error: $e');
    }
  }

  /// Clears recent scans (for admin testing or beginning a new lecture)
  Future<void> clearAttendanceScans() async {
    _activeSession = _activeSession.copyWith(scans: []);
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(_activeSession.sessionId)
          .collection('scans')
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Firestore clearAttendanceScans notice: $e');
    }
  }

  bool checkInStudent({
    required String studentId,
    required String enteredPinOrCode,
    AttendanceCheckInMethod method = AttendanceCheckInMethod.pin,
  }) {
    // 1. Session must be active and not expired
    if (!_activeSession.isActive || _activeSession.isExpired) {
      return false;
    }

    final cleanInput = enteredPinOrCode.trim().toUpperCase();
    final isValidPin = cleanInput == _activeSession.rollingPin;
    final isValidCode =
        cleanInput == _activeSession.code ||
        cleanInput.contains(_activeSession.rollingPin);

    if (isValidPin || isValidCode) {
      // Use authenticated UID if available to satisfy Firestore security rules (scanId == request.auth.uid)
      String? authUid;
      try {
        authUid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      final effectiveStudentId = (authUid != null && authUid.isNotEmpty)
          ? authUid
          : studentId;

      final student = _allStudents.firstWhere(
        (s) => s.id == studentId || s.id == effectiveStudentId,
        orElse: () => _currentUser,
      );

      // Check if already checked in
      final alreadyIn = _activeSession.scans.any(
        (s) => s.studentId == effectiveStudentId || s.studentId == student.id,
      );
      if (!alreadyIn) {
        final studentName = student.fullName.isNotEmpty
            ? student.fullName
            : (_currentUser.fullName.isNotEmpty
                  ? _currentUser.fullName
                  : 'Fellowship Student');

        final now = DateTime.now();
        // Calculate attendance status based on session start time and grace period (15 minutes)
        final sessionStart = _activeSession.generatedAt;
        final int elapsedMinutes = now.difference(sessionStart).inMinutes;
        final AttendanceStatus calculatedStatus = (elapsedMinutes > 15)
            ? AttendanceStatus.late
            : AttendanceStatus.present;

        final newRecord = AttendanceRecordModel(
          id: 'att-${now.millisecondsSinceEpoch}',
          studentId: effectiveStudentId,
          studentName: studentName,
          timestamp: now,
          status: calculatedStatus,
          method: method,
          courseName: _activeSession.courseName,
        );

        final updatedScans = List<AttendanceRecordModel>.from(
          _activeSession.scans,
        )..insert(0, newRecord);
        _activeSession = _activeSession.copyWith(scans: updatedScans);
        notifyListeners();

        return true;
      }
      return true; // Already checked in — still report success
    }
    return false;
  }

  /// Writes an authenticated scan and lets Firestore rules validate the secret
  /// code, session expiry, and one-scan-per-student constraint.
  Future<bool> submitAttendanceCheckIn({
    required String enteredPinOrCode,
    required AttendanceCheckInMethod method,
  }) async {
    final cleanInput = enteredPinOrCode.trim().toUpperCase();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final expiresAt = _activeSession.expiresAt;
    if (uid == null ||
        uid.isEmpty ||
        cleanInput.isEmpty ||
        !_activeSession.isActive ||
        _activeSession.isExpired ||
        expiresAt == null ||
        !expiresAt.isAfter(DateTime.now())) {
      return false;
    }

    final scanRef = FirebaseFirestore.instance
        .collection('attendance_sessions')
        .doc(_activeSession.sessionId)
        .collection('scans')
        .doc(uid);
    try {
      final existing = await scanRef.get();
      if (existing.exists) return true;

      final now = DateTime.now();
      final studentName =
          _currentUser.id == uid && _currentUser.fullName.trim().isNotEmpty
          ? _currentUser.fullName.trim()
          : 'Fellowship Student';
      await scanRef.set({
        'studentId': uid,
        'studentName': studentName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': AttendanceStatus.present.name,
        'method': method.name,
        'courseName': _activeSession.courseName,
        'enteredPin': cleanInput,
      });

      final record = AttendanceRecordModel(
        id: uid,
        studentId: uid,
        studentName: studentName,
        timestamp: now,
        status: AttendanceStatus.present,
        method: method,
        courseName: _activeSession.courseName,
      );
      _activeSession = _activeSession.copyWith(
        scans: [
          record,
          ..._activeSession.scans.where((scan) => scan.studentId != uid),
        ],
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Firestore attendance check-in rejected: $e');
      return false;
    }
  }
}
