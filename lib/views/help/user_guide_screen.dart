import 'package:flutter/material.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

/// Interactive In-App User Guide & Fellowship Manual (የተጠቃሚ መመሪያ)
class UserGuideScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback? onOpenScanner;

  const UserGuideScreen({
    super.key,
    required this.state,
    this.onOpenScanner,
  });

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'መሰረታዊ (Basics)',
    'መንፈሳዊ (Spiritual)',
    'አገልግሎት (Services)',
    'አስተዳደር (Admin)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final allGuides = _buildGuideItems(context, widget.state);

    final filteredGuides = allGuides.where((guide) {
      final matchesCat = _selectedCategory == 'All' || guide.category == _selectedCategory;
      if (!matchesCat) return false;

      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return guide.titleAmharic.toLowerCase().contains(q) ||
          guide.titleEnglish.toLowerCase().contains(q) ||
          guide.keywords.any((k) => k.toLowerCase().contains(q)) ||
          guide.summary.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Guide • የተጠቃሚ መመሪያ',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            Text(
              'WCU Orthodox Fellowship Mobile Manual',
              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        children: [
          // 1. Hero Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.gold.withOpacity(0.2),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'እንኳን ወደ ግቢ ጉባኤ መመሪያ በደህና መጡ!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'የመተግበሪያውን አገልግሎቶች፣ የመገኘት ክትትል (Attendance)፣ መንፈሳዊ ቤተሰብ እና የንስሐ አባት አጠቃቀም ደረጃ በደረጃ ይወቁ።',
                        style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Search Field
          Container(
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(color: textCol, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'በርዕስ ወይም በቃል ይፈልጉ (e.g., QR, ንስሐ, ቤተሰብ, Password)...',
                hintStyle: TextStyle(color: textMuted, fontSize: 12),
                prefixIcon: Icon(Icons.search, color: primaryAccent, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: primaryAccent.withOpacity(0.22),
                    backgroundColor: elevatedBg,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? primaryAccent : textMuted,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isSelected ? primaryAccent : theme.dividerColor),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Topic Count Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'የመመሪያ ርዕሶች (${filteredGuides.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: primaryAccent,
                ),
              ),
              if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedCategory = 'All';
                    });
                  },
                  child: const Text(
                    'Reset Filter',
                    style: TextStyle(fontSize: 11, color: AppTheme.gold, decoration: TextDecoration.underline),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 5. Accordion Guide Cards
          if (filteredGuides.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 40, color: textMuted.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'ምንም መመሪያ አልተገኘም (No matching topics)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'እባክዎ ሌላ ቃል ወይም የፍለጋ ፊደል ይሞክሩ።',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredGuides.map((g) => _buildGuideAccordion(context, g)),

          const SizedBox(height: 24),

          // 6. Support Footer Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.azure.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.headset_mic_outlined, color: AppTheme.azure, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ተጨማሪ ድጋፍ ይፈልጋሉ? (Need Direct Help?)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'የመለያ፣ የይለፍ ቃል ወይም የምዝገባ ችግር ካጋጠመዎት የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ አስተዳዳሪዎችን በቴሌግራም ወይም በቀጥታ ማግኘት ይችላሉ።',
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => widget.state.launchCall('+251911456789'),
                      icon: const Icon(Icons.call, size: 15, color: AppTheme.azure),
                      label: const Text('Call Admin / ደውል', style: TextStyle(fontSize: 12, color: AppTheme.azure)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.azure),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => widget.state.launchSms('+251911456789', body: 'Selam, I need assistance with the WCU Orthodox App.'),
                      icon: const Icon(Icons.sms_outlined, size: 15),
                      label: const Text('Send SMS / መልዕክት ላክ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.azure,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildGuideAccordion(BuildContext context, _GuideItem item) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.accentColor, size: 22),
          ),
          title: Text(
            item.titleAmharic,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textCol,
              fontFamily: 'serif',
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.titleEnglish,
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Summary
            Text(
              item.summary,
              style: TextStyle(fontSize: 13, color: textCol, height: 1.45),
            ),
            const SizedBox(height: 12),

            // Steps
            ...item.steps.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final stepText = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: item.accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: item.accentColor.withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text(
                          '$idx',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.accentColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stepText,
                        style: TextStyle(fontSize: 12, color: textCol, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Tip Box (if provided)
            if (item.tip != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.tip!,
                        style: TextStyle(fontSize: 11, color: textCol, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Button (if provided)
            if (item.actionLabel != null && item.onAction != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: item.onAction,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: Text(item.actionLabel!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_GuideItem> _buildGuideItems(BuildContext context, FellowshipState state) {
    return [
      _GuideItem(
        category: 'መሰረታዊ (Basics)',
        icon: Icons.app_registration_rounded,
        accentColor: AppTheme.gold,
        titleAmharic: '1. ምዝገባና ማረጋገጫ (Sign Up & Approval)',
        titleEnglish: 'Account Registration & Verification',
        keywords: ['register', 'approval', 'sign up', 'ምዝገባ', 'ይለፍ ቃል', 'password', 'email'],
        summary: 'አዲስ ተማሪዎች በስልክ መተግበሪያው ላይ አካውንት በመክፈት የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ አባል ይሆናሉ።',
        steps: [
          'የመግቢያ ገጽ ላይ "Create an Account / አዲስ አካውንት ፍጠር" የሚለውን ይጫኑ።',
          'ትክክለኛውን የራስዎን ስም፣ የክርስትና ስም፣ ኢሜይል፣ ስልክ ቁጥር፣ ግቢ (Main/Durame/Tora) እና የትምህርት ክፍልዎን ያስገቡ።',
          'ምዝገባውን እንዳጠናቀቁ "Awaiting Admin Approval" የሚል ገጽ ይታያል።',
          'የግቢ ጉባኤው አመራሮች መረጃዎን አረጋግጠው ሲያጸድቁ መተግበሪያው ወዲያውኑ አገልግሎት ለመስጠት ይከፈታል።',
        ],
        tip: 'የይለፍ ቃልዎ ቢጠፋ መልሶ ለማግኘት የሚረዳዎትን ትክክለኛ እና በስልክዎ ላይ የሚሰራ ኢሜይል አድራሻ ይጠቀሙ።',
      ),
      _GuideItem(
        category: 'መሰረታዊ (Basics)',
        icon: Icons.qr_code_scanner_rounded,
        accentColor: AppTheme.emerald,
        titleAmharic: '2. የQR ኮድ ክትትል/አቴንዳንስ (Smart Attendance)',
        titleEnglish: 'Smart Attendance Check-In',
        keywords: ['attendance', 'qr', 'scan', 'ስካን', 'መገኘት', 'ክትትል'],
        summary: 'በሰንበት ጉባኤ፣ በቅዳሴ፣ በቤተሰብ ጸሎትና በልዩ ጉባኤያት መገኘትዎን በስልክዎ QR ኮድ ስካን በማድረግ በሰከንዶች ያረጋግጣሉ።',
        steps: [
          'በዋናው ገጽ ላይ ወይም በላይኛው ባር የሚገኘውን የQR ስካነር ምልክት ይጫኑ።',
          'በአዳራሹ ስክሪን ወይም በካሜራው ፊት የቀረበውን የጉባኤውን QR ኮድ ያስቃኙ።',
          'የመገኘትዎ መረጃ በቀጥታ ወደ ግቢ ጉባኤው ዳታቤዝ ገብቶ በግል ገጽዎ ላይ "Checked In" ይሆናል።',
        ],
        tip: 'ስልክዎ ካሜራ ማንበብ ካልቻለ አስተባባሪው የሚያሳየውን ባለ 4 ድጅት ፒን ኮድ (Rolling PIN) በመጻፍ ማረጋገጥ ይችላሉ።',
        actionLabel: 'Open QR Scanner',
        onAction: () {
          Navigator.pop(context);
          if (widget.onOpenScanner != null) widget.onOpenScanner!();
        },
      ),
      _GuideItem(
        category: 'መሰረታዊ (Basics)',
        icon: Icons.badge_outlined,
        accentColor: AppTheme.azure,
        titleAmharic: '3. ዲጂታል መታወቂያ እና ገጽታ (Digital ID & Theme)',
        titleEnglish: 'Digital Fellowship ID & Theme Settings',
        keywords: ['id', 'profile', 'theme', 'dark mode', 'መታወቂያ', 'መገለጫ', 'ቀለም'],
        summary: 'የግቢ ጉባኤ አባልነትዎን የሚያረጋግጥ ዲጂታል መታወቂያ እና የገጽታ ቀለማት መምረጫ።',
        steps: [
          'በታችኛው ሜኑ ላይ "Profile / መገለጫ" የሚለውን ይምረጡ።',
          'የእርስዎ ፎቶ፣ ሙሉ ስም፣ የስም አባት፣ ግቢ፣ የትምህርት ክፍል እና የግል መለያ QR ኮድ የያዘ መታወቂያ ይታያል።',
          'የቀለም ማስተካከያ (Gold, Azure, Emerald, Crimson, Monastic) እና Dark Mode በመምረጥ ስልክዎን ያሳምሩ።',
        ],
        tip: 'በመታወቂያዎ ላይ የሚታየውን የግል QR ኮድ ለአስተባባሪዎች በማሳየት ለተለያዩ አገልግሎቶች በቀላሉ መታወቅ ይችላሉ።',
      ),
      _GuideItem(
        category: 'መንፈሳዊ (Spiritual)',
        icon: Icons.family_restroom_rounded,
        accentColor: AppTheme.gold,
        titleAmharic: '4. መንፈሳዊ ቤተሰብ (Spiritual Family System)',
        titleEnglish: 'Fellowship Family, Mentors & Fellowship',
        keywords: ['family', 'parents', 'ወላጆች', 'ቤተሰብ', 'ፍቅር', 'መንፈሳዊ'],
        summary: 'በግቢ ቆይታ ተማሪዎች ብቻቸውን እንዳይሆኑና በክርስቲያናዊ ፍቅር እንዲተሳሰሩ የተዘጋጀ የቤተሰብ መዋቅር።',
        steps: [
          'በታችኛው ሜኑ "Family" የሚለውን ይጫኑ።',
          'የተመደቡበትን የቤተሰብ ስም (ለምሳሌ፦ ቅዱስ ጊዮርጊስ፣ ደብረ ታቦር) ይመልከቱ።',
          'የመንፈሳዊ ወላጆችዎን (የቤተሰብ አባትና እናት) እንዲሁም የወንድሞችና እህቶችዎን ስም፣ ስልክና መረጃ ያግኙ።',
          'በቤተሰብ የጋራ ጸሎትና ውይይት ቀናት አብረው ይሳተፉ።',
        ],
        tip: 'የትምህርት፣ የምግብ ወይም የሕመም ችግር ካጋጠመዎት በመጀመሪያ ለቤተሰብ ወላጆችዎ ማሳወቅ ይችላሉ።',
      ),
      _GuideItem(
        category: 'መንፈሳዊ (Spiritual)',
        icon: Icons.person_pin_circle_rounded,
        accentColor: const Color(0xFF9333EA),
        titleAmharic: '5. የንስሐ አባትና መንፈሳዊ ቀጠሮ (Father Confessor)',
        titleEnglish: 'Confession Booking & Anonymous Q&A',
        keywords: ['confessor', 'appointment', 'ንስሐ', 'ቀጠሮ', 'ካህን', 'አባት', 'ጥያቄ'],
        summary: 'ከካህናት አባቶች ጋር ለንስሐ፣ ለምክር ወይም ለጸሎት ቀጠሮ መያዣ እና ሚስጥራዊ ጥያቄና መልስ።',
        steps: [
          'ከዋናው ገጽ ላይ "Confessor Father / የንስሐ አባት" የሚለውን ይክፈቱ።',
          'በግቢው ዙሪያ የሚያገለግሉ ካህናትን ዝርዝርና ያሉበትን ደብር ይመልከቱ።',
          '"Book Confession / ቀጠሮ ያዝ" የሚለውን በመጫን ምቹ ቀንና ሰዓት ይምረጡ።',
          'ለማንኛውም መንፈሳዊ ወይም የሕይወት ጥያቄ ስምዎ ሳይጠቀስ (Anonymous) ለካህናት አባቶች ጥያቄ ማቅረብ ይችላሉ።',
        ],
        tip: 'ለንስሐ ከመቅረብዎ በፊት በገጹ የሚገኘውን "Confession Prep Checklist" በመጠቀም ራስዎን በጸሎት ያዘጋጁ።',
      ),
      _GuideItem(
        category: 'መንፈሳዊ (Spiritual)',
        icon: Icons.auto_stories_rounded,
        accentColor: const Color(0xFF0284C7),
        titleAmharic: '6. የጸሎት መጽሐፍ እና ውዳሴ ማርያም (Prayer Book)',
        titleEnglish: 'Liturgical Prayers, Wudasie Maryam & Psalter',
        keywords: ['prayer', 'wudasie', 'ጸሎት', 'ውዳሴ ማርያም', 'መጽሐፍ', 'ዘወትር'],
        summary: 'የዘወትር ጸሎት፣ ውዳሴ ማርያም፣ አንቀጸ ብርሃን እና ይዌድስዋ መላእክት ያለምንም ኢንተርኔት በስልክዎ ያንብቡ።',
        steps: [
          'ከዋናው ገጽ "Prayer Book / የጸሎት መጽሐፍ" የሚለውን ይክፈቱ።',
          'የዕለቱን የውዳሴ ማርያም ክፍል ወይም የዘወትር ጸሎት ይምረጡ።',
          'የፊደል መጠኑን (Font Size) ለዓይን በሚመች መልኩ ማተለቅ ወይም ማሳነስ ይችላሉ።',
        ],
        tip: 'መጽሐፉ ሙሉ በሙሉ ከመስመር ውጭ (Offline) የሚሰራ በመሆኑ በማንኛውም ጊዜና ቦታ መጸለይ ይችላሉ።',
      ),
      _GuideItem(
        category: 'አገልግሎት (Services)',
        icon: Icons.directions_bus_rounded,
        accentColor: const Color(0xFFD97706),
        titleAmharic: '7. የንግደት ጉዞዎች (Pilgrimage Trips & Passes)',
        titleEnglish: 'Monastery Pilgrimages & Bus Bookings',
        keywords: ['trip', 'pilgrimage', 'ንግደት', 'ጉዞ', 'ገዳማት', 'አውቶቡስ'],
        summary: 'ወደ ታሪካዊ ገዳማትና ደብራት የሚደረጉ የንግደት ጉዞዎችን መረጃ ማግኘት እና የአውቶቡስ ትኬት መቁረጥ።',
        steps: [
          'የጉዞውን ዝርዝር፣ መነሻ ሰዓት፣ መዳረሻ ገዳም እና ክፍያ ይመልከቱ።',
          '"Register for Trip / ለጉዞው ተመዝገብ" የሚለውን ይጫኑ።',
          'ክፍያዎን በአስተባባሪው በኩል ሲያረጋግጡ የዲጂታል ቦርዲንግ ፓስ (Boarding Pass) ይደርስዎታል።',
        ],
        tip: 'በመነሻ ቀን ወደ አውቶቡስ ሲገቡ በስልክዎ ያለውን የዲጂታል ፓስ ለአስተባባሪው በማሳየት በቀጥታ መሳፈር ይችላሉ።',
      ),
      _GuideItem(
        category: 'አገልግሎት (Services)',
        icon: Icons.volunteer_activism_rounded,
        accentColor: AppTheme.crimson,
        titleAmharic: '8. በጎ አድራጎትና የጋራ መረዳጃ (Charity & Mutual Aid)',
        titleEnglish: 'Charity Campaigns, Dues & Emergency Aid',
        keywords: ['charity', 'dues', 'aid', 'በጎ አድራጎት', 'እርዳታ', 'መዋጮ'],
        summary: 'የወርሃዊ መዋጮ ክትትል፣ ለአቅመ-ደካሞችና ተማሪዎች የሚደረግ የጋራ መረዳጃ እና የአደጋ ጊዜ ጥሪ።',
        steps: [
          'የወርሃዊ መዋጮዎን (Monthly Dues) ሁኔታ በግል ገጽዎ ይከታተሉ።',
          'ድንገተኛ የሕክምና ወይም የምግብ ችግር ካጋጠመዎት በምስጢር "Request Emergency Aid" በማድረግ የድጋፍ ጥያቄ ያቅርቡ።',
          'የግቢ ጉባኤው የበጎ አድራጎት ክፍል ጥያቄዎን መርምሮ ፈጣን ድጋፍ ያደርጋል።',
        ],
        tip: 'የአደጋ ጊዜ ድጋፍ ጥያቄዎች (Emergency Aid) ፍጹም በሚስጥር የተያዙና ለአስተዳዳሪዎች ብቻ የሚታዩ ናቸው።',
      ),
      _GuideItem(
        category: 'አገልግሎት (Services)',
        icon: Icons.quiz_rounded,
        accentColor: const Color(0xFF10B981),
        titleAmharic: '9. የሃይማኖት ዕውቀት ውድድር (Faith Challenges & Trivia)',
        titleEnglish: 'Weekly Trivia Quizzes & Leaderboard',
        keywords: ['trivia', 'quiz', 'ውድድር', 'ጥያቄ', 'ፈተና', 'ሜዳሊያ'],
        summary: 'ሳምንታዊ የኦርቶዶክስ ተዋሕዶ ሃይማኖት ዕውቀት ጥያቄዎችን በመመለስ ነጥብና የበረከት ዋንጫዎችን ይሰብስቡ።',
        steps: [
          'ከዋናው ገጽ "Faith Challenge / የዕውቀት ውድድር" የሚለውን ይክፈቱ።',
          'የሳምንቱን ጥያቄዎች በጥንቃቄ አንብበው መልሱን ይምረጡ።',
          'ትክክለኛውን መልስ ሲመልሱ ነጥብዎ ይሰላል፤ በመሪዎች ሰሌዳ (Leaderboard) ላይ ደረጃዎን ይመልከቱ።',
        ],
        tip: 'እያንዳንዱ ጥያቄ የራሱ ሰዓት ስላለው ጊዜውን ሳያልፍ በፍጥነት መልስ መስጠት ተጨማሪ ነጥብ ያስገኛል።',
      ),
      _GuideItem(
        category: 'አስተዳደር (Admin)',
        icon: Icons.lock_reset_rounded,
        accentColor: AppTheme.gold,
        titleAmharic: '10. የይለፍ ቃል መቀየር እና መርሳት (Password Management)',
        titleEnglish: 'Password Reset & Profile Security',
        keywords: ['password', 'reset', 'ይለፍ ቃል', 'መቀየር', 'መርሳት', 'security'],
        summary: 'የመለያዎን የይለፍ ቃል መቀየር ወይም የረሱትን የይለፍ ቃል በኢሜይል መልሶ ማግኘት።',
        steps: [
          'የይለፍ ቃል ለመቀየር፦ Profile ገጽ በመሄድ "Change Password" የሚለውን ይጫኑ፤ የነበረውንና አዲሱን ይለፍ ቃል ያስገቡ።',
          'የይለፍ ቃል ከረሱ፦ በመግቢያው ገጽ ላይ "Forgot Password?" የሚለውን ይጫኑ፤ በምዝገባ ወቅት ያስገቡትን ኢሜይል ያስገቡ።',
          'ወደ ኢሜይል ሳጥንዎ (Inbox/Spam) የሚላከውን ማስፈንጠሪያ (Link) በመጫን አዲስ የይለፍ ቃል ያዘጋጁ።',
        ],
        tip: 'የዳግም ማስጀመሪያ ኢሜይል በInbox ካላገኙት እባክዎ የSpam ወይም Junk ፎልደርዎን መፈተሽ አይርሱ።',
      ),
    ];
  }
}

class _GuideItem {
  final String category;
  final IconData icon;
  final Color accentColor;
  final String titleAmharic;
  final String titleEnglish;
  final List<String> keywords;
  final String summary;
  final List<String> steps;
  final String? tip;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _GuideItem({
    required this.category,
    required this.icon,
    required this.accentColor,
    required this.titleAmharic,
    required this.titleEnglish,
    required this.keywords,
    required this.summary,
    required this.steps,
    this.tip,
    this.actionLabel,
    this.onAction,
  });
}
