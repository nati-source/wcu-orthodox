import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final isCoordinator = state.activeRole == UserRole.volunteerCoordinator;
    final coordProfile = state.currentUser.coordinatorProfile;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: state.activeRole.badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: state.activeRole.badgeColor.withOpacity(0.4)),
                  ),
                  child: Icon(
                    state.activeRole == UserRole.admin
                        ? Icons.admin_panel_settings
                        : state.activeRole == UserRole.volunteerCoordinator
                            ? Icons.verified_user
                            : state.activeRole == UserRole.spiritualParent
                                ? Icons.family_restroom
                                : Icons.school,
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
                Flexible(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 150),
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
                        isExpanded: true,
                        dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                        icon: Icon(Icons.swap_horiz, color: primaryColor, size: 18),
                        items: state.availableRoles.map((role) {
                          return DropdownMenuItem<UserRole>(
                            value: role,
                            child: Text(
                              role.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                            HapticFeedback.selectionClick();
                            state.switchRole(newRole);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Secondary row for Volunteer Coordinator Department Switching
            if (isCoordinator && coordProfile != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: coordProfile.isReadOnlyAudit
                      ? const Color(0xFFF5A65E).withOpacity(0.12)
                      : primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: coordProfile.isReadOnlyAudit
                        ? const Color(0xFFF5A65E).withOpacity(0.4)
                        : primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      coordProfile.isReadOnlyAudit ? Icons.fact_check_outlined : Icons.account_tree_outlined,
                      size: 14,
                      color: coordProfile.isReadOnlyAudit ? const Color(0xFFF5A65E) : primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scoped: ${coordProfile.departmentNameAmharic} (${coordProfile.isReadOnlyAudit ? 'Audit Inspection' : 'Coordinator'})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: coordProfile.isReadOnlyAudit ? const Color(0xFFF5A65E) : primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Switch Coordinator Department',
                      icon: Icon(Icons.arrow_drop_down_circle_outlined, size: 16, color: primaryColor),
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      onSelected: (deptId) {
                        HapticFeedback.mediumImpact();
                        state.switchCoordinatorDepartment(deptId);
                      },
                      itemBuilder: (ctx) {
                        return FellowshipDepartmentConstants.allDepartmentIds.map((deptId) {
                          final isCurrent = deptId == coordProfile.departmentId;
                          final isAudit = deptId == FellowshipDepartmentConstants.deptAudit;
                          return PopupMenuItem<String>(
                            value: deptId,
                            child: Row(
                              children: [
                                Icon(
                                  isAudit ? Icons.fact_check_outlined : Icons.hub_outlined,
                                  size: 16,
                                  color: isCurrent ? primaryColor : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${FellowshipDepartmentConstants.getNameAmharic(deptId)} ${isAudit ? '(Audit)' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                      color: isCurrent ? primaryColor : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
