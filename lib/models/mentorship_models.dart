
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

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'fullName': fullName,
      'baptismalName': baptismalName,
      'department': department,
      'academicYear': academicYear,
      'specialties': specialties,
      'telegramHandle': telegramHandle,
      'phoneNumber': phoneNumber,
      'activeMenteesCount': activeMenteesCount,
      'maxMentees': maxMentees,
      'isAvailable': isAvailable,
    };
  }

  factory AcademicMentorModel.fromMap(Map<String, dynamic> map, String docId) {
    return AcademicMentorModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      fullName: map['fullName'] ?? '',
      baptismalName: map['baptismalName'] ?? '',
      department: map['department'] ?? '',
      academicYear: (map['academicYear'] as num?)?.toInt() ?? 4,
      specialties: (map['specialties'] as List?)?.map((e) => e.toString()).toList() ?? [],
      telegramHandle: map['telegramHandle'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      activeMenteesCount: (map['activeMenteesCount'] as num?)?.toInt() ?? 0,
      maxMentees: (map['maxMentees'] as num?)?.toInt() ?? 3,
      isAvailable: map['isAvailable'] ?? true,
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

  Map<String, dynamic> toMap() {
    return {
      'juniorStudentId': juniorStudentId,
      'juniorName': juniorName,
      'juniorBaptismalName': juniorBaptismalName,
      'department': department,
      'academicYear': academicYear,
      'mentorId': mentorId,
      'mentorName': mentorName,
      'coursesNeeded': coursesNeeded,
      'status': status.name,
      'requestedAt': requestedAt.toIso8601String(),
    };
  }

  factory MentorshipRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    final statusName = map['status']?.toString() ?? 'pending';
    final status = MentorshipStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => MentorshipStatus.pending,
    );
    return MentorshipRequestModel(
      id: docId,
      juniorStudentId: map['juniorStudentId'] ?? '',
      juniorName: map['juniorName'] ?? '',
      juniorBaptismalName: map['juniorBaptismalName'] ?? '',
      department: map['department'] ?? '',
      academicYear: (map['academicYear'] as num?)?.toInt() ?? 1,
      mentorId: map['mentorId'] ?? '',
      mentorName: map['mentorName'] ?? '',
      coursesNeeded: map['coursesNeeded'] ?? '',
      status: status,
      requestedAt: map['requestedAt'] != null ? DateTime.tryParse(map['requestedAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// ============================================================================
// 7. THEOLOGICAL TRIVIA & WEEKLY FAITH CHALLENGE MODELS
// ============================================================================
