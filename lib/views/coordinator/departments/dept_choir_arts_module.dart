part of '../coordinator_hub_screen.dart';

extension DeptChoirArtsModuleExt on _CoordinatorHubScreenState {
  Widget _buildChoirAndArtsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'የዝማሬና ስነ-ጥበባት አስተዳደር (CHOIR & SACRED ARTS CONTROL)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),

        // Dual Wing Filter Selector with SingleChildScrollView to prevent overflow
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All Wings (ሁለቱም)'),
                selected: _choirWingFilter == null,
                onSelected: (val) => _updateUi(() => _choirWingFilter = null),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('St. Yared Mezmur'),
                selected: _choirWingFilter == ChoirWingType.mezmur,
                onSelected: (val) => _updateUi(() => _choirWingFilter = ChoirWingType.mezmur),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Fine Arts & Drama'),
                selected: _choirWingFilter == ChoirWingType.fineArts,
                onSelected: (val) => _updateUi(() => _choirWingFilter = ChoirWingType.fineArts),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Practice & Liturgy Rehearsal Schedule Card
        Container(
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
                    child: Text('Weekly Liturgy Rehearsal Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.music_note, color: primaryAccent, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              _buildScheduleRow(context, 'Friday 11:30 LT', 'Saint Yared Digua & Mahlet Practice (Ge\'ez)'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Saturday 10:00 LT', 'Sunday Liturgy Choir Hymns & Drum (Kebero) Roster'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Sunday 2:00 LT', 'Sunday School Drama & Orthodox Poetry Rehearsal'),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 6: ባችና መርሐ ግብራት (BATCH & PROGRAMS COORDINATION)
  // Dedicated to: Interactive Pilgrimage Management (Add/Edit/Delete Trips & Pilgrims, Money Control & Approvals)
  // --------------------------------------------------------------------------
}
