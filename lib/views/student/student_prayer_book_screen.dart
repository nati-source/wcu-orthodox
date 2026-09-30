import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentPrayerBookScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentPrayerBookScreen({super.key, required this.state});

  @override
  State<StudentPrayerBookScreen> createState() => _StudentPrayerBookScreenState();
}

class _StudentPrayerBookScreenState extends State<StudentPrayerBookScreen> {
  int _activeBookIndex = 0; // 0: Wudase Maryam, 1: Yezewetir Tselot
  bool _showGeEz = true;
  bool _showAmharic = true;

  final List<String> _daysShort = ['ሰኞ (Mon)', 'ማክሰኞ (Tue)', 'ረቡዕ (Wed)', 'ሐሙስ (Thu)', 'ዓርብ (Fri)', 'ቅዳሜ (Sat)', 'እሑድ (Sun)'];

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final state = widget.state;
    final wudase = state.wudaseMaryam;
    final yezewetir = state.yezewetirTselot;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Daily Prayer Book • የጸሎት መጽሐፍ', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Font scaling button
          IconButton(
            icon: Icon(Icons.format_size, color: primaryAccent),
            onPressed: () => _showFontSizeBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Top Book Selector Pill Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeBookIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeBookIndex == 0 ? elevatedBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _activeBookIndex == 0 ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
                      ),
                      child: Text(
                        'ውዳሴ ማርያም (Wudase)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _activeBookIndex == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _activeBookIndex == 0 ? primaryAccent : textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeBookIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeBookIndex == 1 ? elevatedBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _activeBookIndex == 1 ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
                      ),
                      child: Text(
                        'የዘወትር ጸሎት (Daily)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _activeBookIndex == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _activeBookIndex == 1 ? primaryAccent : textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Day Selector Bar (For Wudase Maryam)
          if (_activeBookIndex == 0)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _daysShort.length,
                itemBuilder: (context, index) {
                  final isSelected = state.selectedPrayerDayIndex == index;
                  return GestureDetector(
                    onTap: () => state.setPrayerDay(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? elevatedBg : cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primaryAccent : borderCol,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _daysShort[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? primaryAccent : textMuted,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. Language Filter Toggle Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _showGeEz,
                          label: Text(
                            'ግዕዝ (Ge\'ez)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _showGeEz
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textCol.withOpacity(0.8),
                            ),
                          ),
                          selectedColor: primaryAccent,
                          checkmarkColor: isDark ? Colors.black : Colors.white,
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: _showGeEz ? primaryAccent : borderCol),
                          ),
                          onSelected: (val) {
                            if (!_showAmharic && !val) return; // Keep at least one
                            setState(() => _showGeEz = val);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          selected: _showAmharic,
                          label: Text(
                            'አማርኛ (Amharic)',
                            style: TextStyle(
                              fontSize: 11,
                              color: _showAmharic
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textCol.withOpacity(0.8),
                            ),
                          ),
                          selectedColor: primaryAccent,
                          checkmarkColor: isDark ? Colors.black : Colors.white,
                          backgroundColor: cardBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: _showAmharic ? primaryAccent : borderCol),
                          ),
                          onSelected: (val) {
                            if (!_showGeEz && !val) return; // Keep at least one
                            setState(() => _showAmharic = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Font: ${state.prayerFontSize.toInt()} pt',
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          ),

          Divider(color: borderCol, height: 1),

          // 4. Main Prayer Scroll Content
          Expanded(
            child: _activeBookIndex == 0
                ? _buildWudaseContent(context, wudase.sections[state.selectedPrayerDayIndex], state.prayerFontSize)
                : _buildYezewetirContent(context, yezewetir.sections, state.prayerFontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildWudaseContent(BuildContext context, PrayerSectionModel section, double fontSize) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryAccent.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Icon(Icons.church_outlined, color: primaryAccent, size: 28),
              const SizedBox(height: 6),
              Text(
                section.titleGeEz,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.titleAmharic,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_showGeEz) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories, color: primaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'ግዕዝ (Ge\'ez Text)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  section.geEzText,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: fontSize,
                    color: textCol,
                    height: 1.8,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (_showAmharic) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.translate, color: primaryAccent, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'አማርኛ ትርጉም (Amharic Translation)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  section.amharicText,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: textCol.withOpacity(0.9),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildYezewetirContent(BuildContext context, List<PrayerSectionModel> sections, double fontSize) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final sec = sections[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sec.titleGeEz,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sec.titleAmharic,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 14),
              if (_showGeEz) ...[
                Text(
                  sec.geEzText,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: fontSize,
                    color: textCol,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_showAmharic) ...[
                Text(
                  sec.amharicText,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: textCol.withOpacity(0.9),
                    height: 1.7,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showFontSizeBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final state = widget.state;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Adjust Prayer Text Size',
                    style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change text scale for comfortable night prayer reading in dorms.',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('A', style: TextStyle(fontSize: 14, color: textMuted)),
                      Expanded(
                        child: Slider(
                          value: state.prayerFontSize,
                          min: 12.0,
                          max: 26.0,
                          divisions: 7,
                          activeColor: primaryAccent,
                          inactiveColor: elevatedBg,
                          onChanged: (val) {
                            setSheetState(() {});
                            state.setPrayerFontSize(val);
                          },
                        ),
                      ),
                      Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryAccent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Preview: ${state.prayerFontSize.toInt()} pt',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
