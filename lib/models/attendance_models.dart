
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
