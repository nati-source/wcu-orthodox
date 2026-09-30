import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';
import 'student_liturgical_calendar_screen.dart';
import 'student_prayer_book_screen.dart';
import 'student_confessor_screen.dart';
import 'student_pilgrimage_screen.dart';
import 'student_charity_screen.dart';
import 'student_mentorship_screen.dart';
import 'student_trivia_screen.dart';
import 'student_ministry_screen.dart';

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
      MaterialPageRoute(
        builder: (_) => ListenableBuilder(
          listenable: widget.state,
          builder: (context, _) => screen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final calDay = state.currentCalendarDay;
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting Subtitle
          Text(
            'Welcome, ${state.currentUser.fullName.split(' ').first}',
            style: TextStyle(
              fontSize: 14,
              color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // EMERGENCY BROADCAST ALERT CARD (Shown when admin pushes an emergency broadcast)
          if (state.latestEmergencyBroadcast != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.crimson.withOpacity(0.18),
                    theme.cardTheme.color ?? theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.crimson.withOpacity(0.6), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.crimson.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.crimson,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.campaign, color: Colors.white, size: 16),
                            SizedBox(width: 5),
                            Text(
                              'URGENT BROADCAST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, size: 18),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Dismiss from feed',
                        onPressed: () {
                          state.dismissEmergencyBanner();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    state.latestEmergencyBroadcast!.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (state.latestEmergencyBroadcast!.churchName.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          state.latestEmergencyBroadcast!.churchName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    state.latestEmergencyBroadcast!.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Dismiss Alert'),
                        onPressed: () => state.dismissEmergencyBanner(),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (state.isAdmin || state.activeRole == UserRole.admin) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                          label: const Text('Delete from DB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.crimson,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final bId = state.latestEmergencyBroadcast?.id;
                            if (bId == null) return;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                                title: const Text('Delete from Database?'),
                                content: const Text('This will delete the emergency broadcast from Cloud Firestore and remove it from all user screens in real time.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await state.deleteEmergencyBroadcast(bId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Emergency broadcast permanently deleted from database.')),
                                        );
                                      }
                                    },
                                    child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],

          // 0. Daily Liturgical Calendar & Fasting Banner (Interactive)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _navigateTo(StudentLiturgicalCalendarScreen(state: state));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.cardTheme.color ?? theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryAccent.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.calendar_today_outlined, color: primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                calDay.geezDateString,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryAccent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: calDay.isFasting
                                    ? const Color(0xFFEF4444).withOpacity(0.2)
                                    : const Color(0xFF10B981).withOpacity(0.2),
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
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: primaryAccent),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 1. Upcoming Liturgy Big Glow Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.cardTheme.color ?? theme.colorScheme.surface,
                  theme.scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryAccent.withOpacity(0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
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
                    Expanded(
                      child: Text(
                        'Upcoming Liturgy',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Liturgy Reminder Switch
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: _reminderEnabled,
                        activeColor: isDark ? Colors.black : Colors.white,
                        activeTrackColor: primaryAccent,
                        inactiveThumbColor: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                        inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                        onChanged: (val) {
                          setState(() => _reminderEnabled = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(val ? 'Liturgy reminder activated' : 'Reminder silenced'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
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
                    Icon(Icons.location_on_outlined, color: primaryAccent, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'St. Mary\'s Orthodox Church',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Liturgy Countdown Numbers (e.g. 02:15:45)
                ValueListenableBuilder<Duration>(
                  valueListenable: state.liturgyCountdownNotifier,
                  builder: (context, duration, _) {
                    return Text(
                      _formatDuration(duration),
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        color: primaryAccent,
                        letterSpacing: 2.0,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Text(
                  'TIME REMAINING',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // QUICK ACTIONS Header
          Text(
            'FELLOWSHIP SERVICES & QUICK ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.textTertiary,
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
                  iconColor: primaryAccent,
                  title: 'Daily\nPrayers',
                  onTap: () => _navigateTo(StudentPrayerBookScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Confessor Father
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.shield_outlined,
                  iconColor: primaryAccent,
                  title: 'Father\nConfessor',
                  onTap: () => _navigateTo(StudentConfessorScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 3. Pilgrimage Trips
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.directions_bus_outlined,
                  iconColor: primaryAccent,
                  title: 'Pilgrimage\nTrips',
                  onTap: () => _navigateTo(StudentPilgrimageScreen(state: state)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Secondary Quick Action 3-Card Grid
          Row(
            children: [
              // 4. Mutual Aid & Charity
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.volunteer_activism_outlined,
                  iconColor: const Color(0xFF10B981),
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

          const SizedBox(height: 10),

          // Tertiary Quick Action 2-Card Row (10 Departments & Liturgical Calendar)
          Row(
            children: [
              // 7. 10 Departments & Volunteer Serving
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.hub_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: '10 Ministries\n& Volunteer Serving',
                  onTap: () => _navigateTo(StudentMinistryScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),

              // 8. Liturgical Calendar & Feasts
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.calendar_month_outlined,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Liturgical\nCalendar & Feasts',
                  onTap: () => _navigateTo(StudentLiturgicalCalendarScreen(state: state)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Weekly Christian Education Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
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
                        color: primaryAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book, color: primaryAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Christian\nEducation',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryAccent,
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
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Continue reading: "The Early Church Fathers" (Chapter 4 - Asceticism & Grace)',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onNavigateTab(2); // Tab 2 = Roadmap
                  },
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Open Spiritual Roadmap',
                          style: TextStyle(
                            fontSize: 13,
                            color: primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: primaryAccent, size: 16),
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
              Expanded(
                child: Text(
                  'FEASTS & GATHERINGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.textTertiary,
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onNavigateTab(4); // Tab 4 = Profile/Programs
                },
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text('View All', style: TextStyle(color: primaryAccent, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...state.programs.take(2).map((prog) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(Icons.event_available, color: primaryAccent, size: 22),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prog.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${prog.churchName} • ${prog.category}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_active_outlined, color: primaryAccent, size: 20),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reminder set for ${prog.title}'),
                          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
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
    final theme = Theme.of(context);

    return InteractiveFellowshipCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      margin: EdgeInsets.zero,
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderColor: theme.dividerColor,
      showWatermark: true,
      watermarkSize: 55,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
