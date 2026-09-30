part of 'fellowship_state.dart';

/// Feature slice managing Theological Faith Challenge Trivia & Family Leaderboard.
class TriviaState extends ChangeNotifier {
  final FellowshipState root; TriviaState(this.root);
  void refresh() => notifyListeners();
}

mixin TriviaStateMixin on ChangeNotifier {
  UserModel get _currentUser;
  FamilyModel? get currentStudentFamily;

  // ----------------------------------------------------
  // DOMAIN 14: THEOLOGICAL FAITH CHALLENGE TRIVIA
  // ----------------------------------------------------
  List<TriviaQuizModel> _triviaQuizzes = [];
  final List<QuizAttemptModel> _quizAttempts = [];
  List<FamilyLeaderboardEntry> _familyLeaderboard = [];
  // Per-student aggregate leaderboard from trivia_scores collection
  List<Map<String, dynamic>> _globalTriviaLeaderboard = [];

  List<TriviaQuizModel> get triviaQuizzes => List.unmodifiable(_triviaQuizzes);
  List<QuizAttemptModel> get quizAttempts => List.unmodifiable(_quizAttempts);
  List<FamilyLeaderboardEntry> get familyLeaderboard => List.unmodifiable(_familyLeaderboard);
  /// Live global leaderboard from trivia_scores (all students, cross-device).
  List<Map<String, dynamic>> get globalTriviaLeaderboard => List.unmodifiable(_globalTriviaLeaderboard);

  QuizAttemptModel? get myLatestQuizAttempt {
    if (_quizAttempts.isEmpty) return null;
    try {
      return _quizAttempts.firstWhere((a) => a.studentId == _currentUser.id);
    } catch (_) {
      return null;
    }
  }

  /// Total score for current student from the global trivia_scores aggregation.
  int get myGlobalTriviaScore {
    try {
      final entry = _globalTriviaLeaderboard.firstWhere(
        (e) => e['studentUid'] == _currentUser.id,
      );
      return (entry['totalScore'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  void submitQuizAttempt({
    required String quizId,
    required int score,
    required int totalQuestions,
  }) {
    final currentFam = currentStudentFamily;
    final attempt = QuizAttemptModel(
      id: 'att-quiz-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      familyId: currentFam?.id ?? 'fam-st-george',
      familyName: currentFam?.name ?? 'Family of St. George',
      quizId: quizId,
      score: score,
      totalQuestions: totalQuestions,
      completedAt: DateTime.now(),
    );
    _quizAttempts.insert(0, attempt);

    // Update family leaderboard and dynamically re-sort ranks descending by totalScore
    final famIdx = _familyLeaderboard.indexWhere((f) => f.familyId == attempt.familyId);
    if (famIdx != -1) {
      final cur = _familyLeaderboard[famIdx];
      _familyLeaderboard[famIdx] = FamilyLeaderboardEntry(
        familyId: cur.familyId,
        familyName: cur.familyName,
        totalScore: cur.totalScore + (score * 20),
        participantsCount: cur.participantsCount + 1,
        rank: cur.rank,
      );

      final sorted = List<FamilyLeaderboardEntry>.from(_familyLeaderboard)
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
      _familyLeaderboard = [
        for (int i = 0; i < sorted.length; i++)
          FamilyLeaderboardEntry(
            familyId: sorted[i].familyId,
            familyName: sorted[i].familyName,
            totalScore: sorted[i].totalScore,
            participantsCount: sorted[i].participantsCount,
            rank: i + 1,
          )
      ];
    }
    notifyListeners();

    // 1. Record the individual attempt in quiz_attempts
    try {
      FirebaseFirestore.instance.collection('quiz_attempts').doc(attempt.id).set(
        attempt.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore submitQuizAttempt (quiz_attempts) notice: $e');
    }

    // 2. Increment the per-student aggregate score in trivia_scores so the
    //    global leaderboard (streamTriviaLeaderboard) reflects the result
    //    immediately and consistently across all devices.
    try {
      final scoreDoc = FirebaseFirestore.instance
          .collection('trivia_scores')
          .doc(_currentUser.id);

      scoreDoc.get().then((doc) {
        if (doc.exists) {
          scoreDoc.update({
            'studentName': _currentUser.fullName,
            'totalScore': FieldValue.increment(score),
            'quizzesCompleted': FieldValue.increment(1),
            'lastActive': FieldValue.serverTimestamp(),
          });
        } else {
          scoreDoc.set({
            'studentUid': _currentUser.id,
            'studentName': _currentUser.fullName,
            'totalScore': score,
            'quizzesCompleted': 1,
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('Firestore submitQuizAttempt (trivia_scores) notice: $e');
    }
  }

  Future<void> addTriviaQuiz(TriviaQuizModel quiz) async {
    _triviaQuizzes.insert(0, quiz);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('trivia_quizzes').doc(quiz.id).set(
        quiz.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore addTriviaQuiz error: $e');
    }
  }

  Future<void> deleteTriviaQuiz(String quizId) async {
    _triviaQuizzes.removeWhere((q) => q.id == quizId);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('trivia_quizzes').doc(quizId).delete();
    } catch (e) {
      debugPrint('Firestore deleteTriviaQuiz error: $e');
    }
  }
}
