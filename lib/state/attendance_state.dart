part of 'fellowship_state.dart';

/// Feature slice managing Live Attendance Sessions, QR/PIN Rotation & Analytics.
class AttendanceState extends ChangeNotifier {
  final FellowshipState root; AttendanceState(this.root);
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
    code: 'ORTH-301-2026-8421',
    rollingPin: '8421',
    generatedAt: DateTime.now(),
    refreshIntervalSeconds: 30,
    totalEnrolled: 50,
    scans: const [],
  );
  Timer? _pinTimer;
  final ValueNotifier<int> pinCountdownNotifier = ValueNotifier<int>(30);

  AttendanceSessionModel get activeSession => _activeSession;
  int get pinCountdownSeconds => pinCountdownNotifier.value;

  // Analytics Metrics
  int get totalRegisteredStudents => _allStudents.length;
  double get averageAttendanceRate {
    if (_allStudents.isEmpty) return 0.0;
    final total = _allStudents.fold<double>(0.0, (sum, s) => sum + s.attendancePercentage);
    return double.parse((total / _allStudents.length).toStringAsFixed(1));
  }
  int get activeRoadmapsCount => _roadmaps.length;
  int get atRiskStudentsCount => _allStudents.where((s) => s.attendancePercentage < 75.0).length;

  List<UserModel> get atRiskStudents => _allStudents.where((s) => s.attendancePercentage < 75.0).toList();

  void _startPinRotation() {
    _pinTimer?.cancel();
    pinCountdownNotifier.value = 30;
    _pinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (pinCountdownNotifier.value > 1) {
        pinCountdownNotifier.value = pinCountdownNotifier.value - 1;
        // Scoped update: Does not trigger full-app rebuilds
      } else {
        pinCountdownNotifier.value = 30;
        _rotateSessionCode();
      }
    });
  }

  void _rotateSessionCode() {
    final nextPin = (1000 + Random.secure().nextInt(9000)).toString();
    _activeSession = _activeSession.copyWith(
      rollingPin: nextPin,
      code: 'ORTH-301-2026-$nextPin',
      generatedAt: DateTime.now(),
    );
    notifyListeners();

    // Persist the rolling PIN update to Firestore so the admin live screen
    // and any other devices always see the current active code in real-time.
    try {
      FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(_activeSession.sessionId)
          .set({
            'rollingPin': nextPin,
            'code': _activeSession.code,
            'generatedAt': DateTime.now().toIso8601String(),
            'isActive': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore _rotateSessionCode notice: $e');
    }
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
      // Use authenticated UID if available to satisfy Firestore security rules (scanId == request.auth.uid)
      String? authUid;
      try {
        authUid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      final effectiveStudentId = (authUid != null && authUid.isNotEmpty) ? authUid : studentId;

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
            : (_currentUser.fullName.isNotEmpty ? _currentUser.fullName : 'Fellowship Student');

        final newRecord = AttendanceRecordModel(
          id: 'att-${DateTime.now().millisecondsSinceEpoch}',
          studentId: effectiveStudentId,
          studentName: studentName,
          timestamp: DateTime.now(),
          status: DateTime.now().minute % 10 > 7 ? AttendanceStatus.late : AttendanceStatus.present,
          method: method,
          courseName: _activeSession.courseName,
        );

        final updatedScans = List<AttendanceRecordModel>.from(_activeSession.scans)..insert(0, newRecord);
        _activeSession = _activeSession.copyWith(scans: updatedScans);
        notifyListeners();

        // Persist scan to Firestore subcollection using effective student ID
        try {
          FirebaseFirestore.instance
              .collection('attendance_sessions')
              .doc(_activeSession.sessionId)
              .collection('scans')
              .doc(effectiveStudentId)
              .set({
                'studentId': newRecord.studentId,
                'studentName': newRecord.studentName,
                'timestamp': newRecord.timestamp.toIso8601String(),
                'status': newRecord.status.name,
                'method': newRecord.method.name,
                'courseName': newRecord.courseName,
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore checkInStudent notice: $e');
        }

        return true;
      }
      return true; // Already checked in — still report success
    }
    return false;
  }

}
