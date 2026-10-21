part of 'fellowship_state.dart';

/// Feature slice managing Senior-to-Junior Academic Mentorship Matching.
class MentorshipState extends ChangeNotifier {
  final FellowshipState root; MentorshipState(this.root);
  void refresh() => notifyListeners();
}

mixin MentorshipStateMixin on ChangeNotifier {
  UserModel get _currentUser;
  List<UserModel> get _allStudents;

  // ----------------------------------------------------
  // DOMAIN 13: DEPARTMENT MENTORSHIP MATCHING
  // ----------------------------------------------------
  List<AcademicMentorModel> _academicMentors = [];
  List<MentorshipRequestModel> _mentorshipRequests = [];

  List<AcademicMentorModel> get academicMentors {
    final Map<String, AcademicMentorModel> map = {};
    for (final m in _academicMentors) {
      map[m.id] = m;
    }

    // Auto-discover approved senior students (Year >= 3) from the database as potential mentors
    for (final student in _allStudents) {
      if (!student.isApproved) continue;
      if (student.academicYear < 3) continue;
      if (student.id == _currentUser.id) continue;

      if (!map.containsKey(student.id)) {
        map[student.id] = AcademicMentorModel(
          id: student.id,
          studentId: student.id,
          fullName: student.fullName,
          baptismalName: student.baptismalName,
          department: student.department,
          academicYear: student.academicYear,
          specialties: ['Department Courses & Coaching', 'Exam Prep & Study Habits'],
          telegramHandle: '@${student.fullName.toLowerCase().replaceAll(' ', '_')}',
          phoneNumber: student.phoneNumber.trim().isNotEmpty ? student.phoneNumber.trim() : '+251911223344',
          activeMenteesCount: _mentorshipRequests.where((r) => r.mentorId == student.id && r.status == MentorshipStatus.matched).length,
          maxMentees: 4,
          isAvailable: true,
        );
      }
    }
    return map.values.toList();
  }

  List<MentorshipRequestModel> get mentorshipRequests => List.unmodifiable(_mentorshipRequests);

  List<MentorshipRequestModel> get myMentorshipRequests =>
      _mentorshipRequests.where((r) => r.juniorStudentId == _currentUser.id).toList();

  List<MentorshipRequestModel> get incomingMentorshipRequests =>
      _mentorshipRequests.where((r) => r.mentorId == _currentUser.id).toList();

  Future<void> requestMentorship({
    required String mentorId,
    required String coursesNeeded,
  }) async {
    late final AcademicMentorModel mentor;
    try {
      mentor = academicMentors.firstWhere((m) => m.id == mentorId);
    } catch (_) {
      mentor = AcademicMentorModel(
        id: mentorId,
        studentId: mentorId,
        fullName: 'Senior Academic Mentor',
        baptismalName: 'Welde Georgis',
        department: _currentUser.department,
        academicYear: 4,
        specialties: [coursesNeeded],
        telegramHandle: '@mentor',
        phoneNumber: '+251911000000',
      );
    }
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
      mentorPhone: mentor.phoneNumber,
      mentorTelegram: mentor.telegramHandle,
      juniorPhone: _currentUser.phoneNumber,
    );
    _mentorshipRequests.insert(0, req);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('mentorship_requests').doc(req.id).set(
        req.toMap(),
        SetOptions(merge: true),
      );
      debugPrint('Firestore requestMentorship success: ${req.id}');
    } catch (e) {
      debugPrint('Firestore requestMentorship error: $e');
    }
  }

  Future<void> updateMentorshipStatus(String reqId, MentorshipStatus status) async {
    final index = _mentorshipRequests.indexWhere((r) => r.id == reqId);
    if (index != -1) {
      final current = _mentorshipRequests[index];
      final mentorPhone = (current.mentorPhone != null && current.mentorPhone!.trim().isNotEmpty)
          ? current.mentorPhone
          : _currentUser.phoneNumber;
      final mentorTelegram = (current.mentorTelegram != null && current.mentorTelegram!.trim().isNotEmpty)
          ? current.mentorTelegram
          : '@${_currentUser.fullName.toLowerCase().replaceAll(' ', '_')}';

      final updated = current.copyWith(
        status: status,
        mentorPhone: mentorPhone,
        mentorTelegram: mentorTelegram,
      );
      _mentorshipRequests[index] = updated;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('mentorship_requests').doc(reqId).set(
          updated.toMap(),
          SetOptions(merge: true),
        );
        debugPrint('Firestore updateMentorshipStatus success: $reqId');
      } catch (e) {
        debugPrint('Firestore updateMentorshipStatus error: $e');
      }
    }
  }

}

