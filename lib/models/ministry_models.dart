
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
