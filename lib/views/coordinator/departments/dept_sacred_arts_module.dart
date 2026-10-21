part of '../coordinator_hub_screen.dart';

extension DeptSacredArtsModuleExt on _CoordinatorHubScreenState {
  Widget _buildSacredArtsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.brush_rounded, color: primaryAccent, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'የስነ ጥበባትና ጽሕፈት አስተዳደር',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  Text(
                    'Orthodox Iconography, Drama, Poetry & Ecclesiastical Literature',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 1. Orthodox Iconography & Church Artistry Inventory
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
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
                    child: Text(
                      'Sacred Iconography & Calligraphy Registry',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.palette_outlined, color: primaryAccent, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              _buildArtItemTile(context, 'ሥዕለ ቅድስት ድንግል ማርያም (ወላዲተ አምላክ)', 'Traditional Parchment • Tempera Medium', 'Main Sanctuary Icon'),
              const SizedBox(height: 6),
              _buildArtItemTile(context, 'ሥዕለ ቅዱስ ጊዮርጊስ ሰማዕት', 'Canvas Reproduction • Feast Display', 'Youth Hall'),
              const SizedBox(height: 6),
              _buildArtItemTile(context, 'የግዕዝ ፊደላትና ብራና ጽሕፈት ስልጠና', 'Weekly Saturday Calligraphy Workshop', 'Active Course'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Orthodox Drama & Poetry (Kine) Rehearsal Schedule
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
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
                    child: Text(
                      'Spiritual Drama & Orthodox Poetry Rehearsals',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.theater_comedy_outlined, color: primaryAccent, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              _buildScheduleRow(context, 'Saturday 8:00 LT', 'Feast of the Cross (መስቀል) Script Read-Through'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Sunday 2:00 LT', 'Sunday School Drama & Stage Blocking Rehearsal'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Wednesday 11:30 LT', 'Orthodox Poetry (ስንኝና ግጥም) Composition Circle'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Sacred Arts Sub-Wings & Artisan Directory
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Artisan Units & Specialized Guilds (የጥበብ ዘርፎች)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildArtisanChip(context, 'Iconographers (ስዕለ አድኅኖ)', '8 Artisans', Icons.brush),
                  _buildArtisanChip(context, 'Stage & Actors (መንፈሳዊ ድራማ)', '14 Servants', Icons.theater_comedy),
                  _buildArtisanChip(context, 'Poets & Writers (ስነ ጽሑፍ)', '9 Writers', Icons.edit_note),
                  _buildArtisanChip(context, 'Illumination & Exhibitions (አውደ ርዕይ)', '7 Curators', Icons.auto_stories),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Action Toolbar
        if (!isAudit)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Drama script & cast roster saved.')),
                  );
                },
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('Manage Scripts', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New Sacred Iconography catalog entry opened.')),
                  );
                },
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 14),
                label: const Text('Register Icon / Artwork', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildArtItemTile(BuildContext context, String title, String subtitle, String tag) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: elevatedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.image_outlined, size: 14, color: primaryAccent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: primaryAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildArtisanChip(BuildContext context, String label, String count, IconData icon) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 64),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: elevatedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  count,
                  style: TextStyle(fontSize: 9, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
