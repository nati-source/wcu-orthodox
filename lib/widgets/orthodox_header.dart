import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../state/fellowship_state.dart';
import '../theme/app_theme.dart';

class OrthodoxHeader extends StatelessWidget {
  final FellowshipState state;
  final String title;
  final String? subtitle;
  final VoidCallback? onQrTap;
  final VoidCallback? onNotificationTap;
  final bool showQrIcon;

  const OrthodoxHeader({
    super.key,
    required this.state,
    this.title = 'Wachamo University Fellowship',
    this.subtitle,
    this.onQrTap,
    this.onNotificationTap,
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
                          title: const Row(
                            children: [
                              Icon(Icons.delete_forever, color: AppTheme.crimson, size: 24),
                              SizedBox(width: 8),
                              Text('Delete Broadcast?'),
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
              // Orthodox Fellowship Icon Emblem (Long-press toggles Dev Role Switcher for debugging)
              GestureDetector(
                onLongPress: () {
                  // Only allow toggling dev role switcher if user is Admin
                  if (state.currentUser.role != UserRole.admin && state.activeRole != UserRole.admin && !state.showDevRoleSwitcher) {
                    return;
                  }
                  state.toggleDevRoleSwitcher();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: state.showDevRoleSwitcher ? AppTheme.gold : AppTheme.surfaceElevated,
                      content: Row(
                        children: [
                          Icon(
                            state.showDevRoleSwitcher ? Icons.build_circle : Icons.lock_outline,
                            color: state.showDevRoleSwitcher ? const Color(0xFF070F1E) : Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.showDevRoleSwitcher
                                  ? '🛠️ Developer Mode ON: Role Switcher unlocked'
                                  : '🔒 Developer Mode OFF: Role Switcher hidden',
                              style: TextStyle(
                                color: state.showDevRoleSwitcher ? const Color(0xFF070F1E) : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor.withOpacity(0.35),
                        theme.cardTheme.color ?? theme.colorScheme.surface,
                      ],
                    ),
                    border: Border.all(color: primaryColor.withOpacity(0.6), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.wb_sunny_outlined, color: primaryColor, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
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
            ],
          ),
        ),
      ],
    );
  }
}
