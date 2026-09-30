import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentMinistryScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentMinistryScreen({super.key, required this.state});

  @override
  State<StudentMinistryScreen> createState() => _StudentMinistryScreenState();
}

class _StudentMinistryScreenState extends State<StudentMinistryScreen> {
  MinistryPillar? _selectedPillar; // null means 'All'
  String _searchQuery = '';

  IconData _getMinistryIcon(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return Icons.menu_book;
      case 'favorite_border':
        return Icons.favorite_border;
      case 'music_note':
        return Icons.music_note;
      case 'monetization_on_outlined':
        return Icons.monetization_on_outlined;
      case 'account_balance_wallet':
        return Icons.account_balance_wallet;
      case 'event_available':
        return Icons.event_available;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'translate':
        return Icons.translate;
      case 'insights':
        return Icons.insights;
      case 'fact_check_outlined':
        return Icons.fact_check_outlined;
      default:
        return Icons.group_work;
    }
  }

  void _openApplicationDialog(BuildContext context, MinistryModel ministry) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final state = widget.state;
    final isChoirMinistry = ministry.id == FellowshipDepartmentConstants.deptChoirArts || ministry.id == 'dept-music';
    final isSpecialNeedsMinistry = ministry.id == FellowshipDepartmentConstants.deptSpecialNeeds || ministry.id == 'dept-language';

    String selectedSubWing = ministry.subWings.isNotEmpty ? ministry.subWings.first : 'General Serving';
    String selectedYear = '2nd Year';
    ChoirWingType selectedChoirWing = ChoirWingType.mezmur;
    final List<String> selectedLanguages = ['Amharic (አማርኛ)'];
    const availableLanguages = [
      'Amharic (አማርኛ)',
      'Afan Oromo (Afaan Oromoo)',
      'Tigrinya (ትግርኛ)',
      'English (እንግሊዝኛ)',
      'Sign Language (የምልክት ቋንቋ)',
      'Hadiyya (ሃዲይሳ)',
      'Wolaytta (ወላይትኛ)',
      'Sidama (ሲዳሙ-አፎ)',
      'Geez (ግዕዝ)',
    ];

    final reasonController = TextEditingController();
    final experienceController = TextEditingController();
    final availabilityController = TextEditingController(text: 'Weekends & weekday evenings');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderCol,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header with Bilingual Title
                    Text(
                      ministry.titleAmharic,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    Text(
                      'Apply to ${ministry.titleEn}',
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Coordinator Info Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_pin, color: primaryAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isChoirMinistry
                                  ? 'Dual Wings: Dawit Fikadu (Mezmur) • Martha Tedla (Fine Arts)'
                                  : 'Reviewed by ${ministry.teamLead} (${ministry.coordinatorRole})',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Dual Choir Wing Selection (Exclusive to Choir & Fine Arts)
                    if (isChoirMinistry) ...[
                      Text(
                        'Select Choir & Fine Arts Wing (የአገልግሎት ዘርፍ ምረጥ)',
                        style: TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedChoirWing = ChoirWingType.mezmur),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedChoirWing == ChoirWingType.mezmur
                                      ? primaryAccent.withOpacity(0.18)
                                      : elevatedBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedChoirWing == ChoirWingType.mezmur
                                        ? primaryAccent
                                        : borderCol,
                                    width: selectedChoirWing == ChoirWingType.mezmur ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.music_note,
                                      color: selectedChoirWing == ChoirWingType.mezmur ? primaryAccent : textMuted,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'መዝሙር (Mezmur)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: selectedChoirWing == ChoirWingType.mezmur ? primaryAccent : textCol,
                                      ),
                                    ),
                                    Text(
                                      'Lead: Dawit F.',
                                      style: TextStyle(fontSize: 9, color: textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedChoirWing = ChoirWingType.fineArts),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: selectedChoirWing == ChoirWingType.fineArts
                                      ? primaryAccent.withOpacity(0.18)
                                      : elevatedBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selectedChoirWing == ChoirWingType.fineArts
                                        ? primaryAccent
                                        : borderCol,
                                    width: selectedChoirWing == ChoirWingType.fineArts ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.palette_outlined,
                                      color: selectedChoirWing == ChoirWingType.fineArts ? primaryAccent : textMuted,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ስነ ጥበባት (Fine Arts)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: selectedChoirWing == ChoirWingType.fineArts ? primaryAccent : textCol,
                                      ),
                                    ),
                                    Text(
                                      'Lead: Martha T.',
                                      style: TextStyle(fontSize: 9, color: textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // 2. Languages Known Checklist (Exclusive to Language & Special Needs)
                    if (isSpecialNeedsMinistry) ...[
                      Text(
                        'Languages & Communication Skills (የሚያውቋቸው ቋንቋዎች) *',
                        style: TextStyle(color: textCol, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select all languages you can teach, interpret, or communicate in:',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableLanguages.map((lang) {
                          final isSelected = selectedLanguages.contains(lang);
                          return FilterChip(
                            label: Text(lang, style: TextStyle(fontSize: 11, color: isSelected ? (isDark ? Colors.black : Colors.white) : textCol)),
                            selected: isSelected,
                            selectedColor: primaryAccent,
                            backgroundColor: elevatedBg,
                            checkmarkColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            onSelected: (bool selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedLanguages.add(lang);
                                } else {
                                  selectedLanguages.remove(lang);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Preferred Sub-wing Dropdown
                    Text('Select Specific Sub-wing (የአገልግሎት ዘርፍ)',
                        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedSubWing,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          style: TextStyle(fontSize: 12, color: textCol),
                          items: ministry.subWings.map((wing) {
                            return DropdownMenuItem(value: wing, child: Text(wing, style: TextStyle(fontSize: 12, color: textCol)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedSubWing = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Academic Year / Batch Dropdown
                    Text('Your Academic Year / Batch (የትምህርት ክፍለ ዓመት)',
                        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderCol),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedYear,
                          isExpanded: true,
                          dropdownColor: cardBg,
                          style: TextStyle(fontSize: 12, color: textCol),
                          items: ['1st Year Freshman', '2nd Year', '3rd Year', '4th Year Graduating', 'Postgraduate']
                              .map((yr) => DropdownMenuItem(value: yr, child: Text(yr, style: TextStyle(fontSize: 12, color: textCol))))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedYear = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reason for applying
                    Text('Spiritual Calling & Motivation (የአገልግሎት ፍላጎትህ/ሽ)',
                        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      style: TextStyle(color: textCol, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Why do you feel called to serve in this department?',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 12),
                        filled: true,
                        fillColor: elevatedBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderCol),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Experience / skills
                    Text('Church Background & Skills (ልምድ ወይም ክህሎት)',
                        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: experienceController,
                      style: TextStyle(color: textCol, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Parish choir, Begena learner, high school tutoring, Red Cross...',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 12),
                        filled: true,
                        fillColor: elevatedBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderCol),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Availability
                    Text('Weekly Availability (የአገልግሎት ሰዓት)',
                        style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: availabilityController,
                      style: TextStyle(color: textCol, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Saturdays, Sunday afternoons, free evenings...',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 12),
                        filled: true,
                        fillColor: elevatedBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderCol),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please share your motivation for serving')),
                          );
                          return;
                        }
                        if (isSpecialNeedsMinistry && selectedLanguages.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least one language for this department')),
                          );
                          return;
                        }
                        state.submitMinistryApplication(
                          ministryId: ministry.id,
                          reason: reasonController.text.trim(),
                          experience: experienceController.text.trim().isNotEmpty
                              ? experienceController.text.trim()
                              : 'Ready to be trained',
                          availability: availabilityController.text.trim(),
                          studentYear: selectedYear,
                          preferredSubWing: selectedSubWing,
                          choirWing: isChoirMinistry ? selectedChoirWing : null,
                          languagesKnown: isSpecialNeedsMinistry ? selectedLanguages : const [],
                        );
                        Navigator.pop(ctx);
                        final targetLead = isChoirMinistry
                            ? (selectedChoirWing == ChoirWingType.mezmur ? 'Dawit Fikadu' : 'Martha Tedla')
                            : ministry.teamLead;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Application routed directly to $targetLead (${ministry.titleAmharic})!'),
                            backgroundColor: cardBg,
                          ),
                        );
                      },
                      icon: Icon(Icons.send, size: 16, color: isDark ? Colors.black : Colors.white),
                      label: Text(
                        'Submit Application to Coordinator',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

    final state = widget.state;
    final allMinistries = state.ministries;

    // Filter by Pillar and Search Query
    final filteredMinistries = allMinistries.where((m) {
      final matchesPillar = _selectedPillar == null || m.pillar == _selectedPillar;
      final query = _searchQuery.toLowerCase().trim();
      final matchesQuery = query.isEmpty ||
          m.titleEn.toLowerCase().contains(query) ||
          m.titleAmharic.toLowerCase().contains(query) ||
          m.descriptionEn.toLowerCase().contains(query) ||
          m.descriptionAmharic.toLowerCase().contains(query) ||
          m.teamLead.toLowerCase().contains(query) ||
          m.subWings.any((w) => w.toLowerCase().contains(query));
      return matchesPillar && matchesQuery;
    }).toList();

    final myApplications = state.volunteerApplications
        .where((a) => a.studentId == state.currentUser.id)
        .toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Voluntary Serving • ንዑሳን ክፍሎች', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Introduction Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryAccent.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.church_outlined, color: primaryAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '10 EOTC Campus Sub-Committees',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                            Text(
                              'የግቢ ጉባኤ 10ሩ ንዑሳን የአገልግሎት ክፍላት',
                              style: TextStyle(fontSize: 12, color: primaryAccent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Every member is gifted to serve. Applications are reviewed directly by the respective Department Coordinator for rapid screening and onboarding.',
                    style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Search Box
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: textCol, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search by department, coordinator, or sub-wing...',
                hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 12),
                prefixIcon: Icon(Icons.search, color: textMuted, size: 18),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderCol),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. 4-Pillar Filter Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPillarFilterChip(context, null, 'All 10 Wings (ሁሉንም)', allMinistries.length),
                  ...MinistryPillar.values.map((pillar) {
                    final count = allMinistries.where((m) => m.pillar == pillar).length;
                    return _buildPillarFilterChip(context, pillar, pillar.shortName, count);
                  }),
                ],
              ),
            ),

            // 4. My Active Applications Status (if any)
            if (myApplications.isNotEmpty) ...[
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'My Department Applications',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: elevatedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${myApplications.length} active',
                      style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...myApplications.map((app) => _buildApplicationCard(context, app)),
            ],

            const SizedBox(height: 22),

            // 5. Section Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Explore Fellowship Wings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredMinistries.length} Departments',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Departments List
            if (filteredMinistries.isEmpty)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Center(
                  child: Text(
                    'No departments match your filter or search query.',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                ),
              )
            else
              ...filteredMinistries.map((min) => _buildMinistryCard(context, min)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPillarFilterChip(BuildContext context, MinistryPillar? pillar, String label, int count) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final textCol = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedPillar == pillar;

    return GestureDetector(
      onTap: () => setState(() => _selectedPillar = pillar),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent : cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryAccent : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (isDark ? Colors.black : Colors.white) : textCol.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.black.withOpacity(0.25) : Colors.white.withOpacity(0.25))
                    : elevatedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? (isDark ? Colors.black : Colors.white) : primaryAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, VolunteerApplicationModel app) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final primaryAccent = theme.colorScheme.primary;

    final isApproved = app.status == ApplicationStatus.approved;
    final isRejected = app.status == ApplicationStatus.rejected;
    final statusColor = isApproved
        ? AppTheme.emerald
        : isRejected
            ? AppTheme.crimson
            : primaryAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.ministryAmharicTitle.isNotEmpty ? app.ministryAmharicTitle : app.ministryTitle,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textCol),
                    ),
                    Text(
                      app.ministryTitle,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  app.status == ApplicationStatus.pending
                      ? 'PENDING COORDINATOR'
                      : app.status.name.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.bookmark_border, size: 13, color: primaryAccent),
              const SizedBox(width: 4),
              Text('Sub-wing: ${app.preferredSubWing}', style: TextStyle(fontSize: 11, color: textMuted)),
              const Spacer(),
              Text('Batch: ${app.studentYear}', style: TextStyle(fontSize: 11, color: textMuted.withOpacity(0.7))),
            ],
          ),
          if (app.coordinatorNotes != null && app.coordinatorNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.comment, size: 14, color: primaryAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Coordinator note: ${app.coordinatorNotes}',
                      style: TextStyle(fontSize: 11, color: textCol),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinistryCard(BuildContext context, MinistryModel min) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Amharic/English Titles + Pillar Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primaryAccent.withOpacity(0.25)),
                ),
                child: Icon(_getMinistryIcon(min.iconName), color: primaryAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      min.titleAmharic,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      min.titleEn,
                      style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        min.pillar.shortName.toUpperCase(),
                        style: TextStyle(fontSize: 9, color: textMuted.withOpacity(0.8), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Descriptions
          Text(
            min.descriptionAmharic,
            style: TextStyle(fontSize: 12, color: textCol, height: 1.35),
          ),
          const SizedBox(height: 4),
          Text(
            min.descriptionEn,
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
          ),

          const SizedBox(height: 12),

          // Sub-wings Pills
          Text('SUB-WINGS / ዘርፎች:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted.withOpacity(0.7), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: min.subWings.map((wing) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderCol),
                ),
                child: Text(wing, style: TextStyle(fontSize: 10, color: textMuted)),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Meeting Schedule & Requirements
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: primaryAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Meeting: ${min.meetingSchedule}',
                        style: TextStyle(fontSize: 11, color: textCol),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.checklist, size: 14, color: primaryAccent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        min.requirements,
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: borderCol),
          const SizedBox(height: 8),

          // Coordinator Contact & Apply Action
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (min.id == FellowshipDepartmentConstants.deptChoirArts || min.id == 'dept-music') ...[
                      Text(
                        'Co-Leads: Dawit F. (Mezmur) • Martha T. (Fine Arts)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                      ),
                      Text(
                        'Dual Wings • ${min.activeCount} servants',
                        style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600),
                      ),
                    ] else ...[
                      Text(
                        'Lead: ${min.teamLead} (${min.coordinatorBaptismalName})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol),
                      ),
                      Text(
                        '${min.activeCount} servants • ${min.openSlots} open slots',
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              // Direct Inquiry Shortcuts
              IconButton(
                icon: Icon(Icons.phone_outlined, size: 18, color: primaryAccent),
                tooltip: 'Call Coordinator',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => widget.state.launchCall(min.coordinatorPhone),
              ),
              IconButton(
                icon: Icon(Icons.sms_outlined, size: 18, color: primaryAccent),
                tooltip: 'SMS Coordinator',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () => widget.state.launchSms(
                  min.coordinatorPhone,
                  body: 'Selam Coordinator ${min.teamLead}, I am inquiring about joining ${min.titleAmharic}.',
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () => _openApplicationDialog(context, min),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(
                  'Apply',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
