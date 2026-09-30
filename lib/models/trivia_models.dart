
class TriviaQuestionModel {
  final String id;
  final String questionAmharic;
  final String questionEnglish;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String bibleReference;

  const TriviaQuestionModel({
    required this.id,
    required this.questionAmharic,
    required this.questionEnglish,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.bibleReference,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionAmharic': questionAmharic,
      'questionEnglish': questionEnglish,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
      'bibleReference': bibleReference,
    };
  }

  factory TriviaQuestionModel.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
    return TriviaQuestionModel(
      id: map['id'] ?? fallbackId ?? '',
      questionAmharic: map['questionAmharic'] ?? '',
      questionEnglish: map['questionEnglish'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: (map['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] ?? '',
      bibleReference: map['bibleReference'] ?? '',
    );
  }
}

class TriviaQuizModel {
  final String id;
  final int weekNumber;
  final String title;
  final String description;
  final List<TriviaQuestionModel> questions;
  final int timeLimitMinutes;

  const TriviaQuizModel({
    required this.id,
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.questions,
    this.timeLimitMinutes = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'timeLimitMinutes': timeLimitMinutes,
    };
  }

  factory TriviaQuizModel.fromMap(Map<String, dynamic> map, String docId) {
    final rawQuestions = map['questions'] as List<dynamic>? ?? [];
    return TriviaQuizModel(
      id: docId,
      weekNumber: (map['weekNumber'] as num?)?.toInt() ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      questions: rawQuestions
          .map((q) => TriviaQuestionModel.fromMap(Map<String, dynamic>.from(q)))
          .toList(),
      timeLimitMinutes: (map['timeLimitMinutes'] as num?)?.toInt() ?? 5,
    );
  }
}

class QuizAttemptModel {
  final String id;
  final String studentId;
  final String studentName;
  final String familyId;
  final String familyName;
  final String quizId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  const QuizAttemptModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.familyId,
    required this.familyName,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'familyId': familyId,
      'familyName': familyName,
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory QuizAttemptModel.fromMap(Map<String, dynamic> map, String docId) {
    return QuizAttemptModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      familyId: map['familyId'] ?? '',
      familyName: map['familyName'] ?? '',
      quizId: map['quizId'] ?? '',
      score: (map['score'] as num?)?.toInt() ?? 0,
      totalQuestions: (map['totalQuestions'] as num?)?.toInt() ?? 5,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class FamilyLeaderboardEntry {
  final String familyId;
  final String familyName;
  final int totalScore;
  final int participantsCount;
  final int rank;

  const FamilyLeaderboardEntry({
    required this.familyId,
    required this.familyName,
    required this.totalScore,
    required this.participantsCount,
    required this.rank,
  });
}

