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
  void broadcastEmergency({required String title, required String description, String churchName, String category});

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

    try {
      FirebaseFirestore.instance.collection('confession_appointments').doc(newAppt.id).set(
        newAppt.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore bookConfessionAppointment notice: $e');
    }
  }

  void addConfessorFather(ConfessorFatherModel father) {
    if (!canSchedulePriests) return;
    _confessorFathers = List<ConfessorFatherModel>.from(_confessorFathers)..add(father);
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('confessors').doc(father.id).set(
        father.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore addConfessorFather notice: $e');
    }
  }

  void updateConfessorFather(ConfessorFatherModel updated) {
    if (!canSchedulePriests) return;
    final index = _confessorFathers.indexWhere((f) => f.id == updated.id);
    if (index != -1) {
      final list = List<ConfessorFatherModel>.from(_confessorFathers);
      list[index] = updated;
      _confessorFathers = list;
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('confessors').doc(updated.id).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore updateConfessorFather notice: $e');
      }
    }
  }

  void deleteConfessorFather(String fatherId) {
    if (!canSchedulePriests) return;
    _confessorFathers = _confessorFathers.where((f) => f.id != fatherId).toList();
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('confessors').doc(fatherId).delete();
    } catch (e) {
      debugPrint('Firestore deleteConfessorFather notice: $e');
    }
  }

  void confirmConfessionAppointment(
    String apptId, {
    String? notes,
    String? assignedVenue,
  }) {
    if (!canManageApprovals && !isAdmin) return;
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
        FirebaseFirestore.instance.collection('confession_appointments').doc(apptId).set(
          updatedAppt.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore confirmConfessionAppointment notice: $e');
      }
    }
  }

  void broadcastPriestScheduleAlert({
    required String fatherName,
    required String newVenueOrTime,
  }) {
    if (!canManageApprovals && !isAdmin) return;
    broadcastEmergency(
      title: 'Clergy Schedule Update • $fatherName',
      description: '$fatherName schedule/venue updated: $newVenueOrTime. Please verify your appointments.',
      category: 'Clergy Notice',
    );
  }

  void updateConfessionStatus(String apptId, ConfessionAppointmentStatus status) {
    final index = _confessionAppointments.indexWhere((a) => a.id == apptId);
    if (index != -1) {
      final updated = _confessionAppointments[index].copyWith(status: status);
      _confessionAppointments[index] = updated;
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('confession_appointments').doc(apptId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore updateConfessionStatus notice: $e');
      }
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

    try {
      FirebaseFirestore.instance.collection('spiritual_questions').doc(newQ.id).set(
        newQ.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submitAnonymousQuestion notice: $e');
    }
  }

  void answerSpiritualQuestion({
    required String questionId,
    required String answerText,
    required String answeredBy,
  }) {
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
        FirebaseFirestore.instance.collection('spiritual_questions').doc(questionId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore answerSpiritualQuestion notice: $e');
      }
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


