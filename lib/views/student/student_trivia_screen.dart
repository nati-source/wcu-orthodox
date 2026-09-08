import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentTriviaScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentTriviaScreen({super.key, required this.state});

  @override
  State<StudentTriviaScreen> createState() => _StudentTriviaScreenState();
}

class _StudentTriviaScreenState extends State<StudentTriviaScreen> {
  int _activeTab = 0; // 0: Weekly Quiz, 1: Family Leaderboard
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswerRevealed = false;
  int _score = 0;
  bool _isQuizFinished = false;

  void _selectOption(int index) {
    if (_isAnswerRevealed) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _submitCurrentAnswer(TriviaQuestionModel question) {
    if (_selectedOptionIndex == null) return;
    setState(() {
      _isAnswerRevealed = true;
      if (_selectedOptionIndex == question.correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion(int totalQuestions, String quizId) {
    if (_currentQuestionIndex < totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedOptionIndex = null;
        _isAnswerRevealed = false;
      });
    } else {
      setState(() {
        _isQuizFinished = true;
      });
      widget.state.submitQuizAttempt(
        quizId: quizId,
        score: _score,
        totalQuestions: totalQuestions,
      );
    }
  }

  void _restartQuiz() {
    setState(() {
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _isAnswerRevealed = false;
      _score = 0;
      _isQuizFinished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;

    final state = widget.state;
    final quiz = state.triviaQuizzes.first;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Faith Challenge • የዕውቀት ውድድር', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavTab(
                    context: context,
                    title: 'Weekly Faith Quiz',
                    icon: Icons.quiz_outlined,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavTab(
                    context: context,
                    title: 'Family Leaderboard',
                    icon: Icons.emoji_events_outlined,
                    index: 1,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? _buildQuizContent(context, quiz)
                : _buildLeaderboardContent(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int index,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final isSelected = _activeTab == index;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? elevatedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? primaryAccent : textMuted),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (isDark ? primaryAccent : textCol) : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 0: QUIZ PLAY & RESULTS
  // ----------------------------------------------------
  Widget _buildQuizContent(BuildContext context, TriviaQuizModel quiz) {
    if (_isQuizFinished) {
      return _buildQuizResult(context, quiz);
    }

    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final question = quiz.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / quiz.questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Stats Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                    Text(
                      'Score: $_score',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: elevatedBg,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Question Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primaryAccent.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionAmharic,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.questionEnglish,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Option Tiles
          ...List.generate(question.options.length, (optIndex) {
            final optionText = question.options[optIndex];
            final isSelected = _selectedOptionIndex == optIndex;
            final isCorrect = optIndex == question.correctOptionIndex;

            Color bgColor = cardBg;
            Color borderColor = borderCol;

            if (_isAnswerRevealed) {
              if (isCorrect) {
                bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5);
                borderColor = const Color(0xFF10B981);
              } else if (isSelected && !isCorrect) {
                bgColor = isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2);
                borderColor = const Color(0xFFEF4444);
              }
            } else if (isSelected) {
              bgColor = elevatedBg;
              borderColor = primaryAccent;
            }

            return GestureDetector(
              onTap: () => _selectOption(optIndex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (_isAnswerRevealed && isCorrect) ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected ? primaryAccent : elevatedBg,
                      child: Text(
                        String.fromCharCode(65 + optIndex), // A, B, C, D
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : textCol,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: textCol,
                        ),
                      ),
                    ),
                    if (_isAnswerRevealed && isCorrect)
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                    else if (_isAnswerRevealed && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
                  ],
                ),
              ),
            );
          }),

          // Explanation Banner (Shown after answering)
          if (_isAnswerRevealed) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: primaryAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Explanation • ${question.bibleReference}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation,
                    style: TextStyle(fontSize: 12, color: textCol, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // Bottom Action Button
          ElevatedButton(
            onPressed: _selectedOptionIndex == null
                ? null
                : () {
                    if (!_isAnswerRevealed) {
                      _submitCurrentAnswer(question);
                    } else {
                      _nextQuestion(quiz.questions.length, quiz.id);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              !_isAnswerRevealed ? 'Check Answer' : (_currentQuestionIndex < quiz.questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResult(BuildContext context, TriviaQuizModel quiz) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final percentage = (_score / quiz.questions.length) * 100;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryAccent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.military_tech, color: primaryAccent, size: 70),
              const SizedBox(height: 12),
              Text(
                'Faith Quiz Completed!',
                style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 6),
              Text(
                'You scored $_score of ${quiz.questions.length} (${percentage.toInt()}%)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryAccent),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${_score * 20} Points contributed to your Spiritual Family Leaderboard!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _restartQuiz,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderCol),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Retake Quiz', style: TextStyle(color: textCol)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _activeTab = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Leaderboard',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: SPIRITUAL FAMILY LEADERBOARD
  // ----------------------------------------------------
  Widget _buildLeaderboardContent(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: state.familyLeaderboard.length,
      itemBuilder: (context, index) {
        final entry = state.familyLeaderboard[index];
        final isTop1 = entry.rank == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isTop1 ? elevatedBg : cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isTop1 ? primaryAccent : borderCol,
              width: isTop1 ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Rank Medal Badge
              CircleAvatar(
                radius: 18,
                backgroundColor: isTop1
                    ? primaryAccent
                    : entry.rank == 2
                        ? const Color(0xFF94A3B8)
                        : entry.rank == 3
                            ? const Color(0xFFB45309)
                            : elevatedBg,
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isTop1
                        ? (isDark ? Colors.black : Colors.white)
                        : (entry.rank <= 3 ? Colors.white : textCol),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.familyName,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isTop1 ? primaryAccent : textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.participantsCount} Fellows completed quizzes',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.totalScore} pts',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                  Text('Total Score', style: TextStyle(fontSize: 9, color: textMuted.withOpacity(0.7))),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
