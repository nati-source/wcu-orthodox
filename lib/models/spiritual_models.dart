import 'package:flutter/material.dart';


class DailyScriptureModel {
  final String epistle;
  final String catholicEpistle;
  final String acts;
  final String psalm;
  final String gospel;
  final String reflection;
  final String synaxariumExcerpt;

  const DailyScriptureModel({
    required this.epistle,
    required this.catholicEpistle,
    required this.acts,
    required this.psalm,
    required this.gospel,
    required this.reflection,
    required this.synaxariumExcerpt,
  });
}

class EthiopianCalendarDay {
  final String geezDateString; // e.g. "ጳጉሜን ፫ / 3" or "መስከረም ፩ / 1"
  final String geezMonth;
  final int geezDay;
  final int geezYear;
  final DateTime gregorianDate;
  final String saintOfToday; // e.g. "St. Mary (ማርያም)", "St. George (ጊዮርጊስ)"
  final String saintOfTodayGeEz;
  final bool isFasting;
  final String fastName; // e.g. "Wednesday & Friday Fast / የረቡዕ እና ዓርብ ጾም"
  final String fastRules; // e.g. "Fast until 3:00 PM (9 ሰዓት), strictly vegan"
  final bool isFishAllowed;
  final String fastingUntilHour; // e.g. "3:00 PM (9:00 LT)"
  final DailyScriptureModel scriptures;

  const EthiopianCalendarDay({
    required this.geezDateString,
    required this.geezMonth,
    required this.geezDay,
    required this.geezYear,
    required this.gregorianDate,
    required this.saintOfToday,
    required this.saintOfTodayGeEz,
    required this.isFasting,
    required this.fastName,
    required this.fastRules,
    this.isFishAllowed = false,
    this.fastingUntilHour = '3:00 PM',
    required this.scriptures,
  });
}

class EthiopianCalendarHelper {
  static const List<String> monthNamesGeEz = [
    'መስከረም (Meskerem)',
    'ጥቅምት (Tikimt)',
    'ኅዳር (Hidar)',
    'ታኅሣሥ (Tahsas)',
    'ጥር (Tir)',
    'የካቲት (Yekatit)',
    'መጋቢት (Megabit)',
    'ሚያዝያ (Miyazya)',
    'ግንቦት (Ginbot)',
    'ሰኔ (Sene)',
    'ሐምሌ (Hamle)',
    'ነሐሴ (Nehase)',
    'ጳጉሜን (Pagumen)',
  ];

  static const Map<int, Map<String, String>> monthlySaints = {
    1: {'en': 'Nativity of St. Mary (ልደታ) & St. Elijah', 'geez': 'ልደታ ለማርያም ወኤልያስ ነቢይ'},
    2: {'en': 'St. Thaddaeus the Apostle (ታዴዎስ ሐዋርያ)', 'geez': 'ታዴዎስ ሐዋርያ'},
    3: {'en': 'Ba\'eta of St. Mary (በዓታ) & Zena Markos', 'geez': 'በዓታ ለማርያም ወዜና ማርቆስ'},
    4: {'en': 'St. John the Apostle (ዮሐንስ ወልደ ነጎድጓድ)', 'geez': 'ዮሐንስ ወልደ ነጎድጓድ'},
    5: {'en': 'Abune Gebre Menfes Qidus (አቡነ ገብረ መንፈስ ቅዱስ)', 'geez': 'አቡነ ገብረ መንፈስ ቅዱስ'},
    6: {'en': 'Debre Qusqwam (ቁስቋም ማርያም) & Lord Jesus', 'geez': 'ደብረ ቁስቋም ወኢየሱስ'},
    7: {'en': 'The Holy Trinity (ሥላሴ)', 'geez': 'ቅድስት ሥላሴ'},
    8: {'en': 'St. Kiros (አባ ኪሮስ) & St. Job the Righteous', 'geez': 'አባ ኪሮስ ወኢዮብ ጻድቅ'},
    9: {'en': '318 Orthodox Fathers of Nicaea (ሠለስቱ ምዕት)', 'geez': 'ሠለስቱ ምዕት ሊቃውንት'},
    10: {'en': 'Feast of the Glorious Cross (መስቀል)', 'geez': 'በዓለ መስቀሉ ለክርስቶስ'},
    11: {'en': 'St. Anne & St. Joachim (ሐና ወኢያቄም)', 'geez': 'ሐና ወኢያቄም ወፋሲለደስ ሰማዕት'},
    12: {'en': 'Archangel St. Michael (ሚካኤል ሊቀ መላእክት)', 'geez': 'ሚካኤል ሊቀ መላእክት'},
    13: {'en': 'Archangel St. Raphael (ሩፋኤል ሊቀ መላእክት)', 'geez': 'ሩፋኤል ሊቀ መላእክት'},
    14: {'en': 'Abune Aregawi (አቡነ አረጋዊ ዘደብረ ዳሞ)', 'geez': 'አቡነ አረጋዊ'},
    15: {'en': 'St. Cyricus & Julitta (ቂርቆስ ወኢየሉጣ)', 'geez': 'ቂርቆስ ወኢየሉጣ ሰማዕታት'},
    16: {'en': 'Kidane Mehret - Covenant of Mercy (ኪዳነ ምሕረት)', 'geez': 'ኪዳነ ምሕረት ለእመቤታችን'},
    17: {'en': 'St. Stephen the Protomartyr (እስጢፋኖስ ቀዳሜ ሰማዕት)', 'geez': 'እስጢፋኖስ ሊቀ ዲያቆናት'},
    18: {'en': 'St. Philip the Apostle & Abba Ewostatewos', 'geez': 'ፊልጶስ ሐዋርያ ወአባ ኤዎስጣቴዎስ'},
    19: {'en': 'Archangel St. Gabriel (ገብርኤል ሊቀ መላእክት)', 'geez': 'ገብርኤል ሊቀ መላእክት'},
    20: {'en': 'Hinsete Betekristiyan (ሕንፀተ ቤተክርስቲያን)', 'geez': 'ሕንፀተ ቤተክርስቲያን'},
    21: {'en': 'Holy Virgin Mary Mother of God (ማርያም)', 'geez': 'እግዝእትነ ማርያም ድንግል'},
    22: {'en': 'Archangel St. Uriel (ዑራኤል ሊቀ መላእክት)', 'geez': 'ዑራኤል ሊቀ መላእክት ወደቅስዮስ'},
    23: {'en': 'St. George the Martyr (ጊዮርጊስ ሰማዕት)', 'geez': 'ጊዮርጊስ ሊቀ ሰማዕታት'},
    24: {'en': 'Abune Teklehaimanot (አቡነ ተክለ ሃይማኖት)', 'geez': 'አቡነ ተክለ ሃይማኖት'},
    25: {'en': 'St. Mercurius the Martyr (መርቆሬዎስ)', 'geez': 'መርቆሬዎስ ሰማዕት'},
    26: {'en': 'St. Thomas the Apostle (ቶማስ ሐዋርያ)', 'geez': 'ቶማስ ሐዋርያ'},
    27: {'en': 'Medhane Alem - Savior of the World (መድኃኔ ዓለም)', 'geez': 'መድኃኔ ዓለም'},
    28: {'en': 'Emmanuel - God with Us (አማኑኤል)', 'geez': 'አማኑኤል ቸሩ አምላክ'},
    29: {'en': 'Ba\'ale Wold - Nativity of Christ (በዓለ ወልድ)', 'geez': 'በዓለ ወልድ'},
    30: {'en': 'St. John the Baptist (ዮሐንስ መጥምቅ) & St. Mark', 'geez': 'ዮሐንስ መጥምቅ ወማርቆስ ወንጌላዊ'},
  };

  static EthiopianCalendarDay fromGregorian(DateTime date) {
    int gregYear = date.year;
    int meskerem1Day = ((gregYear - 3) % 4 == 0) ? 12 : 11;
    DateTime newYearDate = DateTime(gregYear, 9, meskerem1Day);

    int ethYear;
    DateTime ethNewYear;

    if (date.isBefore(newYearDate)) {
      ethYear = gregYear - 8;
      int prevMeskerem1Day = ((gregYear - 1 - 3) % 4 == 0) ? 12 : 11;
      ethNewYear = DateTime(gregYear - 1, 9, prevMeskerem1Day);
    } else {
      ethYear = gregYear - 7;
      ethNewYear = newYearDate;
    }

    int daysDiff = date.difference(ethNewYear).inDays;
    int ethMonth = (daysDiff ~/ 30) + 1;
    int ethDay = (daysDiff % 30) + 1;

    if (ethMonth > 13) {
      ethMonth = 13;
      ethDay = daysDiff - (12 * 30) + 1;
    }

    final monthName = monthNamesGeEz[(ethMonth - 1).clamp(0, 12)];
    final saintInfo = monthlySaints[ethDay] ?? {
      'en': 'Commemoration of the Righteous (ተዝካረ ጻድቃን)',
      'geez': 'ተዝካረ ጻድቃን ወሰማዕታት',
    };

    final isFast = date.weekday == DateTime.wednesday || date.weekday == DateTime.friday;
    final fastName = date.weekday == DateTime.wednesday
        ? 'Wednesday Fast (የረቡዕ ጾም)'
        : date.weekday == DateTime.friday
            ? 'Friday Fast (የዓርብ ጾም)'
            : 'Non-Fasting Day (ፈታሕ)';

    final fastRules = isFast
        ? 'Strictly vegan, fast until 3:00 PM (9:00 LT). Repentance, psalm recitation & prayer.'
        : 'Regular dietary observance. Morning prayer & daily scripture reading.';

    final fastingUntil = isFast ? '3:00 PM' : 'None';

    final scriptures = DailyScriptureModel(
      epistle: 'ሮሜ 8፥14-30 (Romans 8:14-30)',
      catholicEpistle: '1 ጴጥሮስ 2፥1-10 (1 Peter 2:1-10)',
      acts: 'ግብረ ሐዋርያት 10፥34-48 (Acts 10:34-48)',
      psalm: 'መዝሙረ ዳዊት 102፥20-22 (Psalm 102:20-22)',
      gospel: 'ዮሐንስ 14፥1-14 (John 14:1-14)',
      reflection: '“በመንፈስ የሚመሩ ሁሉ የእግዚአብሔር ልጆች ናቸው።” — ሮሜ 8፥14',
      synaxariumExcerpt: 'በዚህች ዕለት የተከበረ ${saintInfo['geez']} መታሰቢያው ሆነ። በረከቱ ከሁላችን ጋር ትኑር።',
    );

    return EthiopianCalendarDay(
      geezDateString: '$monthName $ethDay / $ethDay',
      geezMonth: monthName,
      geezDay: ethDay,
      geezYear: ethYear,
      gregorianDate: date,
      saintOfToday: saintInfo['en']!,
      saintOfTodayGeEz: saintInfo['geez']!,
      isFasting: isFast,
      fastName: fastName,
      fastRules: fastRules,
      isFishAllowed: !isFast,
      fastingUntilHour: fastingUntil,
      scriptures: scriptures,
    );
  }

  static List<EthiopianCalendarDay> generateWeek([DateTime? today]) {
    final base = today ?? DateTime.now();
    return List.generate(7, (i) {
      final date = base.add(Duration(days: i - 2));
      return fromGregorian(date);
    });
  }
}

// ============================================================================
// 2. DAILY PRAYER BOOK (WUDASE MARYAM & YEZEWETIR TSELOT) MODELS
// ============================================================================

class PrayerSectionModel {
  final String id;
  final String titleGeEz;
  final String titleAmharic;
  final String titleEn;
  final String geEzText;
  final String amharicText;
  final String? audioUrl;
  final String? commentary;

  const PrayerSectionModel({
    required this.id,
    required this.titleGeEz,
    required this.titleAmharic,
    required this.titleEn,
    required this.geEzText,
    required this.amharicText,
    this.audioUrl,
    this.commentary,
  });
}

class PrayerBookModel {
  final String id;
  final String title;
  final String titleGeEz;
  final String description;
  final List<PrayerSectionModel> sections;

  const PrayerBookModel({
    required this.id,
    required this.title,
    required this.titleGeEz,
    required this.description,
    required this.sections,
  });
}

// ============================================================================
// APP THEME PALETTES
// ============================================================================

enum AppThemePalette {
  midnightFellowship, // Default Dark (Obsidian / Midnight Sacred)
  parchmentIncense,   // Default Light (Aged Vellum & Liturgical Crimson)
  axumiteEmerald,     // Modern Bright (Byzantine Forest Green & Amber Brass)
}

extension AppThemePaletteExt on AppThemePalette {
  String get displayName {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return 'Midnight Fellowship';
      case AppThemePalette.parchmentIncense:
        return 'Parchment & Incense';
      case AppThemePalette.axumiteEmerald:
        return 'Axumite Emerald';
    }
  }

  String get amharicName {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return 'የሌሊት ማኅበር (ነባሪ ጨለማ)';
      case AppThemePalette.parchmentIncense:
        return 'ብራና እና ዕጣን (ብርሃን)';
      case AppThemePalette.axumiteEmerald:
        return 'አክሱማዊ መረግድ (ዘመናዊ ብሩህ)';
    }
  }

  String get subtitle {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return 'Midnight Sacred • Gold & Slate';
      case AppThemePalette.parchmentIncense:
        return 'Aged Vellum • Liturgical Crimson & Gold';
      case AppThemePalette.axumiteEmerald:
        return 'Modern Bright • Byzantine Forest & Amber';
    }
  }

  bool get isDark {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return true;
      case AppThemePalette.parchmentIncense:
      case AppThemePalette.axumiteEmerald:
        return false;
    }
  }

  Color get scaffoldBg {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF070F1E);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFFFBF8F2);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFFF8FAFC);
    }
  }

  Color get cardBg {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF101C33);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFFFFFFFF);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFFFFFFFF);
    }
  }

  Color get tileBg {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF1C2333);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFFF5EFEB);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFFF1F5F9);
    }
  }

  Color get elevatedBg {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF232E48);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFFEDE4DB);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get primaryAccent {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFFF59E0B); // Radiant Amber Gold
      case AppThemePalette.parchmentIncense:
        return const Color(0xFF991B1B); // Liturgical Crimson
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFF065F46); // Byzantine Forest Green
    }
  }

  Color get secondaryAccent {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF8B5CF6); // Royal Violet / Gold secondary
      case AppThemePalette.parchmentIncense:
        return const Color(0xFFD97706); // Warm Honey Gold
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFFB45309); // Amber Brass
    }
  }

  Color get textPrimary {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFFF9FAFB);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFF1C1917);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFF0F172A);
    }
  }

  Color get textSecondary {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF9CA3AF);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFF78716C);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFF64748B);
    }
  }

  Color get borderMuted {
    switch (this) {
      case AppThemePalette.midnightFellowship:
        return const Color(0xFF1E293B);
      case AppThemePalette.parchmentIncense:
        return const Color(0xFFE7E5E4);
      case AppThemePalette.axumiteEmerald:
        return const Color(0xFFE2E8F0);
    }
  }

  List<Color> get swatchColors => [
    scaffoldBg,
    cardBg,
    primaryAccent,
    secondaryAccent,
  ];
}

// ============================================================================
// WACHAMO UNIVERSITY COMPLETE DEPARTMENTS LIST
// ============================================================================

class WcuDepartments {
  static const List<String> all = [
    'Accounting and Finance',
    'Adult Education and Community Development',
    'Agricultural Economics',
    'Anesthesia',
    'Animal Science',
    'Architecture',
    'Biology',
    'Biomedical Engineering',
    'Biotechnology',
    'Chemical Engineering',
    'Chemistry',
    'Civics and Ethical Studies',
    'Civil Engineering',
    'Comprehensive Nursing',
    'Computer Science',
    'Construction Technology and Management (COTM)',
    'Curriculum and Instruction',
    'Dental Medicine',
    'Economics',
    'Educational Leadership and Management',
    'Electrical and Computer Engineering',
    'Electro-Mechanical Engineering',
    'English Language and Literature',
    'Environmental Science',
    'Food Science and Postharvest Technology',
    'Geography and Environmental Studies',
    'Geology',
    'Geomatics Engineering / Surveying Engineering',
    'Governance and Development Studies',
    'Hadiya Language and Literature',
    'Health Informatics',
    'History and Heritage Management',
    'Horticulture',
    'Hydraulic and Water Resource Engineering',
    'Industrial Chemistry',
    'Information Systems (IS)',
    'Information Technology (IT)',
    'Journalism and Communication',
    'Law',
    'Management',
    'Marketing Management',
    'Mathematics',
    'Mechanical Engineering',
    'Medical Laboratory Technology',
    'Medicine',
    'Midwifery',
    'Natural Resource Management',
    'Pharmacy',
    'Physics',
    'Plant Science',
    'Psychology',
    'Public Administration and Development Management',
    'Public Health',
    'Rural Development and Agricultural Extension',
    'Sociology',
    'Software Engineering',
    'Sport Science',
    'Statistics',
    'Tourism and Hotel Management',
    'Veterinary Medicine',
  ];
}

// ============================================================================
// 3. FATHER CONFESSOR & SPIRITUAL GUIDANCE MODELS
// ============================================================================
