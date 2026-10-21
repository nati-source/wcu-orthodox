part of 'fellowship_state.dart';

/// Feature slice managing Confessor Fathers, Confession Appointments & Spiritual Q&A.
class ConfessorState extends ChangeNotifier {
  final FellowshipState root; ConfessorState(this.root);
  void refresh() => notifyListeners();
}

mixin ConfessorStateMixin on ChangeNotifier {
  UserModel get _currentUser;
  bool get isAdmin;
  bool get canSchedulePriests;
  bool get canManageApprovals;
  Future<void> broadcastEmergency({required String title, required String description, String churchName, String category});

  // ----------------------------------------------------
  // DOMAIN 10: PRIEST / CONFESSOR FATHER BOOKING & Q&A
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
      _confessionAppointments.where((a) => a.studentId == _currentUser.id || (FirebaseAuth.instance.currentUser != null && a.studentId == FirebaseAuth.instance.currentUser!.uid)).toList();

  Future<void> bookConfessionAppointment({
    required String fatherId,
    required DateTime scheduledDate,
    required String timeSlot,
    required String topic,
    String? notes,
  }) async {
    final father = _confessorFathers.firstWhere(
      (f) => f.id == fatherId,
      orElse: () => _confessorFathers.isNotEmpty
          ? _confessorFathers.first
          : ConfessorFatherModel(
              id: fatherId,
              clericalTitle: 'Abba',
              fullName: 'Spiritual Father',
              churchName: 'WCU Fellowship Chapel',
              phoneNumber: '+251911000000',
              availableDays: const ['Sunday', 'Saturday'],
              availableTimeSlots: const ['09:00 AM - 11:00 AM'],
              bio: 'Campus Confession Father',
            ),
    );
    final newAppt = ConfessionAppointmentModel(
      id: 'conf-${DateTime.now().millisecondsSinceEpoch}',
      studentId: (() { try { final u = FirebaseAuth.instance.currentUser?.uid; if (u != null && u.isNotEmpty) return u; } catch (_) {} return _currentUser.id; })(),
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

    try {
      await FirebaseFirestore.instance.collection('confession_appointments').doc(newAppt.id).set(
        newAppt.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore bookConfessionAppointment success: ${newAppt.id}');
    } catch (e) {
      debugPrint('Firestore bookConfessionAppointment error: $e');
    }
  }

  Future<void> addConfessorFather(ConfessorFatherModel father) async {
    _confessorFathers = List<ConfessorFatherModel>.from(_confessorFathers)..add(father);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('confessors').doc(father.id).set(
        father.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore addConfessorFather success: ${father.id}');
    } catch (e) {
      debugPrint('Firestore addConfessorFather error: $e');
    }
  }

  Future<void> updateConfessorFather(ConfessorFatherModel updated) async {
    final index = _confessorFathers.indexWhere((f) => f.id == updated.id);
    if (index != -1) {
      final list = List<ConfessorFatherModel>.from(_confessorFathers);
      list[index] = updated;
      _confessorFathers = list;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('confessors').doc(updated.id).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore updateConfessorFather success: ${updated.id}');
      } catch (e) {
        debugPrint('Firestore updateConfessorFather error: $e');
      }
    }
  }

  Future<void> deleteConfessorFather(String fatherId) async {
    _confessorFathers = _confessorFathers.where((f) => f.id != fatherId).toList();
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('confessors').doc(fatherId).delete();
      debugPrint('Firestore deleteConfessorFather success: $fatherId');
    } catch (e) {
      debugPrint('Firestore deleteConfessorFather error: $e');
    }
  }

  Future<void> confirmConfessionAppointment(
    String apptId, {
    String? notes,
    String? assignedVenue,
  }) async {
    final index = _confessionAppointments.indexWhere((a) => a.id == apptId);
    if (index != -1) {
      final appt = _confessionAppointments[index];
      final updatedAppt = appt.copyWith(
        status: ConfessionAppointmentStatus.confirmed,
        notes: notes ?? (assignedVenue != null ? 'Confirmed at $assignedVenue' : 'Confirmed by Confession Father'),
      );
      _confessionAppointments[index] = updatedAppt;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('confession_appointments').doc(apptId).set(
          updatedAppt.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore confirmConfessionAppointment success: $apptId');
      } catch (e) {
        debugPrint('Firestore confirmConfessionAppointment error: $e');
      }
    }
  }

  void broadcastPriestScheduleAlert({
    required String fatherName,
    required String newVenueOrTime,
  }) {
    broadcastEmergency(
      title: 'Clergy Schedule Update • $fatherName',
      description: '$fatherName schedule/venue updated: $newVenueOrTime. Please verify your appointments.',
      category: 'Clergy Notice',
    );
  }

  Future<void> updateConfessionStatus(String apptId, ConfessionAppointmentStatus status) async {
    final index = _confessionAppointments.indexWhere((a) => a.id == apptId);
    if (index != -1) {
      final updated = _confessionAppointments[index].copyWith(status: status);
      _confessionAppointments[index] = updated;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('confession_appointments').doc(apptId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore updateConfessionStatus success: $apptId');
      } catch (e) {
        debugPrint('Firestore updateConfessionStatus error: $e');
      }
    }
  }

  Future<void> cancelConfessionAppointment(String apptId) async {
    await updateConfessionStatus(apptId, ConfessionAppointmentStatus.cancelled);
  }

  Future<void> submitAnonymousQuestion({
    required String questionText,
    required String category,
  }) async {
    final newQ = AnonymousSpiritualQuestionModel(
      id: 'q-${DateTime.now().millisecondsSinceEpoch}',
      questionText: questionText,
      category: category,
      askedAt: DateTime.now(),
      isAnswered: false,
    );
    _spiritualQuestions.insert(0, newQ);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('spiritual_questions').doc(newQ.id).set(
        newQ.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore submitAnonymousQuestion success: ${newQ.id}');
    } catch (e) {
      debugPrint('Firestore submitAnonymousQuestion error: $e');
    }
  }

  Future<void> answerSpiritualQuestion({
    required String questionId,
    required String answerText,
    required String answeredBy,
  }) async {
    final index = _spiritualQuestions.indexWhere((q) => q.id == questionId);
    if (index != -1) {
      final updated = _spiritualQuestions[index].copyWith(
        isAnswered: true,
        answerText: answerText,
        answeredBy: answeredBy,
      );
      _spiritualQuestions[index] = updated;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('spiritual_questions').doc(questionId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore answerSpiritualQuestion success: $questionId');
      } catch (e) {
        debugPrint('Firestore answerSpiritualQuestion error: $e');
      }
    }
  }

  Future<void> deleteSpiritualQuestion(String questionId) async {
    _spiritualQuestions.removeWhere((q) => q.id == questionId);
    notifyListeners();
    try {
      await FirebaseFirestore.instance.collection('spiritual_questions').doc(questionId).delete();
      debugPrint('Firestore deleteSpiritualQuestion success: $questionId');
    } catch (e) {
      debugPrint('Firestore deleteSpiritualQuestion error: $e');
    }
  }

  void toggleCommunionItem(String itemId) {
    final index = _communionChecklist.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _communionChecklist[index].isChecked = !_communionChecklist[index].isChecked;
      notifyListeners();
    }
  }

}


