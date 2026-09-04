import 'package:flutter/material.dart';

enum UserRole {
  student,
  admin,
  spiritualParent,
  volunteerCoordinator,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student / Fellow';
      case UserRole.admin:
        return 'Admin';
      case UserRole.spiritualParent:
        return 'Spiritual Parent';
      case UserRole.volunteerCoordinator:
        return 'Volunteer Coordinator';
    }
  }

  Color get badgeColor {
    switch (this) {
      case UserRole.admin:
        return const Color(0xFFEF4444);
      case UserRole.spiritualParent:
        return const Color(0xFFF59E0B);
      case UserRole.volunteerCoordinator:
        return const Color(0xFF3B82F6);
      case UserRole.student:
        return const Color(0xFF10B981);
    }
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String baptismalName;
  final String phoneNumber;
  final String batchYear;
  final String department;
  final int academicYear; // 1 to 8
  final UserRole role;
  final bool isApproved;
  final List<String> badges;
  final String ministryStatus; // e.g. "Choir Member", "Hospitality Volunteer", "None"
  final String? assignedFamilyId;
  final String? avatarUrl;
  final double attendancePercentage; // e.g. 88.0

  UserModel({
    required this.id,
    required this.fullName,
    required this.baptismalName,
    required this.phoneNumber,
    required this.batchYear,
    required this.department,
    required this.academicYear,
    this.role = UserRole.student,
    this.isApproved = true,
    this.badges = const [],
    this.ministryStatus = 'General Fellow',
    this.assignedFamilyId,
    this.avatarUrl,
    this.attendancePercentage = 85.0,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? baptismalName,
    String? phoneNumber,
    String? batchYear,
    String? department,
    int? academicYear,
    UserRole? role,
    bool? isApproved,
    List<String>? badges,
    String? ministryStatus,
    String? assignedFamilyId,
    String? avatarUrl,
    double? attendancePercentage,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      baptismalName: baptismalName ?? this.baptismalName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      batchYear: batchYear ?? this.batchYear,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      badges: badges ?? this.badges,
      ministryStatus: ministryStatus ?? this.ministryStatus,
      assignedFamilyId: assignedFamilyId ?? this.assignedFamilyId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    );
  }
}

class SpiritualParentModel {
  final String id;
  final String fullName;
  final String baptismalName;
  final String department;
  final String faculty;
  final String phoneNumber;
  final String roleTitle; // 'Spiritual Father' or 'Spiritual Mother'
  final String? avatarUrl;

  SpiritualParentModel({
    required this.id,
    required this.fullName,
    required this.baptismalName,
    required this.department,
    required this.faculty,
    required this.phoneNumber,
    required this.roleTitle,
    this.avatarUrl,
  });
}

class FamilyModel {
  final String id;
  final String name; // e.g. "Family of St. George"
  final String formedDate;
  final SpiritualParentModel spiritualFather;
  final SpiritualParentModel spiritualMother;
  final int maxCapacity;
  final String telegramGroupUrl;
  final String whatsappGroupUrl;
  final bool isPublished;
  final List<String> memberIds;

  FamilyModel({
    required this.id,
    required this.name,
    required this.formedDate,
    required this.spiritualFather,
    required this.spiritualMother,
    this.maxCapacity = 10,
    required this.telegramGroupUrl,
    required this.whatsappGroupUrl,
    this.isPublished = false,
    required this.memberIds,
  });

  int get memberCount => memberIds.length;

  FamilyModel copyWith({
    String? id,
    String? name,
    String? formedDate,
    SpiritualParentModel? spiritualFather,
    SpiritualParentModel? spiritualMother,
    int? maxCapacity,
    String? telegramGroupUrl,
    String? whatsappGroupUrl,
    bool? isPublished,
    List<String>? memberIds,
  }) {
    return FamilyModel(
      id: id ?? this.id,
      name: name ?? this.name,
      formedDate: formedDate ?? this.formedDate,
      spiritualFather: spiritualFather ?? this.spiritualFather,
      spiritualMother: spiritualMother ?? this.spiritualMother,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      telegramGroupUrl: telegramGroupUrl ?? this.telegramGroupUrl,
      whatsappGroupUrl: whatsappGroupUrl ?? this.whatsappGroupUrl,
      isPublished: isPublished ?? this.isPublished,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}

enum AttendanceStatus { present, late, absent }

enum AttendanceCheckInMethod { qr, pin }

class AttendanceRecordModel {
  final String id;
  final String studentId;
  final String studentName;
  final DateTime timestamp;
  final AttendanceStatus status;
  final AttendanceCheckInMethod method;
  final String courseName;

  AttendanceRecordModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.timestamp,
    required this.status,
    required this.method,
    required this.courseName,
  });
}

class AttendanceSessionModel {
  final String sessionId;
  final String courseName;
  final String courseCode;
  final String faculty;
  final String code;
  final String rollingPin;
  final DateTime generatedAt;
  final int refreshIntervalSeconds;
  final int totalEnrolled;
  final List<AttendanceRecordModel> scans;

  AttendanceSessionModel({
    required this.sessionId,
    required this.courseName,
    required this.courseCode,
    required this.faculty,
    required this.code,
    required this.rollingPin,
    required this.generatedAt,
    this.refreshIntervalSeconds = 30,
    this.totalEnrolled = 50,
    this.scans = const [],
  });

  int get presentCount => scans.where((s) => s.status == AttendanceStatus.present).length;
  int get lateCount => scans.where((s) => s.status == AttendanceStatus.late).length;
  int get absentCount => (totalEnrolled - scans.length).clamp(0, totalEnrolled);

  AttendanceSessionModel copyWith({
    String? sessionId,
    String? courseName,
    String? courseCode,
    String? faculty,
    String? code,
    String? rollingPin,
    DateTime? generatedAt,
    int? refreshIntervalSeconds,
    int? totalEnrolled,
    List<AttendanceRecordModel>? scans,
  }) {
    return AttendanceSessionModel(
      sessionId: sessionId ?? this.sessionId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      faculty: faculty ?? this.faculty,
      code: code ?? this.code,
      rollingPin: rollingPin ?? this.rollingPin,
      generatedAt: generatedAt ?? this.generatedAt,
      refreshIntervalSeconds: refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      totalEnrolled: totalEnrolled ?? this.totalEnrolled,
      scans: scans ?? this.scans,
    );
  }
}

enum RoadmapStatus { completed, inProgress, locked }

class LessonModel {
  final String id;
  final String title;
  final String summary;
  final List<String> readingList;
  final bool isDownloaded;
  final int durationMinutes;
  final String? audioLink;

  LessonModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.readingList,
    this.isDownloaded = false,
    this.durationMinutes = 45,
    this.audioLink,
  });

  LessonModel copyWith({
    String? id,
    String? title,
    String? summary,
    List<String>? readingList,
    bool? isDownloaded,
    int? durationMinutes,
    String? audioLink,
  }) {
    return LessonModel(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      readingList: readingList ?? this.readingList,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      audioLink: audioLink ?? this.audioLink,
    );
  }
}

class RoadmapPhaseModel {
  final String id;
  final String title;
  final String description;
  final RoadmapStatus status;
  final double progress; // 0.0 to 1.0
  final List<LessonModel> weeklyLessons;
  final List<String> prerequisites;
  final String instructor;
  final String batchYear;
  final String semester;

  RoadmapPhaseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.weeklyLessons,
    this.prerequisites = const [],
    required this.instructor,
    this.batchYear = '2024',
    this.semester = 'Semester 1',
  });

  RoadmapPhaseModel copyWith({
    String? id,
    String? title,
    String? description,
    RoadmapStatus? status,
    double? progress,
    List<LessonModel>? weeklyLessons,
    List<String>? prerequisites,
    String? instructor,
    String? batchYear,
    String? semester,
  }) {
    return RoadmapPhaseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      weeklyLessons: weeklyLessons ?? this.weeklyLessons,
      prerequisites: prerequisites ?? this.prerequisites,
      instructor: instructor ?? this.instructor,
      batchYear: batchYear ?? this.batchYear,
      semester: semester ?? this.semester,
    );
  }
}

enum LibraryCategory { patristics, liturgical, mezmur, dogma, general }

class LibraryItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final LibraryCategory category;
  final List<String> tags; // e.g. ["Patristics", "Ge'ez / Amharic"]
  final String telegramUrl; // Direct Telegram Link to Book/Audio
  final String? sourceUrl;
  final bool isRestricted;
  final List<UserRole> allowedRoles;
  final String? readTime;
  final String? audioDuration;
  final String? coverAssetPath;
  final String? lyricsOrExcerpts;
  final bool isBookmarked;

  LibraryItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.tags,
    required this.telegramUrl,
    this.sourceUrl,
    this.isRestricted = false,
    this.allowedRoles = const [UserRole.student, UserRole.admin, UserRole.spiritualParent, UserRole.volunteerCoordinator],
    this.readTime,
    this.audioDuration,
    this.coverAssetPath,
    this.lyricsOrExcerpts,
    this.isBookmarked = false,
  });

  LibraryItemModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    LibraryCategory? category,
    List<String>? tags,
    String? telegramUrl,
    String? sourceUrl,
    bool? isRestricted,
    List<UserRole>? allowedRoles,
    String? readTime,
    String? audioDuration,
    String? coverAssetPath,
    String? lyricsOrExcerpts,
    bool? isBookmarked,
  }) {
    return LibraryItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      telegramUrl: telegramUrl ?? this.telegramUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isRestricted: isRestricted ?? this.isRestricted,
      allowedRoles: allowedRoles ?? this.allowedRoles,
      readTime: readTime ?? this.readTime,
      audioDuration: audioDuration ?? this.audioDuration,
      coverAssetPath: coverAssetPath ?? this.coverAssetPath,
      lyricsOrExcerpts: lyricsOrExcerpts ?? this.lyricsOrExcerpts,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

class ChurchProgramModel {
  final String id;
  final String title;
  final String churchName;
  final DateTime dateTime;
  final Duration initialDurationRemaining;
  final bool isEmergency;
  final bool reminderEnabled;
  final String description;
  final String? liveFeedUrl;
  final String category; // 'Liturgy', 'Feast', 'Prayer Meeting', 'Bible Study'

  ChurchProgramModel({
    required this.id,
    required this.title,
    required this.churchName,
    required this.dateTime,
    required this.initialDurationRemaining,
    this.isEmergency = false,
    this.reminderEnabled = true,
    required this.description,
    this.liveFeedUrl,
    this.category = 'Liturgy',
  });

  ChurchProgramModel copyWith({
    String? id,
    String? title,
    String? churchName,
    DateTime? dateTime,
    Duration? initialDurationRemaining,
    bool? isEmergency,
    bool? reminderEnabled,
    String? description,
    String? liveFeedUrl,
    String? category,
  }) {
    return ChurchProgramModel(
      id: id ?? this.id,
      title: title ?? this.title,
      churchName: churchName ?? this.churchName,
      dateTime: dateTime ?? this.dateTime,
      initialDurationRemaining: initialDurationRemaining ?? this.initialDurationRemaining,
      isEmergency: isEmergency ?? this.isEmergency,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      description: description ?? this.description,
      liveFeedUrl: liveFeedUrl ?? this.liveFeedUrl,
      category: category ?? this.category,
    );
  }
}

// ============================================================================
// VOLUNTARY SERVING & 10 EOTC FELLOWSHIP DEPARTMENTS
// ============================================================================

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
    required this.roleInDepartment,
    required this.joinedDate,
  });
}

// ============================================================================
// 1. ETHIOPIAN LITURGICAL CALENDAR & FASTING MODELS
// ============================================================================

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
  midnightGold,       // Classic Midnight Liturgical Gold
  axumiteBurgundy,    // Axumite Royal Monastic Burgundy
  lalibelaSandstone,  // Lalibela Rock-Hewn Sandstone Amber
  tewahedoForest,     // Tewahedo Midnight Forest Emerald
  debreDamoAzure,     // Debre Damo Midnight Sky Azure
}

extension AppThemePaletteExt on AppThemePalette {
  String get displayName {
    switch (this) {
      case AppThemePalette.midnightGold:
        return 'Sacred Gold (ክቡር ወርቅ)';
      case AppThemePalette.axumiteBurgundy:
        return 'Liturgical Crimson (ቀይ ልብስ)';
      case AppThemePalette.tewahedoForest:
        return 'St. Mary Emerald (ማርያም አረንጓዴ)';
      case AppThemePalette.debreDamoAzure:
        return 'Royal Sapphire (ሰማያዊ ኪዳን)';
      case AppThemePalette.lalibelaSandstone:
        return 'Lalibela Sandstone Amber (ላሊበላ አምበር)';
    }
  }

  String get amharicName {
    switch (this) {
      case AppThemePalette.midnightGold:
        return 'ወርቃማ ሥርዓተ ቤተክርስቲያን';
      case AppThemePalette.axumiteBurgundy:
        return 'አክሱማዊ ንጉሣዊ ቀይ ልብስ';
      case AppThemePalette.tewahedoForest:
        return 'ተዋሕዶ ልምላሜና ሰላም';
      case AppThemePalette.debreDamoAzure:
        return 'ደብረ ዳሞ ሰማያዊ ጸጋ';
      case AppThemePalette.lalibelaSandstone:
        return 'ላሊበላ ገዳማዊ ጽናት';
    }
  }

  Color get primaryAccent {
    switch (this) {
      case AppThemePalette.midnightGold:
        return const Color(0xFFF5A65E);
      case AppThemePalette.axumiteBurgundy:
        return const Color(0xFFF87171);
      case AppThemePalette.tewahedoForest:
        return const Color(0xFF34D399);
      case AppThemePalette.debreDamoAzure:
        return const Color(0xFF60A5FA);
      case AppThemePalette.lalibelaSandstone:
        return const Color(0xFFFBBF24);
    }
  }

  Color get secondaryAccent {
    switch (this) {
      case AppThemePalette.midnightGold:
        return const Color(0xFFD48B38);
      case AppThemePalette.axumiteBurgundy:
        return const Color(0xFFEF4444);
      case AppThemePalette.tewahedoForest:
        return const Color(0xFF10B981);
      case AppThemePalette.debreDamoAzure:
        return const Color(0xFF3B82F6);
      case AppThemePalette.lalibelaSandstone:
        return const Color(0xFFF59E0B);
    }
  }

  Color get scaffoldBg {
    switch (this) {
      case AppThemePalette.midnightGold:
        return const Color(0xFF0C1017);
      case AppThemePalette.axumiteBurgundy:
        return const Color(0xFF15070E);
      case AppThemePalette.tewahedoForest:
        return const Color(0xFF04120B);
      case AppThemePalette.debreDamoAzure:
        return const Color(0xFF050E1A);
      case AppThemePalette.lalibelaSandstone:
        return const Color(0xFF130E07);
    }
  }

  Color get surfaceBg {
    switch (this) {
      case AppThemePalette.midnightGold:
        return const Color(0xFF131923);
      case AppThemePalette.axumiteBurgundy:
        return const Color(0xFF220C18);
      case AppThemePalette.tewahedoForest:
        return const Color(0xFF0B1E13);
      case AppThemePalette.debreDamoAzure:
        return const Color(0xFF0B1728);
      case AppThemePalette.lalibelaSandstone:
        return const Color(0xFF1D150B);
    }
  }

  Color get cardBg {
    switch (this) {
      case AppThemePalette.midnightGold:
        return const Color(0xFF1B2332);
      case AppThemePalette.axumiteBurgundy:
        return const Color(0xFF301222);
      case AppThemePalette.tewahedoForest:
        return const Color(0xFF122C1C);
      case AppThemePalette.debreDamoAzure:
        return const Color(0xFF12223B);
      case AppThemePalette.lalibelaSandstone:
        return const Color(0xFF2B1F11);
    }
  }

  Color get elevatedBg {
    switch (this) {
      case AppThemePalette.midnightGold:
        return const Color(0xFF242F42);
      case AppThemePalette.axumiteBurgundy:
        return const Color(0xFF40182E);
      case AppThemePalette.tewahedoForest:
        return const Color(0xFF1A3B27);
      case AppThemePalette.debreDamoAzure:
        return const Color(0xFF1A2F50);
      case AppThemePalette.lalibelaSandstone:
        return const Color(0xFF3B2A18);
    }
  }
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

class ConfessorFatherModel {
  final String id;
  final String fullName;
  final String clericalTitle; // e.g. "መልአከ ሰላም ቀሲስ ዮሐንስ", "ቆሞስ አባ ገብረ ሥላሴ"
  final String churchName;
  final String meetingVenue; // e.g. "St. Mary's Sunday School Office (Room 2)"
  final String phoneNumber;
  final List<String> availableDays; // e.g. ["Saturday", "Sunday", "Wednesday"]
  final List<String> availableTimeSlots; // e.g. ["3:00 PM - 5:00 PM", "9:00 AM - 11:30 AM"]
  final String bio;
  final String? avatarUrl;

  const ConfessorFatherModel({
    required this.id,
    required this.fullName,
    required this.clericalTitle,
    required this.churchName,
    this.meetingVenue = "St. Mary's Sunday School Office (Room 2)",
    required this.phoneNumber,
    required this.availableDays,
    required this.availableTimeSlots,
    required this.bio,
    this.avatarUrl,
  });

  ConfessorFatherModel copyWith({
    String? id,
    String? fullName,
    String? clericalTitle,
    String? churchName,
    String? meetingVenue,
    String? phoneNumber,
    List<String>? availableDays,
    List<String>? availableTimeSlots,
    String? bio,
    String? avatarUrl,
  }) {
    return ConfessorFatherModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      clericalTitle: clericalTitle ?? this.clericalTitle,
      churchName: churchName ?? this.churchName,
      meetingVenue: meetingVenue ?? this.meetingVenue,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      availableDays: availableDays ?? this.availableDays,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

enum ConfessionAppointmentStatus { pending, confirmed, completed, cancelled }

extension ConfessionAppointmentStatusExt on ConfessionAppointmentStatus {
  String get displayName {
    switch (this) {
      case ConfessionAppointmentStatus.pending:
        return 'Pending Approval';
      case ConfessionAppointmentStatus.confirmed:
        return 'Confirmed';
      case ConfessionAppointmentStatus.completed:
        return 'Completed';
      case ConfessionAppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case ConfessionAppointmentStatus.pending:
        return const Color(0xFFF59E0B);
      case ConfessionAppointmentStatus.confirmed:
        return const Color(0xFF10B981);
      case ConfessionAppointmentStatus.completed:
        return const Color(0xFF3B82F6);
      case ConfessionAppointmentStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }
}

class ConfessionAppointmentModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentPhone;
  final String fatherId;
  final String fatherName;
  final DateTime scheduledDate;
  final String timeSlot;
  final String topic; // "General Confession", "Spiritual Counseling", "Communion Preparation"
  final ConfessionAppointmentStatus status;
  final String? notes;

  ConfessionAppointmentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentPhone,
    required this.fatherId,
    required this.fatherName,
    required this.scheduledDate,
    required this.timeSlot,
    required this.topic,
    this.status = ConfessionAppointmentStatus.pending,
    this.notes,
  });

  ConfessionAppointmentModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentBaptismalName,
    String? studentPhone,
    String? fatherId,
    String? fatherName,
    DateTime? scheduledDate,
    String? timeSlot,
    String? topic,
    ConfessionAppointmentStatus? status,
    String? notes,
  }) {
    return ConfessionAppointmentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentBaptismalName: studentBaptismalName ?? this.studentBaptismalName,
      studentPhone: studentPhone ?? this.studentPhone,
      fatherId: fatherId ?? this.fatherId,
      fatherName: fatherName ?? this.fatherName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeSlot: timeSlot ?? this.timeSlot,
      topic: topic ?? this.topic,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class AnonymousSpiritualQuestionModel {
  final String id;
  final String questionText;
  final String category; // "Theology & Dogma", "Campus Life & Morals", "Fasting & Canon"
  final DateTime askedAt;
  final bool isAnswered;
  final String? answerText;
  final String? answeredBy;
  final bool isPublic;

  AnonymousSpiritualQuestionModel({
    required this.id,
    required this.questionText,
    required this.category,
    required this.askedAt,
    this.isAnswered = false,
    this.answerText,
    this.answeredBy,
    this.isPublic = true,
  });

  AnonymousSpiritualQuestionModel copyWith({
    String? id,
    String? questionText,
    String? category,
    DateTime? askedAt,
    bool? isAnswered,
    String? answerText,
    String? answeredBy,
    bool? isPublic,
  }) {
    return AnonymousSpiritualQuestionModel(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      category: category ?? this.category,
      askedAt: askedAt ?? this.askedAt,
      isAnswered: isAnswered ?? this.isAnswered,
      answerText: answerText ?? this.answerText,
      answeredBy: answeredBy ?? this.answeredBy,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}

class CommunionChecklistItem {
  final String id;
  final String title;
  final String description;
  bool isChecked;

  CommunionChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.isChecked = false,
  });
}

// ============================================================================
// 4. PILGRIMAGE & TRIP COORDINATOR (WITH TELEBIRR / CBE PAYMENT) MODELS
// ============================================================================

enum PaymentMethodType {
  telebirr,
  cbeBirr,
  cbeAccount,
  free,
}

extension PaymentMethodTypeExt on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.telebirr:
        return 'Telebirr (ቴሌብር)';
      case PaymentMethodType.cbeBirr:
        return 'CBE Birr (ሲቢኢ ብር)';
      case PaymentMethodType.cbeAccount:
        return 'CBE Account Transfer (የንግድ ባንክ ሒሳብ)';
      case PaymentMethodType.free:
        return 'Free / No Fee (ነፃ)';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodType.telebirr:
        return Icons.phone_android;
      case PaymentMethodType.cbeBirr:
        return Icons.account_balance_wallet;
      case PaymentMethodType.cbeAccount:
        return Icons.account_balance;
      case PaymentMethodType.free:
        return Icons.check_circle_outline;
    }
  }
}

enum TripPaymentStatus {
  pendingVerification,
  verified,
  rejected,
  free,
}

extension TripPaymentStatusExt on TripPaymentStatus {
  String get displayName {
    switch (this) {
      case TripPaymentStatus.pendingVerification:
        return 'Pending Verification';
      case TripPaymentStatus.verified:
        return 'Confirmed / Ticket Issued';
      case TripPaymentStatus.rejected:
        return 'Payment Declined';
      case TripPaymentStatus.free:
        return 'Confirmed (Free)';
    }
  }

  Color get color {
    switch (this) {
      case TripPaymentStatus.pendingVerification:
        return const Color(0xFFF59E0B);
      case TripPaymentStatus.verified:
      case TripPaymentStatus.free:
        return const Color(0xFF10B981);
      case TripPaymentStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

class PilgrimageTripModel {
  final String id;
  final String title;
  final String destination;
  final DateTime departureDate;
  final DateTime returnDate;
  final String departurePoint;
  final bool isFree;
  final double feeAmount; // 0.0 if free
  final String telebirrNumber;
  final String telebirrAccountName;
  final String cbeAccountNumber;
  final String cbeAccountName;
  final int totalSeats;
  final int bookedSeats;
  final List<String> itinerary;
  final List<String> packingList;
  final String coordinatorName;
  final String coordinatorPhone;
  final String? bannerAssetPath;

  const PilgrimageTripModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.departurePoint,
    this.isFree = false,
    this.feeAmount = 0.0,
    required this.telebirrNumber,
    required this.telebirrAccountName,
    required this.cbeAccountNumber,
    required this.cbeAccountName,
    required this.totalSeats,
    required this.bookedSeats,
    required this.itinerary,
    required this.packingList,
    required this.coordinatorName,
    required this.coordinatorPhone,
    this.bannerAssetPath,
  });

  int get availableSeats => (totalSeats - bookedSeats).clamp(0, totalSeats);

  PilgrimageTripModel copyWith({
    String? id,
    String? title,
    String? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    String? departurePoint,
    bool? isFree,
    double? feeAmount,
    String? telebirrNumber,
    String? telebirrAccountName,
    String? cbeAccountNumber,
    String? cbeAccountName,
    int? totalSeats,
    int? bookedSeats,
    List<String>? itinerary,
    List<String>? packingList,
    String? coordinatorName,
    String? coordinatorPhone,
    String? bannerAssetPath,
  }) {
    return PilgrimageTripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      departurePoint: departurePoint ?? this.departurePoint,
      isFree: isFree ?? this.isFree,
      feeAmount: feeAmount ?? this.feeAmount,
      telebirrNumber: telebirrNumber ?? this.telebirrNumber,
      telebirrAccountName: telebirrAccountName ?? this.telebirrAccountName,
      cbeAccountNumber: cbeAccountNumber ?? this.cbeAccountNumber,
      cbeAccountName: cbeAccountName ?? this.cbeAccountName,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      itinerary: itinerary ?? this.itinerary,
      packingList: packingList ?? this.packingList,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorPhone: coordinatorPhone ?? this.coordinatorPhone,
      bannerAssetPath: bannerAssetPath ?? this.bannerAssetPath,
    );
  }
}

class TripRegistrationModel {
  final String id;
  final String tripId;
  final String tripTitle;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentPhone;
  final String department;
  final int academicYear;
  final int busNumber;
  final int seatNumber;
  final double feeAmount;
  final bool isFree;
  final PaymentMethodType paymentMethod;
  final String transactionReference;
  final TripPaymentStatus paymentStatus;
  final String qrTicketCode;
  final DateTime registeredAt;

  TripRegistrationModel({
    required this.id,
    required this.tripId,
    required this.tripTitle,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentPhone,
    required this.department,
    required this.academicYear,
    required this.busNumber,
    required this.seatNumber,
    required this.feeAmount,
    this.isFree = false,
    required this.paymentMethod,
    required this.transactionReference,
    this.paymentStatus = TripPaymentStatus.pendingVerification,
    required this.qrTicketCode,
    required this.registeredAt,
  });

  TripRegistrationModel copyWith({
    String? id,
    String? tripId,
    String? tripTitle,
    String? studentId,
    String? studentName,
    String? studentBaptismalName,
    String? studentPhone,
    String? department,
    int? academicYear,
    int? busNumber,
    int? seatNumber,
    double? feeAmount,
    bool? isFree,
    PaymentMethodType? paymentMethod,
    String? transactionReference,
    TripPaymentStatus? paymentStatus,
    String? qrTicketCode,
    DateTime? registeredAt,
  }) {
    return TripRegistrationModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripTitle: tripTitle ?? this.tripTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentBaptismalName: studentBaptismalName ?? this.studentBaptismalName,
      studentPhone: studentPhone ?? this.studentPhone,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      busNumber: busNumber ?? this.busNumber,
      seatNumber: seatNumber ?? this.seatNumber,
      feeAmount: feeAmount ?? this.feeAmount,
      isFree: isFree ?? this.isFree,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      qrTicketCode: qrTicketCode ?? this.qrTicketCode,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }
}

// ============================================================================
// 5. STUDENT MUTUAL AID & CHARITY FUND MODELS
// ============================================================================

class CharityCampaignModel {
  final String id;
  final String title;
  final String description;
  final double targetAmount;
  final double raisedAmount;
  final int donorsCount;
  final DateTime deadline;
  final bool isEmergency;
  final String category; // "Student Mutual Aid", "Orphanage Outreach", "Church Construction"

  const CharityCampaignModel({
    required this.id,
    required this.title,
    required this.description,
    required this.targetAmount,
    required this.raisedAmount,
    required this.donorsCount,
    required this.deadline,
    this.isEmergency = false,
    this.category = 'Student Mutual Aid',
  });

  double get progressPercentage => (raisedAmount / targetAmount).clamp(0.0, 1.0);
}

class DuesPaymentModel {
  final String id;
  final String studentId;
  final String studentName;
  final double amount;
  final String purpose; // "Monthly Fellowship Dues", "Student Aid Donation"
  final PaymentMethodType paymentMethod;
  final String transactionReference;
  final String status; // "Verified", "Pending Verification"
  final DateTime submittedAt;

  const DuesPaymentModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.amount,
    required this.purpose,
    required this.paymentMethod,
    required this.transactionReference,
    required this.status,
    required this.submittedAt,
  });
}

enum EmergencyAidCategory {
  medical,
  foodCafeteria,
  academicSupplies,
  emergencyTransport,
  other,
}

extension EmergencyAidCategoryExt on EmergencyAidCategory {
  String get displayName {
    switch (this) {
      case EmergencyAidCategory.medical:
        return 'Medical & Prescription (ሕክምና)';
      case EmergencyAidCategory.foodCafeteria:
        return 'Food & Living Expenses (ምግብና ኑሮ)';
      case EmergencyAidCategory.academicSupplies:
        return 'Academic Supplies (መጻሕፍትና ማቴሪያል)';
      case EmergencyAidCategory.emergencyTransport:
        return 'Emergency Travel (ድንገተኛ ጉዞ)';
      case EmergencyAidCategory.other:
        return 'Other Urgent Need (ሌላ አስቸኳይ)';
    }
  }
}

enum EmergencyAidStatus {
  underReview,
  approved,
  disbursed,
  declined,
}

extension EmergencyAidStatusExt on EmergencyAidStatus {
  String get displayName {
    switch (this) {
      case EmergencyAidStatus.underReview:
        return 'Under Review';
      case EmergencyAidStatus.approved:
        return 'Approved';
      case EmergencyAidStatus.disbursed:
        return 'Aid Disbursed';
      case EmergencyAidStatus.declined:
        return 'Declined';
    }
  }

  Color get color {
    switch (this) {
      case EmergencyAidStatus.underReview:
        return const Color(0xFFF59E0B);
      case EmergencyAidStatus.approved:
        return const Color(0xFF3B82F6);
      case EmergencyAidStatus.disbursed:
        return const Color(0xFF10B981);
      case EmergencyAidStatus.declined:
        return const Color(0xFFEF4444);
    }
  }
}

class EmergencyAidRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentPhone;
  final String department;
  final int academicYear;
  final EmergencyAidCategory category;
  final String description;
  final double amountRequested;
  final EmergencyAidStatus status;
  final DateTime submittedAt;
  final String? adminNote;

  EmergencyAidRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentPhone,
    required this.department,
    required this.academicYear,
    required this.category,
    required this.description,
    required this.amountRequested,
    this.status = EmergencyAidStatus.underReview,
    required this.submittedAt,
    this.adminNote,
  });

  EmergencyAidRequestModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentBaptismalName,
    String? studentPhone,
    String? department,
    int? academicYear,
    EmergencyAidCategory? category,
    String? description,
    double? amountRequested,
    EmergencyAidStatus? status,
    DateTime? submittedAt,
    String? adminNote,
  }) {
    return EmergencyAidRequestModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentBaptismalName: studentBaptismalName ?? this.studentBaptismalName,
      studentPhone: studentPhone ?? this.studentPhone,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      category: category ?? this.category,
      description: description ?? this.description,
      amountRequested: amountRequested ?? this.amountRequested,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      adminNote: adminNote ?? this.adminNote,
    );
  }
}

// ============================================================================
// 6. DEPARTMENT MENTORSHIP MATCHING MODELS
// ============================================================================

class AcademicMentorModel {
  final String id;
  final String studentId;
  final String fullName;
  final String baptismalName;
  final String department;
  final int academicYear; // e.g. 4 or 5
  final List<String> specialties; // e.g. ["Data Structures", "Algorithms", "Database Systems"]
  final String telegramHandle;
  final String phoneNumber;
  final int activeMenteesCount;
  final int maxMentees;
  final bool isAvailable;

  const AcademicMentorModel({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.baptismalName,
    required this.department,
    required this.academicYear,
    required this.specialties,
    required this.telegramHandle,
    required this.phoneNumber,
    this.activeMenteesCount = 1,
    this.maxMentees = 3,
    this.isAvailable = true,
  });

  AcademicMentorModel copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? baptismalName,
    String? department,
    int? academicYear,
    List<String>? specialties,
    String? telegramHandle,
    String? phoneNumber,
    int? activeMenteesCount,
    int? maxMentees,
    bool? isAvailable,
  }) {
    return AcademicMentorModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      baptismalName: baptismalName ?? this.baptismalName,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      specialties: specialties ?? this.specialties,
      telegramHandle: telegramHandle ?? this.telegramHandle,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      activeMenteesCount: activeMenteesCount ?? this.activeMenteesCount,
      maxMentees: maxMentees ?? this.maxMentees,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

enum MentorshipStatus { pending, matched, completed, declined }

class MentorshipRequestModel {
  final String id;
  final String juniorStudentId;
  final String juniorName;
  final String juniorBaptismalName;
  final String department;
  final int academicYear;
  final String mentorId;
  final String mentorName;
  final String coursesNeeded;
  final MentorshipStatus status;
  final DateTime requestedAt;

  MentorshipRequestModel({
    required this.id,
    required this.juniorStudentId,
    required this.juniorName,
    required this.juniorBaptismalName,
    required this.department,
    required this.academicYear,
    required this.mentorId,
    required this.mentorName,
    required this.coursesNeeded,
    this.status = MentorshipStatus.pending,
    required this.requestedAt,
  });

  MentorshipRequestModel copyWith({
    String? id,
    String? juniorStudentId,
    String? juniorName,
    String? juniorBaptismalName,
    String? department,
    int? academicYear,
    String? mentorId,
    String? mentorName,
    String? coursesNeeded,
    MentorshipStatus? status,
    DateTime? requestedAt,
  }) {
    return MentorshipRequestModel(
      id: id ?? this.id,
      juniorStudentId: juniorStudentId ?? this.juniorStudentId,
      juniorName: juniorName ?? this.juniorName,
      juniorBaptismalName: juniorBaptismalName ?? this.juniorBaptismalName,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      mentorId: mentorId ?? this.mentorId,
      mentorName: mentorName ?? this.mentorName,
      coursesNeeded: coursesNeeded ?? this.coursesNeeded,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }
}

// ============================================================================
// 7. THEOLOGICAL TRIVIA & WEEKLY FAITH CHALLENGE MODELS
// ============================================================================

class TriviaQuestionModel {
  final String id;
  final String questionAmharic;
  final String questionEnglish;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final String bibleReference;

  const TriviaQuestionModel({
    required this.id,
    required this.questionAmharic,
    required this.questionEnglish,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.bibleReference,
  });
}

class TriviaQuizModel {
  final String id;
  final int weekNumber;
  final String title;
  final String description;
  final List<TriviaQuestionModel> questions;
  final int timeLimitMinutes;

  const TriviaQuizModel({
    required this.id,
    required this.weekNumber,
    required this.title,
    required this.description,
    required this.questions,
    this.timeLimitMinutes = 5,
  });
}

class QuizAttemptModel {
  final String id;
  final String studentId;
  final String studentName;
  final String familyId;
  final String familyName;
  final String quizId;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;

  const QuizAttemptModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.familyId,
    required this.familyName,
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
  });
}

class FamilyLeaderboardEntry {
  final String familyId;
  final String familyName;
  final int totalScore;
  final int participantsCount;
  final int rank;

  const FamilyLeaderboardEntry({
    required this.familyId,
    required this.familyName,
    required this.totalScore,
    required this.participantsCount,
    required this.rank,
  });
}

