import 'package:flutter/material.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import 'student_liturgical_calendar_screen.dart';
import 'student_prayer_book_screen.dart';
import 'student_confessor_screen.dart';
import 'student_pilgrimage_screen.dart';
import 'student_charity_screen.dart';
import 'student_mentorship_screen.dart';
import 'student_trivia_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final FellowshipState state;
  final Function(int) onNavigateTab;
  final VoidCallback onOpenScanner;

  const StudentHomeScreen({
    super.key,
    required this.state,
    required this.onNavigateTab,
    required this.onOpenScanner,
  });

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _reminderEnabled = true;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final countdownStr = _formatDuration(state.liturgyCountdown);
    final calDay = state.currentCalendarDay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting Subtitle
          Text(
            'Welcome, ${state.currentUser.fullName.split(' ').first}',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // 0. Daily Liturgical Calendar & Fasting Banner (Interactive)
          GestureDetector(
            onTap: () => _navigateTo(StudentLiturgicalCalendarScreen(state: state)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF263244), Color(0xFF192230)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today_outlined, color: AppTheme.goldLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              calDay.geezDateString,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5A65E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: calDay.isFasting ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                calDay.isFasting ? 'Fasting' : 'Non-Fasting',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: calDay.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          calDay.saintOfTodayGeEz,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.goldLight),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 1. Upcoming Liturgy Big Glow Card (Matching screen4 - Copy.png)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2C3545),
                  const Color(0xFF1E2633),
                  AppTheme.secondaryBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderMuted.withOpacity(0.8), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Liturgy',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Liturgy Reminder Switch
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: _reminderEnabled,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFFE57E12),
                        inactiveThumbColor: AppTheme.textSecondary,
                        inactiveTrackColor: AppTheme.surfaceColor,
                        onChanged: (val) {
                          setState(() => _reminderEnabled = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Liturgy reminder activated' : 'Reminder silenced'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppTheme.surfaceColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppTheme.goldLight, size: 16),
                    const SizedBox(width: 4),
                    const Text(
                      'St. Mary\'s Orthodox Church',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Liturgy Countdown Numbers (e.g. 02:15:45)
                Text(
                  countdownStr,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF5A65E),
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'TIME REMAINING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // QUICK ACTIONS Header
          const Text(
            'FELLOWSHIP SERVICES & QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Primary Quick Action 3-Card Grid
          Row(
            children: [
              // 1. Daily Prayers
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.menu_book,
                  iconColor: const Color(0xFFF5A65E),
                  title: 'Daily\nPrayers',
                  onTap: () => _navigateTo(StudentPrayerBookScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Confessor Father
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFFF5A65E),
                  title: 'Father\nConfessor',
                  onTap: () => _navigateTo(StudentConfessorScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Pilgrimage Trips
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.directions_bus_outlined,
                  iconColor: const Color(0xFFF5A65E),
                  title: 'Pilgrimage\nTrips',
                  onTap: () => _navigateTo(StudentPilgrimageScreen(state: state)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Secondary Quick Action 4-Card Grid
          Row(
            children: [
              // 4. Mutual Aid & Charity
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.volunteer_activism_outlined,
                  iconColor: const Color(0xFF34D399),
                  title: 'Mutual Aid\n& Charity',
                  onTap: () => _navigateTo(StudentCharityScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 5. Dept Mentorship
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.school_outlined,
                  iconColor: const Color(0xFF60A5FA),
                  title: 'Dept\nMentorship',
                  onTap: () => _navigateTo(StudentMentorshipScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 6. Faith Trivia Quiz
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Faith Quiz\nChallenge',
                  onTap: () => _navigateTo(StudentTriviaScreen(state: state)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Weekly Christian Education Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.goldAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, color: AppTheme.goldLight, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Christian\nEducation',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE57E12)),
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Continue reading: "The Early Church Fathers" (Chapter 4 - Asceticism & Grace)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                GestureDetector(
                  onTap: () => widget.onNavigateTab(2), // Tab 2 = Roadmap
                  child: const Row(
                    children: [
                      Text(
                        'Open Spiritual Roadmap',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.goldLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: AppTheme.goldLight, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Church Feasts & Announcements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FEASTS & GATHERINGS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigateTab(4), // Tab 4 = Profile/Programs
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: const Text('View All', style: TextStyle(color: AppTheme.goldLight, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...state.programs.take(2).map((prog) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMuted),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.goldAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.event_available, color: AppTheme.goldLight, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prog.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${prog.churchName} • ${prog.category}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_active_outlined, color: AppTheme.goldLight, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reminder set for ${prog.title}'),
                          backgroundColor: AppTheme.surfaceColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF222B3A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderMuted.withOpacity(0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
