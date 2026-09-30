import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentLibraryScreen extends StatelessWidget {
  final FellowshipState state;

  const StudentLibraryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    final items = state.filteredLibraryItems;
    final activeMezmur = state.activeAudioMezmur;

    return Column(
      children: [
        // Search & Category Filters
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Column(
            children: [
              // Search Field
              TextField(
                onChanged: (val) => state.setLibrarySearch(val),
                style: TextStyle(color: textCol, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search liturgical texts, patristics, mezmur...',
                  hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: primaryAccent, size: 20),
                  suffixIcon: state.librarySearchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: textMuted, size: 18),
                          onPressed: () => state.setLibrarySearch(''),
                        )
                      : null,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderCol),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryAccent, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      context: context,
                      label: 'All Material',
                      isSelected: state.selectedCategory == null,
                      onTap: () => state.setLibraryCategory(null),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Patristics (አበው)',
                      isSelected: state.selectedCategory == LibraryCategory.patristics,
                      onTap: () => state.setLibraryCategory(LibraryCategory.patristics),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Liturgical (ቅዳሴ)',
                      isSelected: state.selectedCategory == LibraryCategory.liturgical,
                      onTap: () => state.setLibraryCategory(LibraryCategory.liturgical),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Mezmur Audio (መዝሙር)',
                      isSelected: state.selectedCategory == LibraryCategory.mezmur,
                      onTap: () => state.setLibraryCategory(LibraryCategory.mezmur),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Dogma (ዶግማ)',
                      isSelected: state.selectedCategory == LibraryCategory.dogma,
                      onTap: () => state.setLibraryCategory(LibraryCategory.dogma),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Lives of Saints (ገድላት)',
                      isSelected: state.selectedCategory == LibraryCategory.livesOfSaints,
                      onTap: () => state.setLibraryCategory(LibraryCategory.livesOfSaints),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Scripture (መጽሐፍ ቅዱስ)',
                      isSelected: state.selectedCategory == LibraryCategory.scripture,
                      onTap: () => state.setLibraryCategory(LibraryCategory.scripture),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'Canon & Law (ቀኖና)',
                      isSelected: state.selectedCategory == LibraryCategory.canon,
                      onTap: () => state.setLibraryCategory(LibraryCategory.canon),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      context: context,
                      label: 'General (አጠቃላይ)',
                      isSelected: state.selectedCategory == LibraryCategory.general,
                      onTap: () => state.setLibraryCategory(LibraryCategory.general),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Material List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No material found matching your query.',
                    style: TextStyle(color: textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (index == 0 && state.selectedCategory == null && state.librarySearchQuery.isEmpty) {
                      return _buildFeaturedLibraryCard(context, item);
                    }
                    return _buildStandardLibraryCard(context, item);
                  },
                ),
        ),

        // Persistent Audio Player Bar if Mezmur is playing
        if (activeMezmur != null)
          _buildMezmurPlayerBar(context, activeMezmur),
      ],
    );
  }

  Widget _buildCategoryChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textCol = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryAccent : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : textCol.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(LibraryCategory cat) {
    switch (cat) {
      case LibraryCategory.patristics:
        return Icons.menu_book;
      case LibraryCategory.liturgical:
        return Icons.church_outlined;
      case LibraryCategory.mezmur:
        return Icons.music_note;
      case LibraryCategory.dogma:
        return Icons.shield_outlined;
      case LibraryCategory.livesOfSaints:
        return Icons.auto_awesome;
      case LibraryCategory.scripture:
        return Icons.import_contacts;
      case LibraryCategory.canon:
        return Icons.balance;
      case LibraryCategory.general:
        return Icons.auto_stories;
    }
  }

  Widget _buildFeaturedLibraryCard(BuildContext context, LibraryItemModel item) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Banner / Book Art
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              gradient: LinearGradient(
                colors: [
                  primaryAccent.withOpacity(0.85),
                  primaryAccent.withOpacity(0.4),
                  cardBg,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.auto_stories,
                    size: 90,
                    color: primaryAccent.withOpacity(0.25),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.6) : Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryAccent.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: primaryAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Featured Text',
                          style: TextStyle(color: primaryAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                Wrap(
                  spacing: 6,
                  children: item.tags.map((tag) => _buildTag(context, tag)).toList(),
                ),
                const SizedBox(height: 12),

                // Title & Subtitle
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons: View Details & Telegram Link
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDetailsDialog(context, item),
                        icon: Icon(Icons.info_outline, size: 18, color: isDark ? Colors.black : Colors.white),
                        label: Text(
                          'View Details',
                          style: TextStyle(
                            color: isDark ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => state.launchTelegram(item.telegramUrl),
                        icon: Icon(Icons.send, size: 16, color: primaryAccent),
                        label: Text(
                          'Telegram Link',
                          style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderCol),
                          backgroundColor: elevatedBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (state.isAdmin || state.activeRole == UserRole.admin || state.activeRole == UserRole.volunteerCoordinator) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 22),
                        tooltip: 'Delete Material',
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.crimson.withOpacity(0.12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: cardBg,
                              title: const Row(
                                children: [
                                  Icon(Icons.delete_forever, color: AppTheme.crimson, size: 22),
                                  SizedBox(width: 8),
                                  Text('Delete Material?'),
                                ],
                              ),
                              content: Text('Remove "${item.title}" from the digital library? This will delete it from Cloud Firestore in real time.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text('Cancel', style: TextStyle(color: textMuted)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    state.deleteLibraryBook(item.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('"${item.title}" was removed from the digital library.'),
                                        backgroundColor: cardBg,
                                      ),
                                    );
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardLibraryCard(BuildContext context, LibraryItemModel item) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryAccent.withOpacity(0.3)),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: primaryAccent,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: item.tags.map((t) => _buildTag(context, t)).toList(),
                    ),
                  ],
                ),
              ),

              // Open Telegram Link Action
              IconButton(
                icon: Icon(Icons.open_in_new, color: primaryAccent, size: 20),
                onPressed: () => state.launchTelegram(item.telegramUrl),
                tooltip: 'Open in Telegram Channel',
              ),
              if (state.isAdmin || state.activeRole == UserRole.admin || state.activeRole == UserRole.volunteerCoordinator)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 20),
                  tooltip: 'Delete Material from Database',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardBg,
                        title: const Row(
                          children: [
                            Icon(Icons.delete_forever, color: AppTheme.crimson, size: 22),
                            SizedBox(width: 8),
                            Text('Delete Material?'),
                          ],
                        ),
                        content: Text('Remove "${item.title}" from the digital library? This will delete it for all users in real time.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Cancel', style: TextStyle(color: textMuted)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                            onPressed: () {
                              Navigator.pop(ctx);
                              state.deleteLibraryBook(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${item.title}" was deleted from digital library.'),
                                  backgroundColor: cardBg,
                                ),
                              );
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Action row (Details / Play Mezmur)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.readTime ?? item.audioDuration ?? 'WCU Orthodox Archive',
                  style: TextStyle(fontSize: 11, color: textMuted.withOpacity(0.8)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.category == LibraryCategory.mezmur) ...[
                    InkWell(
                      onTap: () => state.playMezmur(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: primaryAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, color: primaryAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Play Mezmur',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  TextButton(
                    onPressed: () => _openDetailsDialog(context, item),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(
                      'Details',
                      style: TextStyle(color: primaryAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMezmurPlayerBar(BuildContext context, LibraryItemModel item) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: primaryAccent, width: 2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.music_note, color: primaryAccent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'St. Yaredic Hymn • ${item.audioDuration ?? 'Playing'}',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    state.isAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: primaryAccent,
                    size: 32,
                  ),
                  onPressed: () => state.toggleAudioPlayback(),
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new, color: primaryAccent, size: 20),
                  onPressed: () => state.launchTelegram(item.telegramUrl),
                  tooltip: 'Open Telegram Audio',
                ),
              ],
            ),
            // Progress Bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: primaryAccent,
                inactiveTrackColor: elevatedBg,
                thumbColor: primaryAccent,
              ),
              child: Slider(
                value: state.audioProgress,
                onChanged: (val) => state.setAudioProgress(val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetailsDialog(BuildContext context, LibraryItemModel item) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.title,
          style: TextStyle(fontFamily: 'serif', color: textCol, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.subtitle,
                style: TextStyle(color: primaryAccent, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.45),
              ),
              if (item.lyricsOrExcerpts != null) ...[
                const SizedBox(height: 14),
                Text(
                  'Liturgical Text / Lyrics:',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: elevatedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderCol),
                  ),
                  child: Text(
                    item.lyricsOrExcerpts!,
                    style: TextStyle(fontFamily: 'serif', color: textCol, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.telegram, color: Color(0xFF38A3E5), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Direct Telegram Link to Material',
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              state.launchTelegram(item.telegramUrl);
            },
            icon: Icon(Icons.send, size: 16, color: isDark ? Colors.black : Colors.white),
            label: Text(
              'Open in Telegram',
              style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: elevatedBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600),
      ),
    );
  }
}
