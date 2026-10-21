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
      ValueNotifier<Duration>(Duration.zero);
  ChurchProgramModel? _latestEmergencyBroadcast;
  final Set<String> _dismissedEmergencyIds = {};
  final Set<String> _notified60mIds = {};
  final Set<String> _notified30mIds = {};
  final Set<String> _notified15mIds = {};
  final Set<String> _notifiedHalfTimeIds = {};
  final Set<String> _notified7mIds = {};
  final Set<String> _notifiedProgramCountdownIds = {};
  bool _notifiedLiturgy60m = false;
  bool _notifiedLiturgy30m = false;
  bool _notifiedLiturgy15m = false;
  bool _notifiedLiturgy7m = false;
  bool _notifiedLiturgyFinished = false;
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

    // Check all scheduled programs for countdown intervals: 1 hour, 30 min, 15 min, 7 min, half-time & Time is Up
    for (final p in _programs) {
      if (p.isEmergency) continue;
      final diff = p.dateTime.difference(now);

      // 1. 1 Hour Remaining Alert (when diff is between 55m and 60m)
      if (diff.inMinutes <= 60 && diff.inMinutes >= 55) {
        if (!_notified60mIds.contains(p.id)) {
          _notified60mIds.add(p.id);
          NotificationService.instance.showSystemNotification(
            id: (p.id.hashCode & 0x7FFFFFFF) % 100000 + 60000,
            title: '🔔 1 Hour Remaining • 1 ሰዓት ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ1 ሰዓት ውስጥ ይጀምራል። (Starts in 60 mins)',
          );
          NotificationService.showLocalInAppNotification(
            title: '🔔 1 Hour Remaining • 1 ሰዓት ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ1 ሰዓት ውስጥ ይጀምራል። (Starts in 60 mins)',
            icon: Icons.access_time_filled,
            iconColor: const Color(0xFFC5A059),
          );
        }
      }

      // 2. 30 Minutes Remaining Alert (when diff is between 27m and 30m)
      if (diff.inMinutes <= 30 && diff.inMinutes >= 27) {
        if (!_notified30mIds.contains(p.id)) {
          _notified30mIds.add(p.id);
          NotificationService.instance.showSystemNotification(
            id: (p.id.hashCode & 0x7FFFFFFF) % 100000 + 30000,
            title: '🔔 30 Minutes Remaining • 30 ደቂቃ ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ30 ደቂቃ ውስጥ ይጀምራል። (Starts in 30 mins)',
          );
          NotificationService.showLocalInAppNotification(
            title: '🔔 30 Minutes Remaining • 30 ደቂቃ ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ30 ደቂቃ ውስጥ ይጀምራል። (Starts in 30 mins)',
            icon: Icons.timer,
            iconColor: const Color(0xFFF59E0B),
          );
        }
      }

      // 3. 15 Minutes Remaining Alert (when diff is between 13m and 15m)
      if (diff.inMinutes <= 15 && diff.inMinutes >= 13) {
        if (!_notified15mIds.contains(p.id)) {
          _notified15mIds.add(p.id);
          NotificationService.instance.showSystemNotification(
            id: (p.id.hashCode & 0x7FFFFFFF) % 100000 + 15000,
            title: '🔔 15 Minutes Remaining • 15 ደቂቃ ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ15 ደቂቃ ውስጥ ይጀምራል። Church doors are open.',
          );
          NotificationService.showLocalInAppNotification(
            title: '🔔 15 Minutes Remaining • 15 ደቂቃ ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ15 ደቂቃ ውስጥ ይጀምራል። Church doors are open.',
            icon: Icons.notifications_active,
            iconColor: const Color(0xFF10B981),
          );
        }
      }

      // 4. 7 Minutes Remaining Alert (half of 15m)
      if (diff.inMinutes <= 7 && diff.inMinutes >= 5) {
        if (!_notified7mIds.contains(p.id)) {
          _notified7mIds.add(p.id);
          NotificationService.instance.showSystemNotification(
            id: (p.id.hashCode & 0x7FFFFFFF) % 100000 + 7000,
            title: '🔔 7 Minutes Remaining • 7 ደቂቃ ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ7 ደቂቃ ውስጥ ይጀምራል። (Starts in 7 mins)',
          );
          NotificationService.showLocalInAppNotification(
            title: '🔔 7 Minutes Remaining • 7 ደቂቃ ቀርቷል',
            body: '"${p.title}" በ ${p.churchName} በ7 ደቂቃ ውስጥ ይጀምራል።',
            icon: Icons.timelapse,
            iconColor: const Color(0xFF10B981),
          );
        }
      }

      // 5. Custom Half-time Alert for short programs (e.g. 2 to 20 minute test programs)
      if (p.initialDurationRemaining.inSeconds > 0 && p.initialDurationRemaining.inMinutes < 30) {
        final halfSecs = p.initialDurationRemaining.inSeconds ~/ 2;
        if (diff.inSeconds <= halfSecs && diff.inSeconds >= halfSecs - 25) {
          if (!_notifiedHalfTimeIds.contains(p.id)) {
            _notifiedHalfTimeIds.add(p.id);
            final remainingDisplay = diff.inMinutes > 0 ? '${diff.inMinutes}m' : '${diff.inSeconds}s';
            NotificationService.instance.showSystemNotification(
              id: (p.id.hashCode & 0x7FFFFFFF) % 100000 + 50000,
              title: '🔔 Half Time Remaining • ግማሽ ሰዓት ቀርቷል',
              body: '"${p.title}" begins shortly — only $remainingDisplay remaining!',
            );
          }
        }
      }

      // 6. TIME IS UP Alert (when countdown reaches 0: diff.inSeconds <= 0 and >= -180s)
      if (diff.inSeconds <= 0 && diff.inSeconds >= -180) {
        if (!_notifiedProgramCountdownIds.contains(p.id)) {
          _notifiedProgramCountdownIds.add(p.id);
          NotificationService.instance.showSystemNotification(
            id: (p.id.hashCode & 0x7FFFFFFF) % 100000 + 90000,
            title: '🔔 ሰዓቱ ደርሷል! Time is Up • Program Started',
            body: '"${p.title}" በ ${p.churchName} አሁን ተጀምሯል! እንኳን አደረሳችሁ!',
          );
          NotificationService.showLocalInAppNotification(
            title: '🔔 የ${p.category} ሰዓት ደርሷል! (Program Started)',
            body: '"${p.title}" በ ${p.churchName} አሁን ተጀምሯል። እንኳን አደረሳችሁ!',
            icon: Icons.church,
            iconColor: const Color(0xFFC5A059),
          );
        }
      }
    }

    final upcoming = _programs.where((p) => p.dateTime.isAfter(now) && !p.isEmergency).toList();
    if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      final nextProgram = upcoming.firstWhere(
        (p) => p.category.toLowerCase().contains('liturgy') || p.category.toLowerCase().contains('ቅዳሴ') || p.title.toLowerCase().contains('liturgy'),
        orElse: () => upcoming.first,
      );
      final remaining = nextProgram.dateTime.difference(now);
      liturgyCountdownNotifier.value = remaining;

      // Liturgy specific intervals
      if (remaining.inMinutes <= 60 && remaining.inMinutes >= 55 && !_notifiedLiturgy60m) {
        _notifiedLiturgy60m = true;
        NotificationService.instance.showSystemNotification(
          id: 70001,
          title: '🔔 Holy Liturgy in 1 Hour • የቅዳሴ 1 ሰዓት ቀርቷል',
          body: 'Sunday Holy Liturgy at St. Mary\'s Orthodox Church begins in 60 minutes.',
        );
      }
      if (remaining.inMinutes <= 30 && remaining.inMinutes >= 27 && !_notifiedLiturgy30m) {
        _notifiedLiturgy30m = true;
        NotificationService.instance.showSystemNotification(
          id: 70002,
          title: '🔔 Holy Liturgy in 30 Minutes • የቅዳሴ 30 ደቂቃ ቀርቷል',
          body: 'Liturgy starts in 30 minutes at St. Mary\'s Orthodox Church.',
        );
      }
      if (remaining.inMinutes <= 15 && remaining.inMinutes >= 13 && !_notifiedLiturgy15m) {
        _notifiedLiturgy15m = true;
        NotificationService.instance.showSystemNotification(
          id: 70003,
          title: '🔔 Holy Liturgy in 15 Minutes • የቅዳሴ 15 ደቂቃ ቀርቷል',
          body: 'Holy Liturgy begins in 15 minutes. Church doors are open.',
        );
      }
      if (remaining.inMinutes <= 7 && remaining.inMinutes >= 5 && !_notifiedLiturgy7m) {
        _notifiedLiturgy7m = true;
        NotificationService.instance.showSystemNotification(
          id: 70004,
          title: '🔔 Holy Liturgy in 7 Minutes • የቅዳሴ 7 ደቂቃ ቀርቷል',
          body: 'Holy Liturgy begins in approximately 7 minutes at St. Mary\'s Orthodox Church.',
        );
      }
    } else {
      liturgyCountdownNotifier.value = Duration.zero;
      if (!_notifiedLiturgyFinished && _programs.isNotEmpty) {
        _notifiedLiturgyFinished = true;
        NotificationService.instance.showSystemNotification(
          id: 70000,
          title: '🔔 የቅዳሴ ሰዓት ደርሷል! Holy Liturgy Live Now',
          body: 'Sunday Holy Liturgy at St. Mary\'s Orthodox Church has commenced. እንኳን አደረሳችሁ!',
        );
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

  Future<void> updateChurchProgram({
    required String id,
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

    final idx = _programs.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final updated = _programs[idx].copyWith(
        title: title,
        churchName: churchName,
        dateTime: dateTime,
        initialDurationRemaining: remaining,
        description: description,
        category: category,
        reminderEnabled: reminderEnabled,
      );
      _programs[idx] = updated;
      _tickCountdown();
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('church_programs').doc(id).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore updateChurchProgram success: $id');
      } catch (e) {
        debugPrint('Firestore updateChurchProgram error: $e');
      }
    }
  }

  Future<void> deleteChurchProgram(String id) async {
    _programs.removeWhere((p) => p.id == id);
    _tickCountdown();
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('church_programs').doc(id).delete();
      debugPrint('Firestore deleteChurchProgram success: $id');
    } catch (e) {
      debugPrint('Firestore deleteChurchProgram error: $e');
    }
  }

  Future<void> broadcastEmergency({
    required String title,
    required String description,
    String churchName = "St. Mary's Orthodox Church",
    String category = 'Emergency Alert',
  }) async {
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
      await FirebaseFirestore.instance.collection('church_programs').doc(broadcast.id).set(
        broadcast.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore broadcastEmergency success: ${broadcast.id}');
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

  Future<void> postEmergencyScheduleBroadcast({
    required String title,
    required String description,
    required String churchName,
  }) async {
    await broadcastEmergency(title: title, description: description, churchName: churchName, category: 'Schedule Change');
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
      debugPrint('Firestore createGeneralAnnouncement success: ${docRef.id}');
    } catch (e) {
      debugPrint('Firestore createGeneralAnnouncement notice: $e');
    }
  }

  /// Deletes a general announcement by its Firestore document id.
  Future<void> deleteAnnouncement(String docId) async {
    _announcements.removeWhere((a) => a['id'] == docId);
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(docId).delete();
      debugPrint('Firestore deleteAnnouncement success: $docId');
    } catch (e) {
      debugPrint('Firestore deleteAnnouncement notice: $e');
    }
  }

}
