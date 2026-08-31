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

class MinistryModel {
  final String id;
  final String title;
  final String iconName;
  final String description;
  final String teamLead;
  final int openSlots;
  final int activeCount;
  final List<String> tags;

  MinistryModel({
    required this.id,
    required this.title,
    required this.iconName,
    required this.description,
    required this.teamLead,
    required this.openSlots,
    required this.activeCount,
    required this.tags,
  });
}

enum ApplicationStatus { pending, approved, rejected }

class VolunteerApplicationModel {
  final String id;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentDept;
  final String studentPhone;
  final String ministryId;
  final String ministryTitle;
  final String reason;
  final String experience;
  final String availability;
  final ApplicationStatus status;
  final DateTime appliedAt;

  VolunteerApplicationModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentDept,
    required this.studentPhone,
    required this.ministryId,
    required this.ministryTitle,
    required this.reason,
    required this.experience,
    required this.availability,
    this.status = ApplicationStatus.pending,
    required this.appliedAt,
  });

  VolunteerApplicationModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? studentBaptismalName,
    String? studentDept,
    String? studentPhone,
    String? ministryId,
    String? ministryTitle,
    String? reason,
    String? experience,
    String? availability,
    ApplicationStatus? status,
    DateTime? appliedAt,
  }) {
    return VolunteerApplicationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentBaptismalName: studentBaptismalName ?? this.studentBaptismalName,
      studentDept: studentDept ?? this.studentDept,
      studentPhone: studentPhone ?? this.studentPhone,
      ministryId: ministryId ?? this.ministryId,
      ministryTitle: ministryTitle ?? this.ministryTitle,
      reason: reason ?? this.reason,
      experience: experience ?? this.experience,
      availability: availability ?? this.availability,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}
