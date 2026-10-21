part of '../coordinator_hub_screen.dart';

extension DeptChoirModuleExt on _CoordinatorHubScreenState {
  Widget _buildChoirModule(BuildContext context, FellowshipState state, bool isAudit) {
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
              child: Icon(Icons.music_note_rounded, color: primaryAccent, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'የመዝሙር ክፍል አስተዳደር',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  Text(
                    'Yaredic Hymnography, Zema & Liturgical Choir',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 1. Weekly Liturgy & Rehearsal Schedule Card
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
                      'Weekly Liturgy Rehearsal Schedule',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.calendar_month_outlined, color: primaryAccent, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              _buildScheduleRow(context, 'Friday 11:30 LT', 'Saint Yared Digua & Mahlet Practice (Ge\'ez)'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Saturday 10:00 LT', 'Sunday Liturgy Choir Hymns & Drum (Kebero) Roster'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Sunday 12:00 LT', 'Begena & Kirar Instrumental Repertoire Review'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Vocal Sections & Instrument Wing Breakdown
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
                'Vocal Sections & Instruments (የድምጽና መሳሪያ ዘርፎች)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildChoirSectionChip(context, 'Soprano (ዜማ መሪ)', '18 Servants', Icons.record_voice_over),
                  _buildChoirSectionChip(context, 'Alto / Tenor (ተቀባይ)', '22 Servants', Icons.groups),
                  _buildChoirSectionChip(context, 'Kebero & Tsenatsil (ከበሮ)', '8 Servants', Icons.album),
                  _buildChoirSectionChip(context, 'Begena (በገና)', '6 Servants', Icons.music_note),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Sacred Liturgical Repertoire Library
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
                      'Active Hymn Repertoire Library',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '36 Hymns Active',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildHymnItemTile(context, 'አክሊለ ጽጌ ማርያም (Aklile Tsige)', 'Ge\'ez Feast Chant • Tsome Tsige', 'Mahlet Mode'),
              const SizedBox(height: 6),
              _buildHymnItemTile(context, 'ሰላም ለኪ ማርያም (Selam Leki)', 'Liturgy Entrance Hymn', 'Geez / Ezel Mode'),
              const SizedBox(height: 6),
              _buildHymnItemTile(context, 'በስመ አብ ወወልድ (Besme Ab)', 'Sunday Morning Service Chant', 'Araray Mode'),
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
                    const SnackBar(content: Text('Attendance sheet for Choir Rehearsal generated.')),
                  );
                },
                icon: const Icon(Icons.fact_check_outlined, size: 14),
                label: const Text('Practice Attendance', style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Repertoire roster updated and synced with choir members.')),
                  );
                },
                icon: const Icon(Icons.playlist_add_check, size: 14),
                label: const Text('Sync Repertoire', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildChoirSectionChip(BuildContext context, String label, String count, IconData icon) {
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

  Widget _buildHymnItemTile(BuildContext context, String title, String subtitle, String mode) {
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
            child: Icon(Icons.library_music_outlined, size: 14, color: primaryAccent),
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
            child: Text(mode, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryAccent)),
          ),
        ],
      ),
    );
  }
}
