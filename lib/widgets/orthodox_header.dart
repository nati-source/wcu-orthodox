import 'package:flutter/material.dart';
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
                IconButton(
                  icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, size: 18),
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
              // Orthodox Fellowship Icon Emblem
              Container(
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
