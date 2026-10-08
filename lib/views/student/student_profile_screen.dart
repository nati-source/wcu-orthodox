import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';
import 'student_ministry_screen.dart';
import 'student_confessor_screen.dart';
import 'student_pilgrimage_screen.dart';
import 'student_charity_screen.dart';
import 'student_mentorship_screen.dart';
import '../coordinator/coordinator_hub_screen.dart';
import '../help/user_guide_screen.dart';

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
                      Expanded(child: _buildIdField(context, 'BATCH', user.batchYear)),
                      Container(width: 1, height: 28, color: theme.dividerColor),
                      Expanded(child: _buildIdField(context, 'DEPT', user.department.trim().isEmpty ? 'General' : user.department.trim().split(' ').first)),
                      Container(width: 1, height: 28, color: theme.dividerColor),
                      Expanded(child: _buildIdField(context, 'YEAR', 'Year ${user.academicYear}')),
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
                    backgroundColor: Colors.white,
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
              Expanded(
                child: Text(
                  'Appearance & Theme (የመተግበሪያው ገጽታ)',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryAccent,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
                          const Flexible(
                            child: Text(
                              'Verified Fellowship Member',
                              style: TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                            Flexible(
                              child: Text(
                                'Serving Areas',
                                style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                    Flexible(
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

          // Return to Admin Management Portal Card (if user is authenticated as Admin)
          if (state.authenticatedRole == UserRole.admin && state.activeRole != UserRole.admin) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 18),
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
                border: Border.all(color: AppTheme.crimson.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.crimson.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: AppTheme.crimson, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are viewing as ${state.activeRole.displayName}',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Tap to return to your Admin Dashboard & Oversight controls.',
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.switchRole(UserRole.admin);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.crimson,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Back to Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          // 5. Account & Security Section
          // User Guide Button
          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => UserGuideScreen(state: state),
                  ),
                );
              },
              icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
              label: const Text(
                'App User Guide • የተጠቃሚ መመሪያ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),

          // Change Password Button
          Container(
            width: double.infinity,
            height: 50,
            margin: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () => _openChangePasswordDialog(context),
              icon: const Icon(Icons.lock_reset, color: AppTheme.gold, size: 20),
              label: const Text(
                'Change Password / የይለፍ ቃል ቀይር',
                style: TextStyle(
                  color: AppTheme.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.gold.withOpacity(0.6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: 52,
            margin: const EdgeInsets.only(bottom: 24),
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout, color: AppTheme.crimson, size: 20),
              label: const Text(
                'Sign Out / ከመለያ ውጣ',
                style: TextStyle(
                  color: AppTheme.crimson,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.crimson.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.crimson, size: 22),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out from your fellowship account?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openChangePasswordDialog(BuildContext context) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();
    bool isSaving = false;
    String? errorMsg;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final textCol = theme.colorScheme.onSurface;
          final firebaseUser = AuthService().currentUser;

          return Dialog(
            backgroundColor: AppTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 1.5),
            ),
            insetPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: MediaQuery.of(ctx).viewInsets.bottom > 0 ? 12 : 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_reset, color: AppTheme.gold, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Password',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                              const Text(
                                'የይለፍ ቃል ቀይር',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.gold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.slateMuted, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Enter your current password and choose a secure new password:',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    if (errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.crimson.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.crimson.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.crimson, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMsg!,
                                style: const TextStyle(color: AppTheme.crimson, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Current Password
                    TextField(
                      controller: currentPwController,
                      obscureText: obscureCurrent,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Current Password / የቀድሞ ይለፍ ቃል',
                        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppTheme.gold),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Forgot current password quick link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () async {
                          final email = firebaseUser?.email ?? 'student@wcu.test';
                          if (email.isEmpty) {
                            setDialogState(() => errorMsg = 'No registered email found for this profile.');
                            return;
                          }
                          try {
                            await AuthService().sendPasswordResetEmail(email);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Password reset link sent to $email! Please check your Spam / Inbox.'),
                                  backgroundColor: AppTheme.emerald,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              errorMsg = 'Could not send reset link: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
                            });
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Forgot current password? / ረሱት?',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // New Password
                    TextField(
                      controller: newPwController,
                      obscureText: obscureNew,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'New Password (min 6 characters) / አዲስ ይለፍ ቃል',
                        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18, color: AppTheme.emerald),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Confirm New Password
                    TextField(
                      controller: confirmPwController,
                      obscureText: obscureConfirm,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password / አዲሱን ያረጋግጡ',
                        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.check_circle_outline, size: 18, color: AppTheme.emerald),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                          onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                        filled: true,
                        fillColor: AppTheme.primaryBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.slateMuted)),
                        ),
                        ElevatedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final cur = currentPwController.text.trim();
                                  final newPw = newPwController.text;
                                  final conf = confirmPwController.text;

                                  if (cur.isEmpty) {
                                    setDialogState(() => errorMsg = 'Please enter your current password.');
                                    return;
                                  }
                                  if (newPw.length < 6) {
                                    setDialogState(() => errorMsg = 'New password must be at least 6 characters.');
                                    return;
                                  }
                                  if (newPw != conf) {
                                    setDialogState(() => errorMsg = 'New passwords do not match.');
                                    return;
                                  }

                                  setDialogState(() {
                                    isSaving = true;
                                    errorMsg = null;
                                  });

                                  // If in local/demo mode (no active Firebase user logged in)
                                  if (firebaseUser == null) {
                                    await Future.delayed(const Duration(milliseconds: 500));
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                                              SizedBox(width: 10),
                                              Expanded(child: Text('Password updated successfully! (Demo / Offline mode)')),
                                            ],
                                          ),
                                          backgroundColor: AppTheme.emerald,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  try {
                                    await AuthService().updatePassword(
                                      currentPassword: cur,
                                      newPassword: newPw,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                                              SizedBox(width: 10),
                                              Text('Password changed successfully!'),
                                            ],
                                          ),
                                          backgroundColor: AppTheme.emerald,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() {
                                      isSaving = false;
                                      final err = e.toString();
                                      if (err.contains('wrong-password') || err.contains('invalid-credential')) {
                                        errorMsg = 'Current password is incorrect. Please check and try again.';
                                      } else if (err.contains('weak-password')) {
                                        errorMsg = 'Password is too weak. Please use at least 6 characters.';
                                      } else if (err.contains('requires-recent-login')) {
                                        errorMsg = 'For security, please sign out and sign back in before changing your password.';
                                      } else if (err.contains('network-request-failed')) {
                                        errorMsg = 'Network error. Please check your internet connection.';
                                      } else {
                                        errorMsg = 'Failed: ${err.replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
                                      }
                                    });
                                  }
                                },
                          icon: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070F1E)))
                              : const Icon(Icons.check, size: 18),
                          label: const Text('Update Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: const Color(0xFF070F1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: textCol,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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
                  Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
