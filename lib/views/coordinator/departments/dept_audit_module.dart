part of '../coordinator_hub_screen.dart';

extension DeptAuditModuleExt on _CoordinatorHubScreenState {
  Widget _buildAuditModule(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A65E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5A65E).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, color: Color(0xFFF5A65E), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Audit & Inspection Access Log',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have read-only inspection access across all 10 fellowship sub-committees to verify transparency, constitution compliance, and asset management.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericDepartmentModule(BuildContext context, FellowshipState state, String deptId) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        'Department active and operational.',
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
      ),
    );
  }

}
