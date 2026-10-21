import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, late, absent }

enum AttendanceCheckInMethod { qr, pin }

class AttendanceEnrollmentSnapshot {
  final String studentId;
  final String department;

  const AttendanceEnrollmentSnapshot({
    required this.studentId,
    required this.department,
  });

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'department': department,
  };

  factory AttendanceEnrollmentSnapshot.fromMap(Map<String, dynamic> map) {
    return AttendanceEnrollmentSnapshot(
      studentId: map['studentId']?.toString() ?? '',
      department: map['department']?.toString() ?? 'General',
    );
  }
}

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'method': method.name,
      'courseName': courseName,
    };
  }

  factory AttendanceRecordModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    AttendanceStatus parsedStatus = AttendanceStatus.present;
    if (map['status'] == 'late') {
      parsedStatus = AttendanceStatus.late;
    } else if (map['status'] == 'absent') {
      parsedStatus = AttendanceStatus.absent;
    }

    AttendanceCheckInMethod parsedMethod = AttendanceCheckInMethod.qr;
    if (map['method'] == 'pin') {
      parsedMethod = AttendanceCheckInMethod.pin;
    }

    DateTime parsedTimestamp = DateTime.now();
    if (map['timestamp'] != null) {
      if (map['timestamp'] is Timestamp) {
        parsedTimestamp = (map['timestamp'] as Timestamp).toDate();
      } else if (map['timestamp'] is String) {
        parsedTimestamp = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
      }
    }

    return AttendanceRecordModel(
      id: docId,
      studentId: map['studentId'] as String? ?? docId,
      studentName: map['studentName'] as String? ?? 'Fellowship Student',
      timestamp: parsedTimestamp,
      status: parsedStatus,
      method: parsedMethod,
      courseName: map['courseName'] as String? ?? '',
    );
  }
}

class AttendanceSessionModel {
  final String sessionId;
  final String courseName;
  final String courseCode;
  final String faculty;
  final String code;
  final String rollingPin;
  final DateTime generatedAt;
  final DateTime? expiresAt;
  final int refreshIntervalSeconds;
  final int totalEnrolled;
  final List<AttendanceEnrollmentSnapshot> enrollmentSnapshot;
  final List<AttendanceRecordModel> scans;
  final bool isActive;
  final bool isExpired;

  AttendanceSessionModel({
    required this.sessionId,
    required this.courseName,
    required this.courseCode,
    required this.faculty,
    required this.code,
    required this.rollingPin,
    required this.generatedAt,
    this.expiresAt,
    this.refreshIntervalSeconds = 30,
    this.totalEnrolled = 0,
    this.enrollmentSnapshot = const [],
    this.scans = const [],
    this.isActive = false,
    this.isExpired = false,
  });

  int get presentCount =>
      scans.where((s) => s.status == AttendanceStatus.present).length;
  int get lateCount =>
      scans.where((s) => s.status == AttendanceStatus.late).length;
  int get absentCount => (totalEnrolled - scans.length).clamp(0, totalEnrolled);

  AttendanceSessionModel copyWith({
    String? sessionId,
    String? courseName,
    String? courseCode,
    String? faculty,
    String? code,
    String? rollingPin,
    DateTime? generatedAt,
    DateTime? expiresAt,
    int? refreshIntervalSeconds,
    int? totalEnrolled,
    List<AttendanceEnrollmentSnapshot>? enrollmentSnapshot,
    List<AttendanceRecordModel>? scans,
    bool? isActive,
    bool? isExpired,
  }) {
    return AttendanceSessionModel(
      sessionId: sessionId ?? this.sessionId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      faculty: faculty ?? this.faculty,
      code: code ?? this.code,
      rollingPin: rollingPin ?? this.rollingPin,
      generatedAt: generatedAt ?? this.generatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshIntervalSeconds:
          refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      totalEnrolled: totalEnrolled ?? this.totalEnrolled,
      enrollmentSnapshot: enrollmentSnapshot ?? this.enrollmentSnapshot,
      scans: scans ?? this.scans,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'courseName': courseName,
      'courseCode': courseCode,
      'faculty': faculty,
      'code': code,
      'rollingPin': rollingPin,
      'generatedAt': generatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'refreshIntervalSeconds': refreshIntervalSeconds,
      'totalEnrolled': totalEnrolled,
      'enrollmentSnapshot': enrollmentSnapshot
          .map((student) => student.toMap())
          .toList(),
      'isActive': isActive,
      'isExpired': isExpired,
    };
  }

  factory AttendanceSessionModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    DateTime parsedGen = DateTime.now();
    if (map['generatedAt'] != null) {
      if (map['generatedAt'] is Timestamp) {
        parsedGen = (map['generatedAt'] as Timestamp).toDate();
      } else if (map['generatedAt'] is String) {
        parsedGen = DateTime.tryParse(map['generatedAt']) ?? DateTime.now();
      }
    }

    DateTime? parsedExp;
    if (map['expiresAt'] != null) {
      if (map['expiresAt'] is Timestamp) {
        parsedExp = (map['expiresAt'] as Timestamp).toDate();
      } else if (map['expiresAt'] is String) {
        parsedExp = DateTime.tryParse(map['expiresAt']);
      }
    }

    return AttendanceSessionModel(
      sessionId: docId,
      courseName:
          map['courseName'] as String? ??
          'Patristics & Church History (የነገረ አበው ትምህርት)',
      courseCode:
          map['courseCode'] as String? ??
          'ORTH-301: Patristics & Church History',
      faculty:
          map['faculty'] as String? ??
          'Orthodox Fellowship Education Department',
      code: map['code'] as String? ?? 'ORTH-301-STANDBY',
      rollingPin: map['rollingPin'] as String? ?? '----',
      generatedAt: parsedGen,
      expiresAt: parsedExp,
      refreshIntervalSeconds:
          (map['refreshIntervalSeconds'] as num?)?.toInt() ?? 30,
      totalEnrolled: (map['totalEnrolled'] as num?)?.toInt() ?? 0,
      enrollmentSnapshot:
          (map['enrollmentSnapshot'] as List?)
              ?.whereType<Map>()
              .map(
                (student) => AttendanceEnrollmentSnapshot.fromMap(
                  Map<String, dynamic>.from(student),
                ),
              )
              .where((student) => student.studentId.isNotEmpty)
              .toList() ??
          const [],
      isActive: map['isActive'] as bool? ?? false,
      isExpired: map['isExpired'] as bool? ?? false,
      scans: const [],
    );
  }
}
