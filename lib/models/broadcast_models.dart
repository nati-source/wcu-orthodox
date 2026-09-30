
class DepartmentBroadcastMessageModel {
  final String id;
  final String departmentId;
  final String title;
  final String body;
  final String senderName;
  final String senderRole;
  final DateTime sentAt;
  final String urgency; // 'normal', 'urgent', 'meeting'
  final String targetBatch; // 'all', '1', '2', '3', '4', '5'
  final String targetAudienceLabel;
  final String broadcastCategory; // 'courseInfo', 'specialProgram', 'generalNotice', 'urgentAlert'
  final String? courseCode;
  final String? instructorOrSpeaker;
  final String? meetingLocation;
  final DateTime? meetingTime;

  const DepartmentBroadcastMessageModel({
    required this.id,
    required this.departmentId,
    required this.title,
    required this.body,
    required this.senderName,
    required this.senderRole,
    required this.sentAt,
    this.urgency = 'normal',
    this.targetBatch = 'all',
    this.targetAudienceLabel = 'All Students (ሁሉንም ተማሪዎች)',
    this.broadcastCategory = 'generalNotice',
    this.courseCode,
    this.instructorOrSpeaker,
    this.meetingLocation,
    this.meetingTime,
  });

  bool get isSpecialTeacherNotice =>
      broadcastCategory == 'specialProgram' ||
      title.contains('ልዩ የትምህርትና ስብከት') ||
      title.contains('መምህር');

  DepartmentBroadcastMessageModel copyWith({
    String? id,
    String? departmentId,
    String? title,
    String? body,
    String? senderName,
    String? senderRole,
    DateTime? sentAt,
    String? urgency,
    String? targetBatch,
    String? targetAudienceLabel,
    String? broadcastCategory,
    String? courseCode,
    String? instructorOrSpeaker,
    String? meetingLocation,
    DateTime? meetingTime,
  }) {
    return DepartmentBroadcastMessageModel(
      id: id ?? this.id,
      departmentId: departmentId ?? this.departmentId,
      title: title ?? this.title,
      body: body ?? this.body,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      sentAt: sentAt ?? this.sentAt,
      urgency: urgency ?? this.urgency,
      targetBatch: targetBatch ?? this.targetBatch,
      targetAudienceLabel: targetAudienceLabel ?? this.targetAudienceLabel,
      broadcastCategory: broadcastCategory ?? this.broadcastCategory,
      courseCode: courseCode ?? this.courseCode,
      instructorOrSpeaker: instructorOrSpeaker ?? this.instructorOrSpeaker,
      meetingLocation: meetingLocation ?? this.meetingLocation,
      meetingTime: meetingTime ?? this.meetingTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'departmentId': departmentId,
      'title': title,
      'body': body,
      'senderName': senderName,
      'senderRole': senderRole,
      'sentAt': sentAt.toIso8601String(),
      'urgency': urgency,
      'targetBatch': targetBatch,
      'targetAudienceLabel': targetAudienceLabel,
      'broadcastCategory': broadcastCategory,
      'courseCode': courseCode,
      'instructorOrSpeaker': instructorOrSpeaker,
      'meetingLocation': meetingLocation,
      'meetingTime': meetingTime?.toIso8601String(),
    };
  }

  factory DepartmentBroadcastMessageModel.fromMap(Map<String, dynamic> map, String docId) {
    return DepartmentBroadcastMessageModel(
      id: docId,
      departmentId: map['departmentId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'Coordinator',
      sentAt: map['sentAt'] != null ? DateTime.tryParse(map['sentAt']) ?? DateTime.now() : DateTime.now(),
      urgency: map['urgency'] ?? 'normal',
      targetBatch: map['targetBatch']?.toString() ?? 'all',
      targetAudienceLabel: map['targetAudienceLabel'] ?? 'All Students (ሁሉንም ተማሪዎች)',
      broadcastCategory: map['broadcastCategory'] ?? 'generalNotice',
      courseCode: map['courseCode'],
      instructorOrSpeaker: map['instructorOrSpeaker'],
      meetingLocation: map['meetingLocation'],
      meetingTime: map['meetingTime'] != null ? DateTime.tryParse(map['meetingTime']) : null,
    );
  }
}
