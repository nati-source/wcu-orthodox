part of 'fellowship_state.dart';

/// Feature slice managing Live Attendance Sessions, QR/PIN Rotation & Analytics.
class AttendanceState extends ChangeNotifier {
  final FellowshipState root;
  AttendanceState(this.root);
  void refresh() => notifyListeners();
}

mixin AttendanceStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
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
  final ValueNotifier<int> pinCountdownNotifier = ValueNotifier<int>(300);
  bool _isStartingAttendanceWindow = false;
  String? _attendanceSessionStartError;

  AttendanceSessionModel get activeSession => _activeSession;
  int get pinCountdownSeconds => pinCountdownNotifier.value;
  bool get isStartingAttendanceWindow => _isStartingAttendanceWindow;
  String? get attendanceSessionStartError => _attendanceSessionStartError;

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

  /// Starts the live attendance window with a fresh PIN and QR code.
  /// Default window is 300 seconds (5 minutes).
  Future<bool> startAttendanceWindow({int durationSeconds = 300}) async {
    if (_isStartingAttendanceWindow) return false;

    _isStartingAttendanceWindow = true;
    _attendanceSessionStartError = null;
    notifyListeners();
    _pinTimer?.cancel();
    try {
      final previousSession = _activeSession;
      if (previousSession.sessionId != 'sess-orth301') {
        final closed = previousSession.copyWith(
          isActive: false,
          isExpired: true,
        );
        // Fire-and-forget: do not block new session creation on closing the
        // previous one. A stale open session is harmless; Firestore expiry
        // timestamps enforce the actual window on the server side.
        unawaited(
          _persistAttendanceSession(
            session: closed,
            isActive: false,
            isExpired: true,
          ).then<void>((_) {}),
        );
        _activeSession = closed;
        notifyListeners();
      }

      final nextPin = (1000 + Random.secure().nextInt(9000)).toString();
      final now = DateTime.now();
      final sessionId = 'attendance-${now.microsecondsSinceEpoch}';
      // Carry the session ID in the code itself. Older scanner builds still
      // submit this entire string, which Firestore validates as the session code.
      final code = 'WCU-ATTENDANCE|$sessionId|ORTH-301-2026-$nextPin';
      final expiresAt = now.add(Duration(seconds: durationSeconds));
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
      final newSession = _activeSession.copyWith(
        sessionId: sessionId,
        rollingPin: nextPin,
        code: code,
        generatedAt: now,
        expiresAt: expiresAt,
        refreshIntervalSeconds: durationSeconds,
        totalEnrolled: enrolledStudents.length,
        enrollmentSnapshot: enrolledStudents,
        scans: const [],
        isActive: true,
        isExpired: false,
      );

      // Do not show a scannable QR until Firestore has the matching session.
      if (!await _persistAttendanceSession(
        session: newSession,
        isActive: true,
        isExpired: false,
      )) {
        _attendanceSessionStartError = 'Could not save the attendance session. Check your connection and permissions, then try again.';
        return false;
      }

      _activeSession = newSession;
      pinCountdownNotifier.value = durationSeconds;
      notifyListeners();

      _pinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (pinCountdownNotifier.value > 1) {
          pinCountdownNotifier.value = pinCountdownNotifier.value - 1;
        } else {
          timer.cancel();
          _pinTimer = null;
          expireAttendanceWindow();
        }
      });
      return true;
    } finally {
      _isStartingAttendanceWindow = false;
      notifyListeners();
    }
  }

  /// Closes the attendance window when its duration expires or admin stops it.
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
      ).then<void>((_) {}),
    );
  }

  /// Resets the session back to standby mode
  void resetAttendanceSession() {
    _pinTimer?.cancel();
    _pinTimer = null;
    pinCountdownNotifier.value = 300;
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
      ).then<void>((_) {}),
    );
  }

  Future<bool> _persistAttendanceSession({
    required AttendanceSessionModel session,
    required bool isActive,
    required bool isExpired,
  }) async {
    // Keep local/demo and unit-test sessions usable when Firebase was not
    // initialized. There is no remote QR session to wait for in that mode.
    if (!_firestoreService.isAvailable) return true;

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
      return true;
    } catch (e) {
      debugPrint('Firestore attendance session persist error: $e');
      return false;
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
    String? sessionId,
  }) async {
    final cleanInput = enteredPinOrCode.trim().toUpperCase();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty || cleanInput.isEmpty) {
      // Local/demo fallback when unauthenticated or offline
      return checkInStudent(
        studentId: _currentUser.id,
        enteredPinOrCode: cleanInput,
        method: method,
      );
    }

    // Try to find the session to write to. For QR scans, the code contains
    // the session code so we try the active session or extract session info from the QR.
    // Firestore rules will do the authoritative validation.
    String targetSessionId = sessionId?.trim() ?? '';
    if (targetSessionId.isEmpty) {
      try {
        final querySnap = await FirebaseFirestore.instance
            .collection('attendance_session_status')
            .orderBy('generatedAt', descending: true)
            .limit(10)
            .get(const GetOptions(source: Source.server));
        QueryDocumentSnapshot<Map<String, dynamic>>? activeDoc;
        for (final doc in querySnap.docs) {
          if (doc.data()['isActive'] == true &&
              doc.data()['isExpired'] != true) {
            activeDoc = doc;
            break;
          }
        }
        if (activeDoc != null) {
          targetSessionId = activeDoc.id;
          final data = activeDoc.data();
          DateTime? exp;
          if (data['expiresAt'] is Timestamp) {
            exp = (data['expiresAt'] as Timestamp).toDate();
          }
          _activeSession = _activeSession.copyWith(
            sessionId: targetSessionId,
            isActive: true,
            isExpired: false,
            expiresAt: exp,
          );
        } else {
          targetSessionId = '';
        }
      } catch (e) {
        debugPrint('submitAttendanceCheckIn fallback session query: $e');
        return false;
      }
    }

    if (targetSessionId.isEmpty || targetSessionId == 'sess-orth301') {
      // Local/demo fallback session
      return checkInStudent(
        studentId: uid,
        enteredPinOrCode: cleanInput,
        method: method,
      );
    }

    final scanRef = FirebaseFirestore.instance
        .collection('attendance_sessions')
        .doc(targetSessionId)
        .collection('scans')
        .doc(uid);
    try {
      final existing = await scanRef.get();
      if (existing.exists) {
        final storedPin = (existing.data()?['enteredPin'] as String?)?.toUpperCase() ?? '';
        final matchesStored = storedPin == cleanInput ||
            (cleanInput.length == 4 && storedPin.endsWith(cleanInput)) ||
            (storedPin.length == 4 && cleanInput.endsWith(storedPin));
        if (matchesStored) {
          return true; // Already checked in with this valid PIN
        }
        // If a different/wrong PIN was entered, do NOT report success
        return false;
      }

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
