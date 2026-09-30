part of '../coordinator_hub_screen.dart';

extension DeptLanguageModuleExt on _CoordinatorHubScreenState {
  Widget _buildSpecialNeedsModule(BuildContext context, FellowshipState state, bool isAudit) {
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
                child: Text('Multilingual & Sign-Language Services', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Icon(Icons.translate_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Translation rosters for Afaan Oromoo, Tigrinya, English, and Geez liturgical texts, plus sign-language interpreter duty shifts.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 9: እቅድና ክትትል (PLANNING & MONITORING)
  // --------------------------------------------------------------------------
}
