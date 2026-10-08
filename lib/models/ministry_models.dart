
import 'user_models.dart';

enum MinistryPillar {
  spiritualEducation,
  memberCareSocial,
  operationsFinance,
  governanceAudit,
}

extension MinistryPillarExtension on MinistryPillar {
  String get displayName {
    switch (this) {
      case MinistryPillar.spiritualEducation:
        return 'Spiritual & Apostolic • መንፈሳዊና ትምህርት';
      case MinistryPillar.memberCareSocial:
        return 'Member Care & Charity • እንክብካቤና በጎ አድራጎት';
      case MinistryPillar.operationsFinance:
        return 'Operations & Finance • ልማትና ፋይናንስ';
      case MinistryPillar.governanceAudit:
        return 'Governance & Audit • ክትትልና ኦዲት';
    }
  }

  String get shortName {
    switch (this) {
      case MinistryPillar.spiritualEducation:
        return 'Spiritual';
      case MinistryPillar.memberCareSocial:
        return 'Care & Charity';
      case MinistryPillar.operationsFinance:
        return 'Finance & Ops';
      case MinistryPillar.governanceAudit:
        return 'Governance';
    }
  }
}

class MinistryModel {
  final String id;
  final String titleEn;
  final String titleAmharic;
  final String iconName;
  final String descriptionEn;
  final String descriptionAmharic;
  final MinistryPillar pillar;
  final String teamLead; // Coordinator full name
  final String coordinatorBaptismalName;
  final String coordinatorPhone;
  final String coordinatorRole;
  final int openSlots;
  final int activeCount;
  final List<String> tags;
  final List<String> subWings;
  final String meetingSchedule;
  final String requirements;

  MinistryModel({
    required this.id,
    required this.titleEn,
    required this.titleAmharic,
    required this.iconName,
    required this.descriptionEn,
    required this.descriptionAmharic,
    required this.pillar,
    required this.teamLead,
    required this.coordinatorBaptismalName,
    required this.coordinatorPhone,
    required this.coordinatorRole,
    required this.openSlots,
    required this.activeCount,
    required this.tags,
    required this.subWings,
    required this.meetingSchedule,
    required this.requirements,
  });

  // Backwards compatibility getters
  String get title => titleEn;
  String get description => descriptionEn;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titleEn': titleEn,
      'titleAmharic': titleAmharic,
      'iconName': iconName,
      'descriptionEn': descriptionEn,
      'descriptionAmharic': descriptionAmharic,
      'pillar': pillar.name,
      'teamLead': teamLead,
      'coordinatorBaptismalName': coordinatorBaptismalName,
      'coordinatorPhone': coordinatorPhone,
      'coordinatorRole': coordinatorRole,
      'openSlots': openSlots,
      'activeCount': activeCount,
      'tags': tags,
      'subWings': subWings,
      'meetingSchedule': meetingSchedule,
      'requirements': requirements,
    };
  }

  factory MinistryModel.fromMap(Map<String, dynamic> map, String docId) {
    final pillarStr = map['pillar']?.toString() ?? '';
    final pillar = MinistryPillar.values.firstWhere(
      (p) => p.name == pillarStr,
      orElse: () => MinistryPillar.spiritualEducation,
    );
    return MinistryModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? ''),
      titleEn: map['titleEn']?.toString() ?? map['title']?.toString() ?? '',
      titleAmharic: map['titleAmharic']?.toString() ?? '',
      iconName: map['iconName']?.toString() ?? 'group_work',
      descriptionEn: map['descriptionEn']?.toString() ?? map['description']?.toString() ?? '',
      descriptionAmharic: map['descriptionAmharic']?.toString() ?? '',
      pillar: pillar,
      teamLead: map['teamLead']?.toString() ?? 'Coordinator',
      coordinatorBaptismalName: map['coordinatorBaptismalName']?.toString() ?? '',
      coordinatorPhone: map['coordinatorPhone']?.toString() ?? '',
      coordinatorRole: map['coordinatorRole']?.toString() ?? 'Department Coordinator',
      openSlots: (map['openSlots'] as num?)?.toInt() ?? 5,
      activeCount: (map['activeCount'] as num?)?.toInt() ?? 10,
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      subWings: (map['subWings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      meetingSchedule: map['meetingSchedule']?.toString() ?? 'Sundays 4:00 PM',
      requirements: map['requirements']?.toString() ?? 'Open to all fellowship members.',
    );
  }

  static List<MinistryModel> get defaultMinistries => [
        MinistryModel(
          id: FellowshipDepartmentConstants.deptEducation,
          titleEn: 'Education & Apostolic Ministry',
          titleAmharic: 'ትምህርትና ሐዋርያዊ አገልግሎት',
          iconName: 'menu_book',
          descriptionEn: 'Organizes orthodox dogma courses, campus evangelism, patristics study circles, and scripture preaching.',
          descriptionAmharic: 'የነገረ መለኮት፣ የቤተክርስቲያን ታሪክና የቀኖና ትምህርቶችን ማዘጋጀት፣ ሐዋርያዊ አገልግሎትና የመጽሐፍ ቅዱስ ጥናት መርሐ ግብራትን ማስተባበር።',
          pillar: MinistryPillar.spiritualEducation,
          teamLead: 'Yared Tadesse',
          coordinatorBaptismalName: 'Gebre Meskel',
          coordinatorPhone: '+251911223344',
          coordinatorRole: 'Apostolic Ministry Coordinator',
          openSlots: 8,
          activeCount: 34,
          tags: ['Dogma', 'Evangelism', 'Bible Study', 'Patristics'],
          subWings: [
            'Dogmatics & Canon (ነገረ መለኮት)',
            'Scripture Study (የመጽሐፍ ቅዱስ ጥናት)',
            'Apostolic Outreach (ሐዋርያዊ ስብከት)',
            'Patristics & Library (የአበው ታሪክ)',
          ],
          meetingSchedule: 'Tuesdays 5:30 PM & Sundays 2:00 PM',
          requirements: 'Foundational church course completion; dedicated heart for gospel teaching.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptMemberCare,
          titleEn: 'Member Care, Counseling & Capacity',
          titleAmharic: 'አባላት እንክብካቤ ፤ምክክርና አቅም ማጎልበቻ',
          iconName: 'favorite_border',
          descriptionEn: 'Follows up on students spiritual and moral well-being, conducts peer counseling, and organizes leadership workshops.',
          descriptionAmharic: 'የተማሪዎችን መንፈሳዊና ማኅበራዊ ሕይወት መከታተል፣ የምክር አገልግሎት መስጠት እና የአመራር ክህሎት ማጎልበቻ ስልጠናዎችን ማዘጋጀት።',
          pillar: MinistryPillar.memberCareSocial,
          teamLead: 'Selamawit Desta',
          coordinatorBaptismalName: 'Walata Maryam',
          coordinatorPhone: '+251922334455',
          coordinatorRole: 'Member Care Coordinator',
          openSlots: 6,
          activeCount: 28,
          tags: ['Care', 'Counseling', 'Freshmen', 'Leadership'],
          subWings: [
            'Freshman Follow-up (የአዳዲስ ተማሪዎች ክትትል)',
            'Spiritual Counseling (የምክርና ማጽናናት)',
            'Capacity Building (የአቅም ማጎልበቻ)',
            'Sisterhood Care (የእህቶች ሕብረት)',
          ],
          meetingSchedule: 'Thursdays 6:00 PM',
          requirements: 'Empathy, confidentiality, and active commitment to fellowship life.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptChoirArts,
          titleEn: 'Music & Arts',
          titleAmharic: 'መዝሙርና ስነ ጥበባት',
          iconName: 'music_note',
          descriptionEn: 'Prepares spiritual hymns, liturgical chants (Zema), sacred Begena/Kirar instruments, Christian drama, and iconography.',
          descriptionAmharic: 'የኦርቶዶክሳዊ ዝማሬዎችን ማጥናት፣ የበገናና ክራር ትምህርት፣ መንፈሳዊ ድራማ፣ ስነ ጽሑፍ እና ስዕለ አድኅኖ ስነ ጥበባት።',
          pillar: MinistryPillar.spiritualEducation,
          teamLead: 'Dawit Fikadu',
          coordinatorBaptismalName: 'Gebre Yohannes',
          coordinatorPhone: '+251933445566',
          coordinatorRole: 'Music & Arts Coordinator',
          openSlots: 12,
          activeCount: 52,
          tags: ['Mezmur', 'Zema', 'Begena', 'Drama', 'Poetry'],
          subWings: [
            'Choir Vocal & Zema (የዝማሬና ዜማ ዘርፍ)',
            'Begena & Instruments (የበገናና መሳሪያዎች)',
            'Spiritual Drama (መንፈሳዊ ቴአትር)',
            'Literature & Poetry (ስነ ጽሑፍና ስንኝ)',
          ],
          meetingSchedule: 'Wednesdays & Saturdays 4:00 PM',
          requirements: 'Punctual rehearsal attendance; dedication to ancient Yaredic traditions.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptDevelopment,
          titleEn: 'Development & Revenue Collection',
          titleAmharic: 'ልማትና ገቢ አሰባሰብ',
          iconName: 'monetization_on_outlined',
          descriptionEn: 'Plans and coordinates fundraising initiatives, holiday sales, spiritual publications distribution, and donor campaigns.',
          descriptionAmharic: 'የገቢ ማስገኛ ፕሮጀክቶችን መንደፍ፣ የበዓላት ባዛርና የንዋየ ቅድሳት ሽያጭ ማስተባበር፣ የበጎ አድራጊዎች ድጋፍ ማሰባሰብ።',
          pillar: MinistryPillar.operationsFinance,
          teamLead: 'Ermias Berhanu',
          coordinatorBaptismalName: 'Habte Maryam',
          coordinatorPhone: '+251944556677',
          coordinatorRole: 'Development Coordinator',
          openSlots: 5,
          activeCount: 22,
          tags: ['Fundraising', 'Bazaar', 'Alumni', 'Projects'],
          subWings: [
            'Fundraising Projects (የገቢ ፕሮጀክቶች)',
            'Holiday Bazaars & Sales (የበዓላት ባዛር)',
            'Alumni Relations (የቀድሞ ተማሪዎች)',
            'Merchandise & Books (የመጻሕፍትና ንዋያተ ቅድሳት)',
          ],
          meetingSchedule: 'Fridays 5:00 PM',
          requirements: 'Project management, marketing creativity, or sales enthusiasm.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptFinanceProperty,
          titleEn: 'Accounting & Property',
          titleAmharic: 'ሒሳብና ንብረት',
          iconName: 'account_balance_wallet',
          descriptionEn: 'Maintains meticulous accounting ledgers, manages fellowship assets, sound systems, robes, and campus church property.',
          descriptionAmharic: 'የፋይናንስና የሂሳብ መዛግብትን መያዝ፣ የድምፅ መሳሪያዎችን፣ አልባሳትና የግብረ ጽድቅ ንብረቶችን በአግባቡ ማስተዳደር።',
          pillar: MinistryPillar.operationsFinance,
          teamLead: 'Bethlehem Girma',
          coordinatorBaptismalName: 'Walata Tsion',
          coordinatorPhone: '+251955667788',
          coordinatorRole: 'Accounting & Property Coordinator',
          openSlots: 4,
          activeCount: 16,
          tags: ['Finance', 'Ledger', 'Audio Gear', 'Inventory'],
          subWings: [
            'Bookkeeping & Finance (የሂሳብ መዝገብ)',
            'Sound & Audio Equipment (የድምፅ መሳሪያዎች)',
            'Church Vestments & Robes (የአልባሳት ንብረት)',
            'Procurement & Logistics (ግዢና አቅርቦት)',
          ],
          meetingSchedule: 'Saturdays 10:00 AM',
          requirements: 'High integrity and diligence; Accounting/Economics background preferred.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptBatchPrograms,
          titleEn: 'Batch & Program Coordination',
          titleAmharic: 'ባችና መርሐ ግብራት ማስተባበሪያ',
          iconName: 'event_available',
          descriptionEn: 'Coordinates year batches (1st to graduating class), reserves campus auditoriums, and manages overall fellowship schedules.',
          descriptionAmharic: 'የየክፍለ ዓመቱን (የባች) ተወካዮች ማስተባበር፣ የአዳራሽና የቦታ ፈቃድ ማመቻቸት፣ ሳምንታዊና ወርሃዊ መርሐ ግብራትን ማቀናጀት።',
          pillar: MinistryPillar.memberCareSocial,
          teamLead: 'Abel Solomon',
          coordinatorBaptismalName: 'Tekle Haymanot',
          coordinatorPhone: '+251966778899',
          coordinatorRole: 'Batch & Programs Coordinator',
          openSlots: 7,
          activeCount: 30,
          tags: ['Batch Reps', 'Hall Booking', 'Conferences', 'Events'],
          subWings: [
            'Freshman Batch Reps (የ1ኛ ዓመት ተወካዮች)',
            'Senior & Graduating Reps (የተመራቂዎች)',
            'Hall Booking & Protocol (የአዳራሽና ፕሮቶኮል)',
            'Vigil & Feast Logistics (የጉባኤያት አቀነባባሪ)',
          ],
          meetingSchedule: 'Mondays 6:00 PM',
          requirements: 'Punctuality, strong organizational communication across batches.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptCharity,
          titleEn: 'Vocational & Charitable Activities',
          titleAmharic: 'ሙያ ና በጎ አድራጎት',
          iconName: 'volunteer_activism',
          descriptionEn: 'Manages student mutual aid, hospital & orphanage visits, blood drives, dorm welfare visits, and vocational peer tutoring.',
          descriptionAmharic: 'ለተቸገሩ ተማሪዎች የምግብና የትምህርት ድጋፍ ማድረግ፣ የሆስፒታልና የአቅመ ደካሞች ጥየቃ፣ የደም ልገሳና የሙያ ማጋራት።',
          pillar: MinistryPillar.memberCareSocial,
          teamLead: 'Rahel Tesfaye',
          coordinatorBaptismalName: 'Walata Michael',
          coordinatorPhone: '+251977889900',
          coordinatorRole: 'Charity Coordinator',
          openSlots: 10,
          activeCount: 40,
          tags: ['Charity', 'Mutual Aid', 'Hospital Visit', 'Blood Drive'],
          subWings: [
            'Student Emergency Fund (የተማሪዎች ድጋፍ)',
            'Hospital & Prison Outreach (የሕሙማን ጥየቃ)',
            'Community Blood Drive (የደም ልገሳ)',
            'Vocational Tutoring (የትምህርትና ሙያ ማጋራት)',
          ],
          meetingSchedule: 'Saturdays 2:00 PM',
          requirements: 'Compassionate heart for charity, active attendance in welfare visits.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptSpecialNeeds,
          titleEn: 'Language & Special Needs',
          titleAmharic: 'ቋንቋና ልዩ ልዩ ፍላጎት',
          iconName: 'translate',
          descriptionEn: 'Provides multilingual liturgical services (Afan Oromo, Tigrinya, English), sign language translation, and accessibility for disabled members.',
          descriptionAmharic: 'በተለያዩ ቋንቋዎች (በአፋን ኦሮሞ፣ በትግርኛ፣ በእንግሊዝኛ) ትምህርቶችን ማዘጋጀት፣ የምልክት ቋንቋ አገልግሎትና አካል ጉዳተኞችን ማገዝ።',
          pillar: MinistryPillar.spiritualEducation,
          teamLead: 'Gemechu Bekele',
          coordinatorBaptismalName: 'Haile Maryam',
          coordinatorPhone: '+251988990011',
          coordinatorRole: 'Language & Special Needs Coordinator',
          openSlots: 8,
          activeCount: 25,
          tags: ['Afan Oromo', 'Sign Language', 'Tigrinya', 'English', 'Inclusion'],
          subWings: [
            'Afan Oromo Ministry (የአፋን ኦሮሞ አገልግሎት)',
            'Tigrinya & Other Languages (የትግርኛና ሌሎች)',
            'Sign Language (የምልክት ቋንቋ)',
            'Accessibility Support (የልዩ ፍላጎት ድጋፍ)',
          ],
          meetingSchedule: 'Sundays 4:00 PM',
          requirements: 'Language fluency or willingness to learn sign language.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptPlanning,
          titleEn: 'Planning & Monitoring',
          titleAmharic: 'እቅድና ክትትል',
          iconName: 'insights',
          descriptionEn: 'Prepares semester/annual strategic plans, tracks project KPIs, monitors department execution, and evaluates performance.',
          descriptionAmharic: 'የግቢ ጉባኤውን ዓመታዊና ሴሚስተራዊ እቅድ ማዘጋጀት፣ የክፍላትን አፈፃፀም መከታተልና የግምገማ ሪፖርቶችን ማቅረብ።',
          pillar: MinistryPillar.governanceAudit,
          teamLead: 'Nahom Assefa',
          coordinatorBaptismalName: 'Gebre Kidan',
          coordinatorPhone: '+251999001122',
          coordinatorRole: 'Planning & Monitoring Coordinator',
          openSlots: 3,
          activeCount: 14,
          tags: ['Strategy', 'KPIs', 'Reports', 'Evaluation'],
          subWings: [
            'Strategic Planning (የስትራቴጂክ እቅድ)',
            'Department Tracking (የክፍላት አፈፃፀም)',
            'Statistical Analysis (የስታቲስቲክስ ትንተና)',
            'Evaluation Seminars (የግምገማ መድረኮች)',
          ],
          meetingSchedule: 'Sundays 6:00 PM',
          requirements: 'Analytical thinking, organizational discipline, 2nd year or above.',
        ),
        MinistryModel(
          id: FellowshipDepartmentConstants.deptAudit,
          titleEn: 'Audit & Inspection',
          titleAmharic: 'ኦዲት ና ኢንስፔክሽን',
          iconName: 'fact_check_outlined',
          descriptionEn: 'Conducts independent financial audits, verifies property registries, and ensures adherence to EOTC fellowship bylaws and canons.',
          descriptionAmharic: 'ገለልተኛ የፋይናንስና የሂሳብ ምርመራ ማካሄድ፣ የንብረት ቆጠራና ማረጋገጫ፣ የደንብና መመሪያ ተገዢነትን መቆጣጠር።',
          pillar: MinistryPillar.governanceAudit,
          teamLead: 'Kaleb Worku',
          coordinatorBaptismalName: 'Wolde Rufael',
          coordinatorPhone: '+251910112233',
          coordinatorRole: 'Audit & Inspection Coordinator',
          openSlots: 3,
          activeCount: 12,
          tags: ['Audit', 'Finance Check', 'Inventory Audit', 'Compliance'],
          subWings: [
            'Financial Audit (የፋይናንስ ቁጥጥር)',
            'Asset Inspection (የንብረት ፍተሻ)',
            'Bylaw Compliance (የመተዳደሪያ ደንብ)',
            'Quarterly Reports (የሩብ ዓመት ሪፖርት)',
          ],
          meetingSchedule: 'Bi-weekly Saturdays 9:00 AM',
          requirements: 'Uncompromising integrity, 3rd/4th year student, background in Accounting/Law/Management.',
        ),
      ];
}

enum ChoirWingType {
  mezmur,
  fineArts,
}

extension ChoirWingTypeExtension on ChoirWingType {
  String get displayName {
    switch (this) {
      case ChoirWingType.mezmur:
        return 'መዝሙር ክፍል (Yaredic Hymnography & Choir)';
      case ChoirWingType.fineArts:
        return 'ስነ ጥበባት ክፍል (Sacred Drama, Poetry & Literature)';
    }
  }

  String get shortName {
    switch (this) {
      case ChoirWingType.mezmur:
        return 'መዝሙር (Choir)';
      case ChoirWingType.fineArts:
        return 'ስነ ጥበባት (Fine Arts)';
    }
  }

  String get coordinatorName {
    switch (this) {
      case ChoirWingType.mezmur:
        return 'Dawit Fikadu';
      case ChoirWingType.fineArts:
        return 'Martha Tedla';
    }
  }
}

enum ApplicationStatus { pending, approved, rejected }

class VolunteerApplicationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentDept;
  final String studentPhone;
  final String studentYear;
  final String ministryId;
  final String ministryTitle;
  final String ministryAmharicTitle;
  final String preferredSubWing;
  final ChoirWingType? choirWing;
  final List<String> languagesKnown;
  final String reason;
  final String experience;
  final String availability;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? reviewedByCoordinator;
  final String? coordinatorNotes;

  VolunteerApplicationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentDept,
    required this.studentPhone,
    this.studentYear = '2nd Year',
    required this.ministryId,
    required this.ministryTitle,
    this.ministryAmharicTitle = '',
    this.preferredSubWing = 'General',
    this.choirWing,
    this.languagesKnown = const [],
    required this.reason,
    required this.experience,
    required this.availability,
    this.status = ApplicationStatus.pending,
    required this.appliedAt,
    this.reviewedAt,
    this.reviewedByCoordinator,
    this.coordinatorNotes,
  });

  VolunteerApplicationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentBaptismalName,
    String? studentDept,
    String? studentPhone,
    String? studentYear,
    String? ministryId,
    String? ministryTitle,
    String? ministryAmharicTitle,
    String? preferredSubWing,
    ChoirWingType? choirWing,
    List<String>? languagesKnown,
    String? reason,
    String? experience,
    String? availability,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? reviewedByCoordinator,
    String? coordinatorNotes,
  }) {
    return VolunteerApplicationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentBaptismalName: studentBaptismalName ?? this.studentBaptismalName,
      studentDept: studentDept ?? this.studentDept,
      studentPhone: studentPhone ?? this.studentPhone,
      studentYear: studentYear ?? this.studentYear,
      ministryId: ministryId ?? this.ministryId,
      ministryTitle: ministryTitle ?? this.ministryTitle,
      ministryAmharicTitle: ministryAmharicTitle ?? this.ministryAmharicTitle,
      preferredSubWing: preferredSubWing ?? this.preferredSubWing,
      choirWing: choirWing ?? this.choirWing,
      languagesKnown: languagesKnown ?? this.languagesKnown,
      reason: reason ?? this.reason,
      experience: experience ?? this.experience,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedByCoordinator: reviewedByCoordinator ?? this.reviewedByCoordinator,
      coordinatorNotes: coordinatorNotes ?? this.coordinatorNotes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentBaptismalName': studentBaptismalName,
      'studentDept': studentDept,
      'studentPhone': studentPhone,
      'studentYear': studentYear,
      'ministryId': ministryId,
      'ministryTitle': ministryTitle,
      'ministryAmharicTitle': ministryAmharicTitle,
      'preferredSubWing': preferredSubWing,
      'choirWing': choirWing?.name,
      'languagesKnown': languagesKnown,
      'reason': reason,
      'experience': experience,
      'availability': availability,
      'status': status.name,
      'appliedAt': appliedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewedByCoordinator': reviewedByCoordinator,
      'coordinatorNotes': coordinatorNotes,
    };
  }

  factory VolunteerApplicationModel.fromMap(Map<String, dynamic> map, String docId) {
    final statusName = map['status']?.toString() ?? 'pending';
    final status = ApplicationStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => ApplicationStatus.pending,
    );
    ChoirWingType? choirWing;
    if (map['choirWing'] != null) {
      choirWing = ChoirWingType.values.firstWhere(
        (c) => c.name == map['choirWing'].toString(),
        orElse: () => ChoirWingType.mezmur,
      );
    }

    return VolunteerApplicationModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentBaptismalName: map['studentBaptismalName'] ?? '',
      studentDept: map['studentDept'] ?? '',
      studentPhone: map['studentPhone'] ?? '',
      studentYear: map['studentYear']?.toString() ?? '2nd Year',
      ministryId: map['ministryId'] ?? '',
      ministryTitle: map['ministryTitle'] ?? '',
      ministryAmharicTitle: map['ministryAmharicTitle'] ?? '',
      preferredSubWing: map['preferredSubWing'] ?? 'General',
      choirWing: choirWing,
      languagesKnown: (map['languagesKnown'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      reason: map['reason'] ?? '',
      experience: map['experience'] ?? '',
      availability: map['availability'] ?? '',
      status: status,
      appliedAt: map['appliedAt'] != null ? DateTime.tryParse(map['appliedAt']) ?? DateTime.now() : DateTime.now(),
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt']) : null,
      reviewedByCoordinator: map['reviewedByCoordinator'],
      coordinatorNotes: map['coordinatorNotes'],
    );
  }
}

class DepartmentMemberModel {
  final String id;
  final String departmentId;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentDept;
  final String studentYear;
  final String phoneNumber;
  final String subWing;
  final ChoirWingType? choirWing;
  final String roleInDepartment;
  final DateTime joinedDate;

  DepartmentMemberModel({
    required this.id,
    required this.departmentId,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentDept,
    required this.studentYear,
    required this.phoneNumber,
    required this.subWing,
    this.choirWing,
    required this.roleInDepartment,
    required this.joinedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'studentId': studentId,
      'studentName': studentName,
      'studentBaptismalName': studentBaptismalName,
      'studentDept': studentDept,
      'studentYear': studentYear,
      'phoneNumber': phoneNumber,
      'subWing': subWing,
      'choirWing': choirWing?.name,
      'roleInDepartment': roleInDepartment,
      'joinedDate': joinedDate.toIso8601String(),
    };
  }

  factory DepartmentMemberModel.fromMap(Map<String, dynamic> map, String docId) {
    ChoirWingType? choirWing;
    if (map['choirWing'] != null) {
      choirWing = ChoirWingType.values.firstWhere(
        (c) => c.name == map['choirWing'].toString(),
        orElse: () => ChoirWingType.mezmur,
      );
    }
    return DepartmentMemberModel(
      id: docId,
      departmentId: map['departmentId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentBaptismalName: map['studentBaptismalName'] ?? '',
      studentDept: map['studentDept'] ?? '',
      studentYear: map['studentYear']?.toString() ?? '1st Year',
      phoneNumber: map['phoneNumber'] ?? '',
      subWing: map['subWing'] ?? 'General',
      choirWing: choirWing,
      roleInDepartment: map['roleInDepartment'] ?? 'Member',
      joinedDate: map['joinedDate'] != null ? DateTime.tryParse(map['joinedDate']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
