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
    final state = widget.state;
    final quiz = state.triviaQuizzes.first;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Faith Challenge • የዕውቀት ውድድር'),
        backgroundColor: AppTheme.primaryBg,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavTab(
                    title: 'Weekly Faith Quiz',
                    icon: Icons.quiz_outlined,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavTab(
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
                ? _buildQuizContent(quiz)
                : _buildLeaderboardContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({required String title, required IconData icon, required int index}) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
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
  Widget _buildQuizContent(TriviaQuizModel quiz) {
    if (_isQuizFinished) {
      return _buildQuizResult(quiz);
    }

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
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${quiz.questions.length}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
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
                    backgroundColor: AppTheme.surfaceColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5A65E)),
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
              gradient: const LinearGradient(
                colors: [Color(0xFF283344), Color(0xFF1A2230)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionAmharic,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  question.questionEnglish,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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

            Color bgColor = AppTheme.secondaryBg;
            Color borderColor = AppTheme.borderMuted;

            if (_isAnswerRevealed) {
              if (isCorrect) {
                bgColor = const Color(0xFF064E3B);
                borderColor = const Color(0xFF10B981);
              } else if (isSelected && !isCorrect) {
                bgColor = const Color(0xFF450A0A);
                borderColor = const Color(0xFFEF4444);
              }
            } else if (isSelected) {
              bgColor = const Color(0xFF2A364A);
              borderColor = AppTheme.goldAccent;
            }

            return GestureDetector(
              onTap: () => _selectOption(optIndex),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: isSelected || (_isAnswerRevealed && isCorrect) ? 1.5 : 1.0),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected ? const Color(0xFFF5A65E) : AppTheme.surfaceElevated,
                      child: Text(
                        String.fromCharCode(65 + optIndex), // A, B, C, D
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.black : Colors.white,
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
                          color: Colors.white,
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
                color: const Color(0xFF192433),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.menu_book, color: Color(0xFF60A5FA), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Explanation • ${question.bibleReference}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    question.explanation,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0), height: 1.4),
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
              backgroundColor: const Color(0xFFF5A65E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              !_isAnswerRevealed ? 'Check Answer' : (_currentQuestionIndex < quiz.questions.length - 1 ? 'Next Question' : 'Finish Quiz'),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizResult(TriviaQuizModel quiz) {
    final percentage = (_score / quiz.questions.length) * 100;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF283446), Color(0xFF1B2332)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.military_tech, color: Color(0xFFF5A65E), size: 70),
              const SizedBox(height: 12),
              const Text(
                'Faith Quiz Completed!',
                style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'You scored $_score of ${quiz.questions.length} (${percentage.toInt()}%)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
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
                        side: const BorderSide(color: AppTheme.borderMuted),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Retake Quiz', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _activeTab = 1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A65E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Leaderboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
  Widget _buildLeaderboardContent(FellowshipState state) {
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
            color: isTop1 ? const Color(0xFF263346) : AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isTop1 ? AppTheme.goldAccent : AppTheme.borderMuted,
              width: isTop1 ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Rank Medal Badge
              CircleAvatar(
                radius: 18,
                backgroundColor: isTop1
                    ? const Color(0xFFF5A65E)
                    : entry.rank == 2
                        ? const Color(0xFF94A3B8)
                        : entry.rank == 3
                            ? const Color(0xFFB45309)
                            : AppTheme.surfaceElevated,
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isTop1 ? Colors.black : Colors.white,
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
                        color: isTop1 ? const Color(0xFFF5A65E) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.participantsCount} Fellows completed quizzes',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.totalScore} pts',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5A65E),
                    ),
                  ),
                  const Text('Total Score', style: TextStyle(fontSize: 9, color: AppTheme.textTertiary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
