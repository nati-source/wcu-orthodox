import 'package:flutter/material.dart';


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

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'clericalTitle': clericalTitle,
      'churchName': churchName,
      'meetingVenue': meetingVenue,
      'phoneNumber': phoneNumber,
      'availableDays': availableDays,
      'availableTimeSlots': availableTimeSlots,
      'bio': bio,
      'avatarUrl': avatarUrl,
    };
  }

  factory ConfessorFatherModel.fromMap(Map<String, dynamic> map, String docId) {
    return ConfessorFatherModel(
      id: docId,
      fullName: map['fullName'] ?? '',
      clericalTitle: map['clericalTitle'] ?? 'ቄስ',
      churchName: map['churchName'] ?? 'WCU Orthodox Church',
      meetingVenue: map['meetingVenue'] ?? "St. Mary's Sunday School Office (Room 2)",
      phoneNumber: map['phoneNumber'] ?? '',
      availableDays: (map['availableDays'] as List?)?.map((e) => e.toString()).toList() ?? ["Saturday", "Sunday"],
      availableTimeSlots: (map['availableTimeSlots'] as List?)?.map((e) => e.toString()).toList() ?? ["3:00 PM - 5:00 PM"],
      bio: map['bio'] ?? '',
      avatarUrl: map['avatarUrl'],
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

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentBaptismalName': studentBaptismalName,
      'studentPhone': studentPhone,
      'fatherId': fatherId,
      'fatherName': fatherName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'timeSlot': timeSlot,
      'topic': topic,
      'status': status.name,
      'notes': notes,
    };
  }

  factory ConfessionAppointmentModel.fromMap(Map<String, dynamic> map, String docId) {
    final statusName = map['status']?.toString() ?? 'pending';
    final status = ConfessionAppointmentStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => ConfessionAppointmentStatus.pending,
    );
    return ConfessionAppointmentModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentBaptismalName: map['studentBaptismalName'] ?? '',
      studentPhone: map['studentPhone'] ?? '',
      fatherId: map['fatherId'] ?? '',
      fatherName: map['fatherName'] ?? '',
      scheduledDate: map['scheduledDate'] != null ? DateTime.tryParse(map['scheduledDate']) ?? DateTime.now() : DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      topic: map['topic'] ?? 'General Confession',
      status: status,
      notes: map['notes'],
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

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'category': category,
      'askedAt': askedAt.toIso8601String(),
      'isAnswered': isAnswered,
      'answerText': answerText,
      'answeredBy': answeredBy,
      'isPublic': isPublic,
    };
  }

  factory AnonymousSpiritualQuestionModel.fromMap(Map<String, dynamic> map, String docId) {
    return AnonymousSpiritualQuestionModel(
      id: docId,
      questionText: map['questionText'] ?? '',
      category: map['category'] ?? 'Theology & Dogma',
      askedAt: map['askedAt'] != null ? DateTime.tryParse(map['askedAt']) ?? DateTime.now() : DateTime.now(),
      isAnswered: map['isAnswered'] ?? false,
      answerText: map['answerText'],
      answeredBy: map['answeredBy'],
      isPublic: map['isPublic'] ?? true,
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
