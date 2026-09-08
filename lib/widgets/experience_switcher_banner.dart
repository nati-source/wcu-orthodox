import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../state/fellowship_state.dart';
import '../theme/app_theme.dart';

class ExperienceSwitcherBanner extends StatelessWidget {
  final FellowshipState state;

  const ExperienceSwitcherBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: state.activeRole.badgeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: state.activeRole.badgeColor.withOpacity(0.4)),
              ),
              child: Icon(
                state.activeRole == UserRole.admin ? Icons.admin_panel_settings : Icons.school,
                color: state.activeRole.badgeColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACTIVE EXPERIENCE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    state.activeRole.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: state.activeRole.badgeColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  value: state.activeRole,
                  isDense: true,
                  dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                  icon: Icon(Icons.swap_horiz, color: primaryColor, size: 18),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(
                        role.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: role == state.activeRole ? primaryColor : theme.colorScheme.onSurface,
                          fontWeight: role == state.activeRole ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      state.switchRole(newRole);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
