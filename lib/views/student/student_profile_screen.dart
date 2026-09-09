import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';
import 'student_ministry_screen.dart';
import 'student_confessor_screen.dart';
import 'student_pilgrimage_screen.dart';
import 'student_charity_screen.dart';
import 'student_mentorship_screen.dart';
import '../admin/admin_approvals_screen.dart';
import '../coordinator/coordinator_hub_screen.dart';

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
    final isDark = theme.brightness == Brightness.dark;

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
                  theme.cardTheme.color ?? theme.colorScheme.surface,
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
                      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
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
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
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
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIdField(context, 'BATCH', user.batchYear),
                      Container(width: 1, height: 28, color: theme.dividerColor),
                      _buildIdField(context, 'DEPT', user.department.split(' ').first),
                      Container(width: 1, height: 28, color: theme.dividerColor),
                      _buildIdField(context, 'YEAR', 'Year ${user.academicYear}'),
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
                Text(
                  'SCAN TO VERIFY FELLOWSHIP MEMBERSHIP',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Scoped Department Coordinator Access Portal
          if (state.activeRole == UserRole.volunteerCoordinator || user.coordinatorProfile != null) ...[
            InteractiveFellowshipCard(
              onTap: () => _navigateTo(context, CoordinatorHubScreen(state: state)),
              borderColor: primaryAccent.withOpacity(0.6),
              gradient: LinearGradient(
                colors: [
                  primaryAccent.withOpacity(0.18),
                  theme.cardTheme.color ?? theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.admin_panel_settings, color: primaryAccent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coordinator Hub • ${user.coordinatorProfile?.departmentNameAmharic ?? 'Department Portal'}',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.coordinatorProfile?.departmentNameEn ?? ''} (${user.coordinatorProfile?.isReadOnlyAudit == true ? 'Audit Mode' : 'Scoped Access'})',
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage applicant queues, screening, and active servant rosters.',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: primaryAccent),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

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
                  context: context,
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
                  context: context,
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
                  context: context,
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
                  context: context,
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

          // 3. Appearance & Theme (የመተግበሪያው ገጽታ)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Appearance & Theme (የመተግበሪያው ገጽታ)',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: primaryAccent.withOpacity(0.3)),
                ),
                child: Text(
                  '3 Presets',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AppThemePalette.values.map((palette) {
                final isSelected = state.currentThemePalette == palette;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    state.setThemePalette(palette);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.palette, color: palette.primaryAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Applied Theme: ${palette.displayName} (${palette.amharicName})',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 220,
                    margin: const EdgeInsets.only(right: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? palette.primaryAccent : palette.borderMuted,
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: palette.primaryAccent.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(palette.isDark ? 0.2 : 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Theme Mode Badge + Selection Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: palette.scaffoldBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: palette.borderMuted),
                              ),
                              child: Text(
                                palette.isDark ? 'DARK SACRED' : 'LIGHT SACRED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: palette.primaryAccent,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? palette.primaryAccent : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? palette.primaryAccent : palette.borderMuted,
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      size: 14,
                                      color: palette.isDark ? Colors.black : Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title & Amharic Title
                        Text(
                          palette.displayName,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: palette.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          palette.amharicName,
                          style: TextStyle(
                            fontSize: 11,
                            color: palette.primaryAccent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          palette.subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: palette.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),

                        // Live Circular Color Swatches (Bg, Card, Primary, Secondary)
                        Row(
                          children: [
                            for (int i = 0; i < palette.swatchColors.length; i++) ...[
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: palette.swatchColors[i],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: palette.isDark ? Colors.white24 : Colors.black12,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.swatchColors[i].withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              if (i < palette.swatchColors.length - 1)
                                const SizedBox(width: 6),
                            ],
                          ],
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
          Text(
            'Active Ministry Service',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.volunteer_activism, color: primaryAccent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${user.id} • ${user.phoneNumber}',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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

          // Attendance Rate & Ministry Status
          Row(
            children: [
              // Attendance Score
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Rate',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${user.attendancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryAccent,
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
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ministry Status',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.ministryStatus,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
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
                        child: Row(
                          children: [
                            Text(
                              'Serving Areas',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.chevron_right, size: 14, color: primaryAccent),
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

          // Course Completion Badges
          Text(
            'Course Badges & Milestones',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
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
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, color: primaryAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
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
              gradient: LinearGradient(
                colors: [
                  primaryAccent.withOpacity(0.18),
                  theme.cardTheme.color ?? theme.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.volunteer_activism, color: primaryAccent, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join a Fellowship Ministry',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choir, Diaconia, Hospitality, Media...',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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
                    backgroundColor: primaryAccent,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Browse', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildIdField(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: textMuted.withOpacity(0.7),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTile({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderCol),
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
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
