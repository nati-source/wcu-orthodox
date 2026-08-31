import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentLibraryScreen extends StatelessWidget {
  final FellowshipState state;

  const StudentLibraryScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
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
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search liturgical texts, patristics, mezmur...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.goldAccent, size: 20),
                  suffixIcon: state.librarySearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textTertiary, size: 18),
                          onPressed: () => state.setLibrarySearch(''),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip(
                      label: 'All Material',
                      isSelected: state.selectedCategory == null,
                      onTap: () => state.setLibraryCategory(null),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: 'Patristics',
                      isSelected: state.selectedCategory == LibraryCategory.patristics,
                      onTap: () => state.setLibraryCategory(LibraryCategory.patristics),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: 'Liturgical',
                      isSelected: state.selectedCategory == LibraryCategory.liturgical,
                      onTap: () => state.setLibraryCategory(LibraryCategory.liturgical),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: 'Mezmur Audio',
                      isSelected: state.selectedCategory == LibraryCategory.mezmur,
                      onTap: () => state.setLibraryCategory(LibraryCategory.mezmur),
                    ),
                    const SizedBox(width: 8),
                    _buildCategoryChip(
                      label: 'Dogma',
                      isSelected: state.selectedCategory == LibraryCategory.dogma,
                      onTap: () => state.setLibraryCategory(LibraryCategory.dogma),
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
              ? const Center(
                  child: Text(
                    'No material found matching your query.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (index == 0 && state.selectedCategory == null && state.librarySearchQuery.isEmpty) {
                      // Featured Item Card (Matching Top of screen5 - Copy.png)
                      return _buildFeaturedLibraryCard(context, item);
                    }
                    // Standard Card
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
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldAccent : AppTheme.secondaryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.goldLight : AppTheme.borderMuted,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedLibraryCard(BuildContext context, LibraryItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderMuted),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
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
                  const Color(0xFF4A2F0F),
                  const Color(0xFF23180C),
                  AppTheme.secondaryBg,
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
                    color: AppTheme.goldLight.withOpacity(0.25),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: AppTheme.goldLight, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Featured Text',
                          style: TextStyle(color: AppTheme.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
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
                  children: item.tags.map((tag) => _buildTag(tag)).toList(),
                ),
                const SizedBox(height: 12),

                // Title & Subtitle
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFF5A65E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons: View Details & Telegram Link (Matching screen5 - Copy.png)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openDetailsDialog(context, item),
                        icon: const Icon(Icons.info_outline, size: 18, color: Colors.black),
                        label: const Text(
                          'View Details',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE57E12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => state.launchTelegram(item.telegramUrl),
                        icon: const Icon(Icons.send, size: 16, color: AppTheme.goldLight),
                        label: const Text(
                          'Telegram Link',
                          style: TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.borderMuted),
                          backgroundColor: const Color(0xFF222B3A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderMuted),
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
                  color: const Color(0xFF222B3A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
                ),
                child: Center(
                  child: Icon(
                    item.category == LibraryCategory.mezmur
                        ? Icons.music_note
                        : item.category == LibraryCategory.patristics
                            ? Icons.menu_book
                            : Icons.auto_stories,
                    color: AppTheme.goldLight,
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
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: item.tags.map((t) => _buildTag(t)).toList(),
                    ),
                  ],
                ),
              ),

              // Open Telegram Link Action
              IconButton(
                icon: const Icon(Icons.open_in_new, color: AppTheme.goldLight, size: 20),
                onPressed: () => state.launchTelegram(item.telegramUrl),
                tooltip: 'Open in Telegram Channel',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action row (Details / Play Mezmur)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.readTime ?? item.audioDuration ?? 'WCU Orthodox Archive',
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
              Row(
                children: [
                  if (item.category == LibraryCategory.mezmur) ...[
                    InkWell(
                      onTap: () => state.playMezmur(item),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.goldAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.play_arrow, color: AppTheme.goldLight, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Play Mezmur',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.goldLight),
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
                    child: const Text(
                      'Details',
                      style: TextStyle(color: AppTheme.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF192230),
        border: const Border(top: BorderSide(color: Color(0xFFD4690B), width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
                const Icon(Icons.music_note, color: AppTheme.goldLight, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'St. Yaredic Hymn • ${item.audioDuration ?? 'Playing'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    state.isAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: const Color(0xFFF5A65E),
                    size: 32,
                  ),
                  onPressed: () => state.toggleAudioPlayback(),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: AppTheme.goldLight, size: 20),
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
                activeTrackColor: const Color(0xFFE57E12),
                inactiveTrackColor: AppTheme.surfaceElevated,
                thumbColor: AppTheme.goldLight,
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.title,
          style: const TextStyle(fontFamily: 'serif', color: AppTheme.goldLight, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.subtitle,
                style: const TextStyle(color: Color(0xFFF5A65E), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Text(
                item.description,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
              ),
              if (item.lyricsOrExcerpts != null) ...[
                const SizedBox(height: 14),
                const Text(
                  'Liturgical Text / Lyrics:',
                  style: TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderMuted),
                  ),
                  child: Text(
                    item.lyricsOrExcerpts!,
                    style: const TextStyle(fontFamily: 'serif', color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.telegram, color: Color(0xFF38A3E5), size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Direct Telegram Link to Material',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
            child: const Text('Close', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              state.launchTelegram(item.telegramUrl);
            },
            icon: const Icon(Icons.send, size: 16, color: Colors.white),
            label: const Text('Open in Telegram', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4690B)),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF222B3A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderMuted.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, color: AppTheme.goldLight, fontWeight: FontWeight.w600),
      ),
    );
  }
}
