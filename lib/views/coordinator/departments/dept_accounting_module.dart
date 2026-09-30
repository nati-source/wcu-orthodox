part of '../coordinator_hub_screen.dart';

extension DeptAccountingModuleExt on _CoordinatorHubScreenState {
  Widget _buildFinancePropertyModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Church Property & Assets Registry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Icon(Icons.account_balance_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Track sacred vestments, sound system equipment, and liturgical books inventory.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 8: ቋንቋና ልዩ ልዩ ፍላጎት (LANGUAGE & SPECIAL NEEDS)
  // --------------------------------------------------------------------------
}
