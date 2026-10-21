part of 'fellowship_state.dart';

/// Feature slice managing Theological Faith Challenge Trivia & Family Leaderboard.
class TriviaState extends ChangeNotifier {
  final FellowshipState root;
  TriviaState(this.root);
  void refresh() => notifyListeners();
}

mixin TriviaStateMixin on ChangeNotifier {
  UserModel get _currentUser;
  FamilyModel? get currentStudentFamily;
  bool get isDemoMode;

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
  List<FamilyLeaderboardEntry> get familyLeaderboard =>
      List.unmodifiable(_familyLeaderboard);

  /// Live global leaderboard from trivia_scores (all students, cross-device).
  List<Map<String, dynamic>> get globalTriviaLeaderboard =>
      List.unmodifiable(_globalTriviaLeaderboard);

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

  Future<Map<String, int>> submitQuizAttempt({
    required String quizId,
    required List<int> selectedAnswers,
  }) async {
    if (_currentUser.id.isEmpty || selectedAnswers.isEmpty) {
      throw StateError('The signed-in student or quiz answers are missing.');
    }
    final attemptId = '${quizId}_${_currentUser.id}';
    late final int score;
    late final int totalQuestions;
    var familyId = '';
    var familyName = '';
    try {
      final response = await FirebaseCallableService.instance.call(
        'submitTriviaAttempt',
        {'quizId': quizId, 'selectedAnswers': selectedAnswers},
      );
      score = (response['score'] as num).toInt();
      totalQuestions = (response['totalQuestions'] as num).toInt();
      familyId = response['familyId']?.toString() ?? '';
      familyName = response['familyName']?.toString() ?? '';
    } catch (e) {
      if (!isDemoMode) {
        debugPrint('Secure quiz submission failed: $e');
        rethrow;
      }
      final quiz = _triviaQuizzes.firstWhere((item) => item.id == quizId);
      totalQuestions = quiz.questions.length;
      if (selectedAnswers.length != totalQuestions) {
        throw StateError('Select one answer for every quiz question.');
      }
      score = List<int>.generate(totalQuestions, (index) => index)
          .where(
            (index) =>
                quiz.questions[index].correctOptionIndex ==
                selectedAnswers[index],
          )
          .length;
      final family = currentStudentFamily;
      familyId = family?.id ?? '';
      familyName = family?.name ?? '';
    }

    final alreadyInState = _quizAttempts.any(
      (existing) => existing.id == attemptId,
    );
    if (!alreadyInState) {
      _quizAttempts.insert(
        0,
        QuizAttemptModel(
          id: attemptId,
          studentId: _currentUser.id,
          studentName: _currentUser.fullName,
          familyId: familyId,
          familyName: familyName,
          quizId: quizId,
          score: score,
          totalQuestions: totalQuestions,
          completedAt: DateTime.now(),
        ),
      );
      _addScoreToFamilyLeaderboard(familyId, familyName, score);
    }
    notifyListeners();
    return {'score': score, 'totalQuestions': totalQuestions};
  }

  Future<void> addTriviaQuiz(TriviaQuizModel quiz) async {
    try {
      await FirebaseCallableService.instance.call('saveTriviaQuiz', {
        'quizId': quiz.id,
        ...quiz.toMap(),
      });
      final sanitized = _withoutAnswerKey(quiz);
      _triviaQuizzes.removeWhere((item) => item.id == quiz.id);
      _triviaQuizzes.insert(0, sanitized);
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore addTriviaQuiz error: $e');
      rethrow;
    }
  }

  Future<void> deleteTriviaQuiz(String quizId) async {
    try {
      await FirebaseCallableService.instance.call('deleteTriviaQuiz', {
        'quizId': quizId,
      });
      _triviaQuizzes.removeWhere((quiz) => quiz.id == quizId);
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore deleteTriviaQuiz error: $e');
      rethrow;
    }
  }

  TriviaQuizModel _withoutAnswerKey(TriviaQuizModel quiz) => TriviaQuizModel(
    id: quiz.id,
    weekNumber: quiz.weekNumber,
    title: quiz.title,
    description: quiz.description,
    timeLimitMinutes: quiz.timeLimitMinutes,
    questions: quiz.questions
        .map(
          (question) => TriviaQuestionModel(
            id: question.id,
            questionAmharic: question.questionAmharic,
            questionEnglish: question.questionEnglish,
            options: question.options,
            correctOptionIndex: -1,
            explanation: '',
            bibleReference: question.bibleReference,
          ),
        )
        .toList(),
  );

  void _addScoreToFamilyLeaderboard(
    String familyId,
    String familyName,
    int score,
  ) {
    if (familyId.isEmpty) return;
    final famIdx = _familyLeaderboard.indexWhere((f) => f.familyId == familyId);
    if (famIdx != -1) {
      final current = _familyLeaderboard[famIdx];
      _familyLeaderboard[famIdx] = FamilyLeaderboardEntry(
        familyId: current.familyId,
        familyName: current.familyName,
        totalScore: current.totalScore + score * 20,
        participantsCount: current.participantsCount + 1,
        rank: current.rank,
      );
      final sorted = List<FamilyLeaderboardEntry>.from(_familyLeaderboard)
        ..sort((a, b) => b.totalScore.compareTo(a.totalScore));
      _familyLeaderboard = [
        for (var index = 0; index < sorted.length; index++)
          FamilyLeaderboardEntry(
            familyId: sorted[index].familyId,
            familyName: sorted[index].familyName,
            totalScore: sorted[index].totalScore,
            participantsCount: sorted[index].participantsCount,
            rank: index + 1,
          ),
      ];
    } else {
      _familyLeaderboard.add(
        FamilyLeaderboardEntry(
          familyId: familyId,
          familyName: familyName,
          totalScore: score * 20,
          participantsCount: 1,
          rank: _familyLeaderboard.length + 1,
        ),
      );
    }
  }
}
