part of 'fellowship_state.dart';

/// Feature slice managing Church Programs, Liturgy Countdown, Emergency Broadcasts & Announcements.
class BroadcastState extends ChangeNotifier {
  final FellowshipState root; BroadcastState(this.root);
  void refresh() => notifyListeners();
}

mixin BroadcastStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
  bool get isAdmin;

  // ----------------------------------------------------
  // DOMAIN 6: REAL-TIME CHURCH PROGRAMS, LITURGY & ANNOUNCEMENTS
  // ----------------------------------------------------
  List<ChurchProgramModel> _programs = [];
  Timer? _countdownTimer;
  final ValueNotifier<Duration> liturgyCountdownNotifier =
      ValueNotifier<Duration>(const Duration(hours: 2, minutes: 15, seconds: 45));
  ChurchProgramModel? _latestEmergencyBroadcast;
  final Set<String> _dismissedEmergencyIds = {};
  // General announcements from the 'announcements' collection (admin-authored).
  List<Map<String, dynamic>> _announcements = [];

  List<ChurchProgramModel> get programs => List.unmodifiable(_programs);
  Duration get liturgyCountdown => liturgyCountdownNotifier.value;
  ChurchProgramModel? get latestEmergencyBroadcast => _latestEmergencyBroadcast;
  /// Live general announcements from Firestore, ordered most-recent first.
  List<Map<String, dynamic>> get announcements => List.unmodifiable(_announcements);

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _tickCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    final now = DateTime.now();
    final upcoming = _programs.where((p) => p.dateTime.isAfter(now) && !p.isEmergency).toList();
    if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final nextProgram = upcoming.firstWhere(
        (p) => p.category.toLowerCase().contains('liturgy') || p.category.toLowerCase().contains('ቅዳሴ') || p.title.toLowerCase().contains('liturgy'),
        orElse: () => upcoming.first,
      );
      liturgyCountdownNotifier.value = nextProgram.dateTime.difference(now);
    } else {
      if (liturgyCountdownNotifier.value.inSeconds > 0) {
        liturgyCountdownNotifier.value =
            liturgyCountdownNotifier.value - const Duration(seconds: 1);
      }
    }
  }

  Future<void> scheduleChurchProgram({
    required String title,
    required String description,
    required String churchName,
    required DateTime dateTime,
    String category = 'Liturgy',
    bool reminderEnabled = true,
  }) async {
    final remaining = dateTime.isAfter(DateTime.now())
        ? dateTime.difference(DateTime.now())
        : Duration.zero;

    final program = ChurchProgramModel(
      id: 'prg-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      churchName: churchName.isNotEmpty ? churchName : "St. Mary's Orthodox Church",
      dateTime: dateTime,
      initialDurationRemaining: remaining,
      isEmergency: false,
      reminderEnabled: reminderEnabled,
      description: description,
      category: category,
    );

    _programs.insert(0, program);
    _tickCountdown();
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('church_programs').doc(program.id).set(
        program.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore scheduleChurchProgram error: $e');
    }
  }

  void broadcastEmergency({
    required String title,
    required String description,
    String churchName = "St. Mary's Orthodox Church",
    String category = 'Emergency Alert',
  }) {
    final broadcast = ChurchProgramModel(
      id: 'alert-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      churchName: churchName.isNotEmpty ? churchName : "St. Mary's Orthodox Church",
      dateTime: DateTime.now(),
      initialDurationRemaining: Duration.zero,
      isEmergency: true,
      description: description,
      category: category,
    );
    _dismissedEmergencyIds.remove(broadcast.id);
    _latestEmergencyBroadcast = broadcast;
    _programs.insert(0, broadcast);
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('church_programs').doc(broadcast.id).set(
        broadcast.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore church_programs broadcast notice: $e');
    }
  }

  void dismissEmergencyBanner([String? alertId]) {
    final id = alertId ?? _latestEmergencyBroadcast?.id;
    if (id != null) {
      _dismissedEmergencyIds.add(id);
    }
    _latestEmergencyBroadcast = null;
    notifyListeners();
  }

  Future<void> deleteEmergencyBroadcast(String broadcastId) async {
    _programs.removeWhere((p) => p.id == broadcastId);
    if (_latestEmergencyBroadcast?.id == broadcastId) {
      _latestEmergencyBroadcast = null;
      final remaining = _programs.where((p) => p.isEmergency).toList();
      if (remaining.isNotEmpty) {
        remaining.sort((a, b) => b.dateTime.compareTo(a.dateTime));
        final nextAlert = remaining.first;
        if (!_dismissedEmergencyIds.contains(nextAlert.id)) {
          _latestEmergencyBroadcast = nextAlert;
        }
      }
    }
    notifyListeners();

    try {
      await _firestoreService.deleteChurchProgram(broadcastId);
      await FirebaseFirestore.instance.collection('church_programs').doc(broadcastId).delete();
      debugPrint('Emergency broadcast deleted: $broadcastId');
    } catch (e) {
      debugPrint('Firestore deleteEmergencyBroadcast notice: $e');
    }
  }

  void postEmergencyScheduleBroadcast({
    required String title,
    required String description,
    required String churchName,
  }) {
    if (!isAdmin) return;
    broadcastEmergency(title: title, description: description, churchName: churchName, category: 'Schedule Change');
  }

  // ----------------------------------------------------
  // ANNOUNCEMENTS (general notice board — 'announcements' collection)
  // ----------------------------------------------------

  /// Creates a general announcement in the 'announcements' Firestore collection.
  /// Announcements are distinct from emergency broadcasts: they are pinned
  /// notices (event summaries, news, policy updates) with a category tag.
  Future<void> createGeneralAnnouncement({
    required String title,
    required String content,
    required String authorName,
    required String category,
    String? imageUrl,
    bool isUrgent = false,
  }) async {
    if (!isAdmin) return;
    final newAnnouncement = <String, dynamic>{
      'title': title,
      'content': content,
      'authorName': authorName,
      'category': category,
      'imageUrl': imageUrl,
      'isUrgent': isUrgent,
      'createdAt': DateTime.now().toIso8601String(),
    };
    // Optimistically insert at top of local list
    _announcements.insert(0, newAnnouncement);
    notifyListeners();

    try {
      final docRef = await FirebaseFirestore.instance.collection('announcements').add({
        ...newAnnouncement,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Back-fill the generated doc id into our local list entry
      final idx = _announcements.indexWhere((a) => a['title'] == title && a['id'] == null);
      if (idx >= 0) {
        _announcements[idx] = {..._announcements[idx], 'id': docRef.id};
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firestore createGeneralAnnouncement notice: $e');
    }
  }

  /// Deletes a general announcement by its Firestore document id.
  Future<void> deleteAnnouncement(String docId) async {
    if (!isAdmin) return;
    _announcements.removeWhere((a) => a['id'] == docId);
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
    } catch (e) {
      debugPrint('Firestore deleteAnnouncement notice: $e');
    }
  }

}
