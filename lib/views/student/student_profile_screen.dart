import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import 'student_ministry_screen.dart';
import 'student_confessor_screen.dart';
import 'student_pilgrimage_screen.dart';
import 'student_charity_screen.dart';
import 'student_mentorship_screen.dart';

class StudentProfileScreen extends StatelessWidget {
  final FellowshipState state;

  const StudentProfileScreen({super.key, required this.state});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = state.currentUser;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final secondaryAccent = theme.colorScheme.secondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Digital Fellowship ID Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surface,
                  theme.scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: primaryAccent.withOpacity(0.6), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryAccent.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.colorScheme.surface,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryAccent, width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.person, size: 40, color: primaryAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // User Names & Role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'B.N. ${user.baptismalName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: user.role.badgeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: user.role.badgeColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              user.role.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user.role.badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIdField('BATCH', user.batchYear),
                      Container(width: 1, height: 28, color: AppTheme.borderMuted),
                      _buildIdField('DEPT', user.department.split(' ').first),
                      Container(width: 1, height: 28, color: AppTheme.borderMuted),
                      _buildIdField('YEAR', 'Year ${user.academicYear}'),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Digital Membership QR
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: 'WCU-ORTHODOX-FELLOW:${user.id}:${user.fullName}',
                    version: QrVersions.auto,
                    size: 130.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SCAN TO VERIFY FELLOWSHIP MEMBERSHIP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Personal Fellowship Services Matrix
          Text(
            'My Fellowship Engagements',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildServiceTile(
                  icon: Icons.shield_outlined,
                  color: const Color(0xFFF5A65E),
                  title: 'My Confession',
                  subtitle: '${state.myConfessionAppointments.length} Bookings',
                  onTap: () => _navigateTo(context, StudentConfessorScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceTile(
                  icon: Icons.directions_bus_outlined,
                  color: const Color(0xFF10B981),
                  title: 'My Pilgrimages',
                  subtitle: '${state.myTripRegistrations.length} Passes',
                  onTap: () => _navigateTo(context, StudentPilgrimageScreen(state: state)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildServiceTile(
                  icon: Icons.school_outlined,
                  color: const Color(0xFF60A5FA),
                  title: 'My Mentorship',
                  subtitle: '${state.myMentorshipRequests.length} Matches',
                  onTap: () => _navigateTo(context, StudentMentorshipScreen(state: state)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceTile(
                  icon: Icons.volunteer_activism_outlined,
                  color: const Color(0xFFF59E0B),
                  title: 'My Dues & Aid',
                  subtitle: '${state.duesPayments.length} Receipts',
                  onTap: () => _navigateTo(context, StudentCharityScreen(state: state)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. App Themes & Sacred Aesthetics Selection
          Text(
            'App Themes & Sacred Aesthetics (የመተግበሪያው ገጽታ)',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppThemePalette.values.map((palette) {
                final isSelected = state.currentThemePalette == palette;
                return GestureDetector(
                  onTap: () {
                    state.setThemePalette(palette);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.palette, color: AppTheme.goldLight, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Active Theme: ${palette.displayName} • ${palette.amharicName}')),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.surfaceElevated,
                      ),
                    );
                  },
                  child: Container(
                    width: 175,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: palette.scaffoldBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? palette.primaryAccent : AppTheme.borderMuted,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: palette.primaryAccent.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: palette.primaryAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, color: palette.primaryAccent, size: 18),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          palette.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          palette.amharicName,
                          style: TextStyle(fontSize: 10, color: palette.primaryAccent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // 4. Ministry & Service Status
          const Text(
            'Active Ministry Service',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldLight,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.volunteer_activism, color: AppTheme.goldLight, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${user.id} • ${user.phoneNumber}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.verified, color: AppTheme.emerald, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified Fellowship Member',
                            style: TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Attendance Rate & Ministry Status
          Row(
            children: [
              // Attendance Score
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderMuted),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Rate',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${user.attendancePercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.attendancePercentage >= 75.0 ? 'Good Standing' : 'At-Risk Warning',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.attendancePercentage >= 75.0 ? AppTheme.emerald : AppTheme.crimson,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Ministry Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderMuted),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ministry Status',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.ministryStatus,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StudentMinistryScreen(state: state),
                            ),
                          );
                        },
                        child: const Row(
                          children: [
                            Text(
                              'Serving Areas',
                              style: TextStyle(fontSize: 11, color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.chevron_right, size: 14, color: AppTheme.goldLight),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. Course Completion Badges
          const Text(
            'Course Badges & Milestones',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.goldLight,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: user.badges.map((badge) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.workspace_premium, color: AppTheme.goldLight, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Voluntary Ministries Action Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF382310),
                  AppTheme.secondaryBg,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.volunteer_activism, color: AppTheme.goldLight, size: 32),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join a Fellowship Ministry',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Choir, Diaconia, Hospitality, Media...',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentMinistryScreen(state: state),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4690B),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Browse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIdField(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppTheme.textTertiary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.secondaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderMuted),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
