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
    final state = widget.state;
    final wudase = state.wudaseMaryam;
    final yezewetir = state.yezewetirTselot;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Daily Prayer Book • የጸሎት መጽሐፍ'),
        backgroundColor: AppTheme.primaryBg,
        elevation: 0,
        actions: [
          // Font scaling button
          IconButton(
            icon: const Icon(Icons.format_size, color: AppTheme.goldLight),
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
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeBookIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeBookIndex == 0 ? AppTheme.surfaceElevated : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _activeBookIndex == 0 ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
                      ),
                      child: Text(
                        'ውዳሴ ማርያም (Wudase)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _activeBookIndex == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _activeBookIndex == 0 ? const Color(0xFFF5A65E) : AppTheme.textSecondary,
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
                        color: _activeBookIndex == 1 ? AppTheme.surfaceElevated : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: _activeBookIndex == 1 ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
                      ),
                      child: Text(
                        'የዘወትር ጸሎት (Daily)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _activeBookIndex == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _activeBookIndex == 1 ? const Color(0xFFF5A65E) : AppTheme.textSecondary,
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
                        color: isSelected ? const Color(0xFF2C374A) : AppTheme.secondaryBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppTheme.goldAccent : AppTheme.borderMuted,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _daysShort[index],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFFF5A65E) : AppTheme.textSecondary,
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
                Row(
                  children: [
                    FilterChip(
                      selected: _showGeEz,
                      label: const Text('ግዕዝ (Ge\'ez)', style: TextStyle(fontSize: 11)),
                      selectedColor: AppTheme.goldAccent.withOpacity(0.2),
                      checkmarkColor: AppTheme.goldLight,
                      backgroundColor: AppTheme.secondaryBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (!_showAmharic && !val) return; // Keep at least one
                        setState(() => _showGeEz = val);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _showAmharic,
                      label: const Text('አማርኛ (Amharic)', style: TextStyle(fontSize: 11)),
                      selectedColor: AppTheme.goldAccent.withOpacity(0.2),
                      checkmarkColor: AppTheme.goldLight,
                      backgroundColor: AppTheme.secondaryBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (!_showGeEz && !val) return; // Keep at least one
                        setState(() => _showAmharic = val);
                      },
                    ),
                  ],
                ),
                Text(
                  'Font: ${state.prayerFontSize.toInt()} pt',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.borderMuted, height: 1),

          // 4. Main Prayer Scroll Content
          Expanded(
            child: _activeBookIndex == 0
                ? _buildWudaseContent(wudase.sections[state.selectedPrayerDayIndex], state.prayerFontSize)
                : _buildYezewetirContent(yezewetir.sections, state.prayerFontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildWudaseContent(PrayerSectionModel section, double fontSize) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Section Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF273142), Color(0xFF1B2332)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.church_outlined, color: AppTheme.goldLight, size: 28),
              const SizedBox(height: 6),
              Text(
                section.titleGeEz,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5A65E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.titleAmharic,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        if (_showGeEz) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_stories, color: AppTheme.goldLight, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'ግዕዝ (Ge\'ez Text)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.goldLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  section.geEzText,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: fontSize,
                    color: Colors.white,
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
              color: const Color(0xFF161E2B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderMuted.withOpacity(0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.translate, color: Color(0xFF3B82F6), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'አማርኛ ትርጉም (Amharic Translation)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  section.amharicText,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: const Color(0xFFE2E8F0),
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

  Widget _buildYezewetirContent(List<PrayerSectionModel> sections, double fontSize) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final sec = sections[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sec.titleGeEz,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5A65E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sec.titleAmharic,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              if (_showGeEz) ...[
                Text(
                  sec.geEzText,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: fontSize,
                    color: Colors.white,
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
                    color: const Color(0xFFCBD5E1),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
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
                  const Text(
                    'Adjust Prayer Text Size',
                    style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Change text scale for comfortable night prayer reading in dorms.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                      Expanded(
                        child: Slider(
                          value: state.prayerFontSize,
                          min: 12.0,
                          max: 26.0,
                          divisions: 7,
                          activeColor: AppTheme.goldAccent,
                          inactiveColor: AppTheme.surfaceColor,
                          onChanged: (val) {
                            setSheetState(() {});
                            state.setPrayerFontSize(val);
                          },
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.goldLight)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Preview: ${state.prayerFontSize.toInt()} pt',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.goldLight),
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
