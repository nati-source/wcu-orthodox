part of 'fellowship_state.dart';

/// Feature slice managing Senior-to-Junior Academic Mentorship Matching.
class MentorshipState extends ChangeNotifier {
  final FellowshipState root; MentorshipState(this.root);
  void refresh() => notifyListeners();
}

mixin MentorshipStateMixin on ChangeNotifier {
  UserModel get _currentUser;

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

    try {
      FirebaseFirestore.instance.collection('mentorship_requests').doc(req.id).set(
        req.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore requestMentorship notice: $e');
    }
  }

  void updateMentorshipStatus(String reqId, MentorshipStatus status) {
    final index = _mentorshipRequests.indexWhere((r) => r.id == reqId);
    if (index != -1) {
      final updated = _mentorshipRequests[index].copyWith(status: status);
      _mentorshipRequests[index] = updated;
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('mentorship_requests').doc(reqId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore updateMentorshipStatus notice: $e');
      }
    }
  }

}

