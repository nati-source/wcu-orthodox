import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_models.dart';
import '../state/fellowship_state.dart';
import '../theme/app_theme.dart';
import 'wcu_brand_logo.dart';

class OrthodoxHeader extends StatelessWidget {
  final FellowshipState state;
  final String title;
  final String? subtitle;
  final VoidCallback? onQrTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showQrIcon;

  const OrthodoxHeader({
    super.key,
    required this.state,
    this.title = 'Wachamo University Fellowship',
    this.subtitle,
    this.onQrTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.showQrIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emergency Broadcast Toast/Banner if active
        if (state.latestEmergencyBroadcast != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.crimson.withOpacity(0.25),
                  AppTheme.crimsonBg.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.crimson.withOpacity(0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign, color: AppTheme.crimson, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.latestEmergencyBroadcast!.title,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.latestEmergencyBroadcast!.description,
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (state.isAdmin || state.activeRole == UserRole.admin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 20),
                    tooltip: 'Delete broadcast from database',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final broadcast = state.latestEmergencyBroadcast;
                      if (broadcast == null) return;
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          actionsOverflowButtonSpacing: 8,
                          actionsOverflowDirection: VerticalDirection.down,
                          actionsAlignment: MainAxisAlignment.end,
                          title: const Row(
                            children: [
                              Icon(Icons.delete_forever, color: AppTheme.crimson, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Delete Broadcast?', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          content: Text(
                            'Permanently delete "${broadcast.title}" from the cloud database? It will be removed from all student devices in real time.',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await state.deleteEmergencyBroadcast(broadcast.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Emergency broadcast removed from database.')),
                                  );
                                }
                              },
                              child: const Text('Delete from DB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, size: 18),
                  tooltip: 'Dismiss',
                  onPressed: () => state.dismissEmergencyBanner(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

        // Main Header Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            children: [
              // The shared fellowship mark opens the app's identity details.
              Tooltip(
                message: 'About WCU Gibi Gubae',
                child: WcuBrandLogo(
                  markSize: 36,
                  showName: false,
                  showAmharic: false,
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'WCU Gibi Gubae',
                    applicationVersion: '1.3.6',
                    applicationLegalese:
                        'Wachemo University Orthodox Fellowship\nየዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ',
                    applicationIcon: const WcuBrandLogo(
                      markSize: 48,
                      showName: false,
                      showAmharic: false,
                    ),
                    children: const [
                      Text('Faith • Fellowship • Service'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: onProfileTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Quick Return to Admin Button when Admin is previewing Student or Coordinator
              if (state.isAuthorizedAdmin && state.activeRole != UserRole.admin)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      state.switchRole(UserRole.admin);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.gold, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: AppTheme.gold, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Dedicated Theme Toggle Action Button
              IconButton(
                tooltip: 'Theme: ${state.currentThemePalette.displayName} — Tap to switch',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withOpacity(0.4)),
                  ),
                  child: Icon(
                    state.currentThemePalette.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final nextIndex = (state.currentThemePalette.index + 1) % AppThemePalette.values.length;
                  final nextPalette = AppThemePalette.values[nextIndex];
                  state.setThemePalette(nextPalette);

                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: nextPalette.cardBg,
                      content: Row(
                        children: [
                          Icon(
                            nextPalette.isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                            color: nextPalette.primaryAccent,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Theme: ${nextPalette.displayName}',
                                  style: TextStyle(
                                    color: nextPalette.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  nextPalette.amharicName,
                                  style: TextStyle(
                                    color: nextPalette.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(milliseconds: 1800),
                    ),
                  );
                },
              ),
              if (showQrIcon && onQrTap != null)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withOpacity(0.4)),
                    ),
                    child: Icon(Icons.qr_code_scanner, color: primaryColor, size: 20),
                  ),
                  onPressed: onQrTap,
                  tooltip: 'Dynamic QR Scanner',
                ),
              if (onNotificationTap != null)
                IconButton(
                  icon: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ?? theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Icon(Icons.notifications_none, color: theme.colorScheme.onSurface, size: 20),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: onNotificationTap,
                  tooltip: 'Notifications',
                ),
              if (onProfileTap != null)
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(Icons.person_outline, color: theme.colorScheme.onSurface, size: 20),
                  ),
                  onPressed: onProfileTap,
                  tooltip: 'Profile & Settings • መገለጫ',
                ),
            ],
          ),
        ),
      ],
    );
  }
}
