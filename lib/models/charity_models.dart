import 'package:flutter/material.dart';
import 'pilgrimage_models.dart';


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

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'raisedAmount': raisedAmount,
      'donorsCount': donorsCount,
      'deadline': deadline.toIso8601String(),
      'isEmergency': isEmergency,
      'category': category,
    };
  }

  factory CharityCampaignModel.fromMap(Map<String, dynamic> map, String docId) {
    return CharityCampaignModel(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      raisedAmount: (map['raisedAmount'] as num?)?.toDouble() ?? 0.0,
      donorsCount: (map['donorsCount'] as num?)?.toInt() ?? 0,
      deadline: map['deadline'] != null ? DateTime.tryParse(map['deadline']) ?? DateTime.now() : DateTime.now(),
      isEmergency: map['isEmergency'] ?? false,
      category: map['category'] ?? 'Student Mutual Aid',
    );
  }
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

  DuesPaymentModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    double? amount,
    String? purpose,
    PaymentMethodType? paymentMethod,
    String? transactionReference,
    String? status,
    DateTime? submittedAt,
  }) {
    return DuesPaymentModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      amount: amount ?? this.amount,
      purpose: purpose ?? this.purpose,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'amount': amount,
      'purpose': purpose,
      'paymentMethod': paymentMethod.name,
      'transactionReference': transactionReference,
      'status': status,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }

  factory DuesPaymentModel.fromMap(Map<String, dynamic> map, String docId) {
    final methodStr = map['paymentMethod']?.toString() ?? 'telebirr';
    final method = PaymentMethodType.values.firstWhere(
      (m) => m.name == methodStr,
      orElse: () => PaymentMethodType.telebirr,
    );
    return DuesPaymentModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      purpose: map['purpose'] ?? 'Monthly Fellowship Dues',
      paymentMethod: method,
      transactionReference: map['transactionReference'] ?? '',
      status: map['status'] ?? 'Verified',
      submittedAt: map['submittedAt'] != null ? DateTime.tryParse(map['submittedAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class CharityDisbursementModel {
  final String id;
  final String beneficiaryName;
  final String assistanceType; // "Student Cafeteria Meal Support", "Medical & Prescription", "Emergency Transport", "Academic Supplies"
  final double amount;
  final String voucherReference;
  final String approvedBy;
  final DateTime disbursedAt;
  final String notes;

  const CharityDisbursementModel({
    required this.id,
    required this.beneficiaryName,
    required this.assistanceType,
    required this.amount,
    required this.voucherReference,
    required this.approvedBy,
    required this.disbursedAt,
    this.notes = '',
  });

  CharityDisbursementModel copyWith({
    String? id,
    String? beneficiaryName,
    String? assistanceType,
    double? amount,
    String? voucherReference,
    String? approvedBy,
    DateTime? disbursedAt,
    String? notes,
  }) {
    return CharityDisbursementModel(
      id: id ?? this.id,
      beneficiaryName: beneficiaryName ?? this.beneficiaryName,
      assistanceType: assistanceType ?? this.assistanceType,
      amount: amount ?? this.amount,
      voucherReference: voucherReference ?? this.voucherReference,
      approvedBy: approvedBy ?? this.approvedBy,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'beneficiaryName': beneficiaryName,
      'assistanceType': assistanceType,
      'amount': amount,
      'voucherReference': voucherReference,
      'approvedBy': approvedBy,
      'disbursedAt': disbursedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory CharityDisbursementModel.fromMap(Map<String, dynamic> map, String docId) {
    return CharityDisbursementModel(
      id: docId,
      beneficiaryName: map['beneficiaryName'] ?? '',
      assistanceType: map['assistanceType'] ?? 'Student Cafeteria Meal Support',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      voucherReference: map['voucherReference'] ?? '',
      approvedBy: map['approvedBy'] ?? 'Charity Coordinator',
      disbursedAt: map['disbursedAt'] != null ? DateTime.tryParse(map['disbursedAt']) ?? DateTime.now() : DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
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

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentBaptismalName': studentBaptismalName,
      'studentPhone': studentPhone,
      'department': department,
      'academicYear': academicYear,
      'category': category.name,
      'description': description,
      'amountRequested': amountRequested,
      'status': status.name,
      'submittedAt': submittedAt.toIso8601String(),
      'adminNote': adminNote,
    };
  }

  factory EmergencyAidRequestModel.fromMap(Map<String, dynamic> map, String docId) {
    final catName = map['category']?.toString() ?? 'other';
    final cat = EmergencyAidCategory.values.firstWhere(
      (c) => c.name == catName,
      orElse: () => EmergencyAidCategory.other,
    );
    final statusName = map['status']?.toString() ?? 'underReview';
    final status = EmergencyAidStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => EmergencyAidStatus.underReview,
    );

    return EmergencyAidRequestModel(
      id: docId,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentBaptismalName: map['studentBaptismalName'] ?? '',
      studentPhone: map['studentPhone'] ?? '',
      department: map['department'] ?? '',
      academicYear: (map['academicYear'] as num?)?.toInt() ?? 1,
      category: cat,
      description: map['description'] ?? '',
      amountRequested: (map['amountRequested'] as num?)?.toDouble() ?? 0.0,
      status: status,
      submittedAt: map['submittedAt'] != null ? DateTime.tryParse(map['submittedAt']) ?? DateTime.now() : DateTime.now(),
      adminNote: map['adminNote'],
    );
  }
}

// ============================================================================
// 6. DEPARTMENT MENTORSHIP MATCHING MODELS
// ============================================================================
