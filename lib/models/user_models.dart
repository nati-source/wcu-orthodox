import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, admin, spiritualParent, volunteerCoordinator }

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

// ============================================================================
// 10 EOTC FELLOWSHIP DEPARTMENTS & RBAC CONSTANTS
// ============================================================================

class FellowshipDepartmentConstants {
  static const String deptEducation =
      'dept-apostolic'; // DEPT_EDUCATION (ትምህርትና ሐዋርያዊ አገልግሎት)
  static const String deptMemberCare =
      'dept-membercare'; // DEPT_MEMBER_CARE (አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ)
  static const String deptChoir =
      'dept-mezmur'; // DEPT_CHOIR (መዝሙር ክፍል) - Dedicated Choir & Hymnography
  static const String deptSacredArts = 'dept-arts'; // DEPT_SACRED_ARTS (ስነ ጥበባት ክፍል) - Dedicated Christian Arts & Literature
  static const String deptChoirArts =
      'dept-music'; // Legacy combined identifier for migration review
  static const String deptDevelopment =
      'dept-development'; // DEPT_DEVELOPMENT (ልማትና ገቢ አሰባሰብ)
  static const String deptFinanceProperty =
      'dept-accounting'; // DEPT_FINANCE_PROPERTY (ሒሳብና ንብረት)
  static const String deptBatchPrograms =
      'dept-programs'; // DEPT_BATCH_PROGRAMS (ባችና መርሐ ግብራት ማስተባበሪያ)
  static const String deptCharity =
      'dept-charity'; // DEPT_CHARITY (ሙያና በጎ አድራጎት)
  static const String deptSpecialNeeds =
      'dept-language'; // DEPT_SPECIAL_NEEDS (ቋንቋና ልዩ ልዩ ፍላጎት)
  static const String deptPlanning =
      'dept-planning'; // DEPT_PLANNING (እቅድና ክትትል)
  static const String deptAudit =
      'dept-audit'; // DEPT_AUDIT (ኦዲትና ኢንስፔክሽን - Read Only)

  /// The 11 specific coordinator scopes selectable by admins
  static const List<String> coordinatorScopeIds = [
    deptEducation,
    deptMemberCare,
    deptChoir,
    deptSacredArts,
    deptDevelopment,
    deptFinanceProperty,
    deptBatchPrograms,
    deptCharity,
    deptSpecialNeeds,
    deptPlanning,
    deptAudit,
  ];

  /// Active fellowship departments across the application
  static const List<String> allDepartmentIds = [
    deptEducation,
    deptMemberCare,
    deptChoir,
    deptSacredArts,
    deptDevelopment,
    deptFinanceProperty,
    deptBatchPrograms,
    deptCharity,
    deptSpecialNeeds,
    deptPlanning,
    deptAudit,
  ];

  static const Map<String, String> amharicNames = {
    deptEducation: 'ትምህርትና ሐዋርያዊ አገልግሎት',
    deptMemberCare: 'አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ',
    deptChoir: 'መዝሙር ክፍል',
    deptSacredArts: 'ስነ ጥበባት ክፍል',
    deptChoirArts: 'መዝሙርና ስነ ጥበባት (የቀድሞ ጥምር)',
    deptDevelopment: 'ልማትና ገቢ አሰባሰብ',
    deptFinanceProperty: 'ሒሳብና ንብረት',
    deptBatchPrograms: 'ባችና መርሐ ግብራት ማስተባበሪያ',
    deptCharity: 'ሙያና በጎ አድራጎት',
    deptSpecialNeeds: 'ቋንቋና ልዩ ልዩ ፍላጎት',
    deptPlanning: 'እቅድና ክትትል',
    deptAudit: 'ኦዲትና ኢንስፔክሽን',
  };

  static const Map<String, String> englishNames = {
    deptEducation: 'Education & Apostolic Ministry',
    deptMemberCare: 'Member Care, Counseling & Capacity',
    deptChoir: 'Mezmur / Choir',
    deptSacredArts: 'Sacred Arts',
    deptChoirArts: 'Music & Sacred Arts (Legacy Combined)',
    deptDevelopment: 'Development & Fundraising',
    deptFinanceProperty: 'Accounting & Property Management',
    deptBatchPrograms: 'Batch & Programs Coordination',
    deptCharity: 'Vocational & Charitable Activities',
    deptSpecialNeeds: 'Language & Special Needs',
    deptPlanning: 'Planning & Monitoring',
    deptAudit: 'Audit & Inspection',
  };

  static String normalize(String deptIdOrKey) {
    switch (deptIdOrKey.toUpperCase()) {
      case 'DEPT_EDUCATION':
        return deptEducation;
      case 'DEPT_MEMBER_CARE':
        return deptMemberCare;
      case 'DEPT_CHOIR':
      case 'DEPT_MEZMUR':
        return deptChoir;
      case 'DEPT_SACRED_ARTS':
      case 'DEPT_ARTS':
        return deptSacredArts;
      case 'DEPT_CHOIR_ARTS':
        return deptChoirArts;
      case 'DEPT_DEVELOPMENT':
        return deptDevelopment;
      case 'DEPT_FINANCE_PROPERTY':
        return deptFinanceProperty;
      case 'DEPT_BATCH_PROGRAMS':
        return deptBatchPrograms;
      case 'DEPT_CHARITY':
        return deptCharity;
      case 'DEPT_SPECIAL_NEEDS':
        return deptSpecialNeeds;
      case 'DEPT_PLANNING':
        return deptPlanning;
      case 'DEPT_AUDIT':
        return deptAudit;
      default:
        return deptIdOrKey;
    }
  }

  static String normalizeDepartmentId(String deptIdOrKey) =>
      normalize(deptIdOrKey);

  static String getNameAmharic(String deptIdOrKey) {
    final normalized = normalize(deptIdOrKey);
    return amharicNames[normalized] ?? amharicNames[deptIdOrKey] ?? deptIdOrKey;
  }

  static String getNameEn(String deptIdOrKey) {
    final normalized = normalize(deptIdOrKey);
    return englishNames[normalized] ?? englishNames[deptIdOrKey] ?? deptIdOrKey;
  }

  /// Checks if a department ID corresponds to the legacy combined Music & Sacred Arts scope
  static bool isLegacyCombinedMusicScope(String? deptId) {
    if (deptId == null) return false;
    final clean = deptId.trim().toLowerCase();
    return clean == deptChoirArts ||
        clean == 'dept-music' ||
        clean == 'dept_choir_arts';
  }

  /// Checks if a department ID corresponds to the read-only Audit & Inspection scope
  static bool isAuditScope(String? deptId) {
    if (deptId == null) return false;
    final clean = deptId.trim().toLowerCase();
    return clean == deptAudit || clean == 'dept-audit' || clean == 'dept_audit';
  }

  /// Returns clear formatted role string: "Volunteer Coordinator — [Scope]"
  static String formatCoordinatorScope(String? deptId) {
    if (deptId == null || deptId.trim().isEmpty) {
      return 'Volunteer Coordinator — Unassigned Scope';
    }
    if (isLegacyCombinedMusicScope(deptId)) {
      return 'Volunteer Coordinator — Music & Sacred Arts (Legacy Combined)';
    }
    final enName = getNameEn(deptId);
    return 'Volunteer Coordinator — $enName';
  }
}

class CoordinatorProfileModel {
  final String departmentId; // e.g. 'dept-music'
  final String departmentTitle;
  final String departmentTitleAmharic;
  final String departmentNameEn;
  final String departmentNameAmharic;
  final String coordinatorTitle;
  final DateTime? appointedDate;
  final bool canApproveApplicants;
  final bool canManageRoster;
  final bool canPublishAnnouncements;
  final bool isReadOnlyAudit; // true for DEPT_AUDIT (ኦዲትና ኢንስፔክሽን)

  const CoordinatorProfileModel({
    required this.departmentId,
    String? departmentTitle,
    String? departmentTitleAmharic,
    String? departmentNameEn,
    String? departmentNameAmharic,
    this.coordinatorTitle = 'Department Coordinator',
    this.appointedDate,
    this.canApproveApplicants = true,
    this.canManageRoster = true,
    this.canPublishAnnouncements = true,
    this.isReadOnlyAudit = false,
  }) : departmentTitle = departmentTitle ?? departmentNameEn ?? '',
       departmentTitleAmharic =
           departmentTitleAmharic ?? departmentNameAmharic ?? '',
       departmentNameEn = departmentNameEn ?? departmentTitle ?? '',
       departmentNameAmharic =
           departmentNameAmharic ?? departmentTitleAmharic ?? '';

  CoordinatorProfileModel copyWith({
    String? departmentId,
    String? departmentTitle,
    String? departmentTitleAmharic,
    String? departmentNameEn,
    String? departmentNameAmharic,
    String? coordinatorTitle,
    DateTime? appointedDate,
    bool? canApproveApplicants,
    bool? canManageRoster,
    bool? canPublishAnnouncements,
    bool? isReadOnlyAudit,
  }) {
    return CoordinatorProfileModel(
      departmentId: departmentId ?? this.departmentId,
      departmentTitle: departmentTitle ?? this.departmentTitle,
      departmentTitleAmharic:
          departmentTitleAmharic ?? this.departmentTitleAmharic,
      departmentNameEn: departmentNameEn ?? this.departmentNameEn,
      departmentNameAmharic:
          departmentNameAmharic ?? this.departmentNameAmharic,
      coordinatorTitle: coordinatorTitle ?? this.coordinatorTitle,
      appointedDate: appointedDate ?? this.appointedDate,
      canApproveApplicants: canApproveApplicants ?? this.canApproveApplicants,
      canManageRoster: canManageRoster ?? this.canManageRoster,
      canPublishAnnouncements:
          canPublishAnnouncements ?? this.canPublishAnnouncements,
      isReadOnlyAudit: isReadOnlyAudit ?? this.isReadOnlyAudit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'departmentTitle': departmentTitle,
      'departmentTitleAmharic': departmentTitleAmharic,
      'departmentNameEn': departmentNameEn,
      'departmentNameAmharic': departmentNameAmharic,
      'coordinatorTitle': coordinatorTitle,
      'appointedDate': appointedDate?.toIso8601String(),
      'canApproveApplicants': canApproveApplicants,
      'canManageRoster': canManageRoster,
      'canPublishAnnouncements': canPublishAnnouncements,
      'isReadOnlyAudit': isReadOnlyAudit,
    };
  }

  factory CoordinatorProfileModel.fromMap(Map<String, dynamic> map) {
    return CoordinatorProfileModel(
      departmentId: map['departmentId'] ?? '',
      departmentTitle: map['departmentTitle'] ?? map['departmentNameEn'],
      departmentTitleAmharic:
          map['departmentTitleAmharic'] ?? map['departmentNameAmharic'],
      departmentNameEn: map['departmentNameEn'] ?? map['departmentTitle'],
      departmentNameAmharic:
          map['departmentNameAmharic'] ?? map['departmentTitleAmharic'],
      coordinatorTitle: map['coordinatorTitle'] ?? 'Department Coordinator',
      appointedDate: map['appointedDate'] is Timestamp
          ? (map['appointedDate'] as Timestamp).toDate()
          : map['appointedDate'] is String
          ? DateTime.tryParse(map['appointedDate'] as String)
          : null,
      canApproveApplicants: map['canApproveApplicants'] ?? true,
      canManageRoster: map['canManageRoster'] ?? true,
      canPublishAnnouncements: map['canPublishAnnouncements'] ?? true,
      isReadOnlyAudit: map['isReadOnlyAudit'] ?? false,
    );
  }
}

class AppAdminConstants {
  static const String adminEmail = 'natisita928@gmail.com';

  static const List<String> authorizedAdminEmails = [
    'natisita928@gmail.com',
    'natnaeltedla25@gmail.com',
    'alamrew0955958544@gmail.com',
    'admin@wcu.edu.et',
    'admin@wcuorthodox.org',
    'admin@gmail.com',
    'wcuorthodox@gmail.com',
  ];

  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return false;
    return clean == adminEmail || authorizedAdminEmails.contains(clean);
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
  final String
  ministryStatus; // e.g. "Choir Member", "Hospitality Volunteer", "None"
  final String? assignedFamilyId;
  final String? avatarUrl;
  final double attendancePercentage;
  final bool hasAttendanceData;
  final CoordinatorProfileModel? coordinatorProfile;
  final String gender; // 'male' or 'female'
  final String? email;

  UserModel({
    required this.id,
    required this.fullName,
    required this.baptismalName,
    required this.phoneNumber,
    required this.batchYear,
    required this.department,
    required this.academicYear,
    this.role = UserRole.student,
    this.isApproved = false,
    this.badges = const [],
    this.ministryStatus = 'General Fellow',
    this.assignedFamilyId,
    this.avatarUrl,
    double? attendancePercentage,
    bool? hasAttendanceData,
    this.coordinatorProfile,
    this.gender = 'male',
    this.email,
  }) : attendancePercentage = attendancePercentage ?? 0.0,
       hasAttendanceData = hasAttendanceData ?? attendancePercentage != null;

  bool get isMale => gender.toLowerCase() == 'male';
  bool get isFemale => gender.toLowerCase() == 'female';

  static String inferGender(String fullName, [String? baptismalName]) {
    final lowerName = fullName.toLowerCase().trim();
    final lowerBap = (baptismalName ?? '').toLowerCase().trim();

    // Check male baptismal prefixes first (accurate in Ethiopian Orthodox tradition: Gebre Maryam, Wolde Maryam, etc.)
    if (lowerBap.contains('gebre') ||
        lowerBap.contains('ገብረ') ||
        lowerBap.contains('haile') ||
        lowerBap.contains('ኃይለ') ||
        lowerBap.contains('habte') ||
        lowerBap.contains('ሀብተ') ||
        lowerBap.contains('tekle') ||
        lowerBap.contains('ተክለ') ||
        lowerBap.contains('wolde') ||
        lowerBap.contains('ወልደ') ||
        lowerBap.contains('kidan') ||
        lowerBap.contains('ኪዳነ')) {
      if (!lowerBap.contains('wolete') && !lowerBap.contains('ወለተ')) {
        return 'male';
      }
    }

    // Check female baptismal clues
    if (lowerBap.contains('walata') ||
        lowerBap.contains('wolete') ||
        lowerBap.contains('ወለተ') ||
        lowerBap.contains('amata') ||
        lowerBap.contains('አመተ') ||
        lowerBap.contains('ehete') ||
        lowerBap.contains('እኅተ') ||
        lowerBap.contains('kristos samra') ||
        lowerBap.contains('ክርስቶስ ሠምራ') ||
        lowerBap.contains('maryam') ||
        lowerBap.contains('ማርያም') ||
        lowerBap.contains('fikerte') ||
        lowerBap.contains('ፍቅርተ')) {
      return 'female';
    }

    const femaleNames = {
      'selamawit',
      'martha',
      'lidia',
      'lidya',
      'sara',
      'sarah',
      'rahel',
      'rachel',
      'eden',
      'feven',
      'bethlehem',
      'bethelhem',
      'meron',
      'tsehay',
      'tigist',
      'meseret',
      'helen',
      'senait',
      'almaz',
      'hiwot',
      'tsion',
      'zion',
      'mahlet',
      'genet',
      'lemlem',
      'kalkidan',
      'yeabsera',
      'abigiya',
      'ruth',
      'aster',
      'hirut',
      'sosina',
      'samrawit',
      'hilina',
      'hermela',
      'mekdes',
      'hewan',
      'feker',
      'weynishet',
      'haddas',
      'frehiwot',
      'birtukan',
      'worknesh',
      'yemisrach',
      'hana',
      'hanna',
      'blen',
      'rebecca',
      'rebeka',
      'diana',
      'gelila',
      'ሴላማዊት',
      'ማርታ',
      'ሊዲያ',
      'ሣራ',
      'ሣራህ',
      'ራሔል',
      'ኤደን',
      'ፌቨን',
      'ቤተልሔም',
      'ሜሮን',
      'ፀሐይ',
      'ትዕግሥት',
      'መሠረት',
      'ሄለን',
      'ሠናይት',
      'አልማዝ',
      'ሕይወት',
      'ጽዮን',
      'ማሕሌት',
      'ገነት',
      'ለምለም',
      'ቃልኪዳን',
      'ሩት',
      'አስቴር',
      'ሕሩት',
      'ሶስና',
      'ሳምራዊት',
      'ህሊና',
      'ሔርሜላ',
      'መቅደስ',
      'ሔዋን',
    };

    final firstWord = lowerName.split(RegExp(r'\s+')).first;
    if (femaleNames.contains(firstWord)) {
      return 'female';
    }

    return 'male';
  }

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
    bool? hasAttendanceData,
    CoordinatorProfileModel? coordinatorProfile,
    String? gender,
    String? email,
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
      hasAttendanceData: hasAttendanceData ?? this.hasAttendanceData,
      coordinatorProfile: coordinatorProfile ?? this.coordinatorProfile,
      gender: gender ?? this.gender,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'baptismalName': baptismalName,
      'phoneNumber': phoneNumber,
      'batchYear': batchYear,
      'department': department,
      'academicYear': academicYear,
      'role': role.name,
      'isApproved': isApproved,
      'badges': badges,
      'ministryStatus': ministryStatus,
      'assignedFamilyId': assignedFamilyId,
      'avatarUrl': avatarUrl,
      if (hasAttendanceData) 'attendancePercentage': attendancePercentage,
      'coordinatorProfile': coordinatorProfile?.toMap(),
      'gender': gender,
      'email': email,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    final roleStr = map['role']?.toString().trim() ?? 'student';
    UserRole role = UserRole.student;
    for (final r in UserRole.values) {
      if (r.name.toLowerCase() == roleStr.toLowerCase()) {
        role = r;
        break;
      }
    }

    final rawName = map['fullName'] ?? map['name'];
    final nameStr = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : 'Student Fellow';
    final bapStr = map['baptismalName']?.toString() ?? '';
    final parsedGender = map['gender']?.toString().toLowerCase().trim();
    final finalGender = (parsedGender == 'male' || parsedGender == 'female')
        ? parsedGender!
        : inferGender(nameStr, bapStr);

    final bool isApproved = (map['isApproved'] is bool && (map['isApproved'] as bool)) ||
        map['isApproved']?.toString().toLowerCase() == 'true' ||
        map['isApproved'] == 1;

    return UserModel(
      id: docId.isNotEmpty ? docId : (map['id']?.toString() ?? ''),
      fullName: nameStr,
      baptismalName: bapStr,
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      batchYear: map['batchYear']?.toString() ?? '2024',
      department: map['department']?.toString() ?? 'General',
      academicYear: (map['academicYear'] as num?)?.toInt() ?? 1,
      role: role,
      isApproved: isApproved,
      badges:
          (map['badges'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      ministryStatus: map['ministryStatus']?.toString() ?? 'General Fellow',
      assignedFamilyId:
          map['assignedFamilyId'] ??
          map['familyId'] ??
          map['family'] ??
          map['assignedFamily'],
      avatarUrl: map['avatarUrl'],
      attendancePercentage: (map['attendancePercentage'] as num?)?.toDouble(),
      hasAttendanceData: map['attendancePercentage'] is num,
      coordinatorProfile: map['coordinatorProfile'] is Map<String, dynamic>
          ? CoordinatorProfileModel.fromMap(map['coordinatorProfile'])
          : null,
      gender: finalGender,
      email: map['email']?.toString(),
    );
  }
}
