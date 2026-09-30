import 'user_models.dart';


enum ProposalStatus { pending, approved, rejected }

class FundraisingProposalModel {
  final String id;
  final String title;
  final String objective;
  final double targetAmount;
  final double expectedExpenses;
  final String proposedStrategy;
  final String targetAudience;
  final String category; // e.g. 'Bazaar & Exhibition', 'Alumni Pledge', 'Sacred Artifacts', 'Student Emergency', 'Special Project'
  final String timelineOrDuration; // e.g. '1 Month (Meskerem 15 - Tikimt 15)'
  final String submittedByName;
  final String submittedByDept;
  final DateTime submittedAt;
  final ProposalStatus status;
  final String? adminReviewNotes;
  final DateTime? reviewedAt;

  const FundraisingProposalModel({
    required this.id,
    required this.title,
    required this.objective,
    required this.targetAmount,
    this.expectedExpenses = 0.0,
    required this.proposedStrategy,
    required this.targetAudience,
    this.category = 'Bazaar & Exhibition',
    this.timelineOrDuration = '1 Month',
    required this.submittedByName,
    this.submittedByDept = FellowshipDepartmentConstants.deptDevelopment,
    required this.submittedAt,
    this.status = ProposalStatus.pending,
    this.adminReviewNotes,
    this.reviewedAt,
  });

  bool get isPending => status == ProposalStatus.pending;
  bool get isApproved => status == ProposalStatus.approved;
  bool get isRejected => status == ProposalStatus.rejected;
  double get netExpectedProceeds => targetAmount - expectedExpenses;

  FundraisingProposalModel copyWith({
    String? id,
    String? title,
    String? objective,
    double? targetAmount,
    double? expectedExpenses,
    String? proposedStrategy,
    String? targetAudience,
    String? category,
    String? timelineOrDuration,
    String? submittedByName,
    String? submittedByDept,
    DateTime? submittedAt,
    ProposalStatus? status,
    String? adminReviewNotes,
    DateTime? reviewedAt,
  }) {
    return FundraisingProposalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      targetAmount: targetAmount ?? this.targetAmount,
      expectedExpenses: expectedExpenses ?? this.expectedExpenses,
      proposedStrategy: proposedStrategy ?? this.proposedStrategy,
      targetAudience: targetAudience ?? this.targetAudience,
      category: category ?? this.category,
      timelineOrDuration: timelineOrDuration ?? this.timelineOrDuration,
      submittedByName: submittedByName ?? this.submittedByName,
      submittedByDept: submittedByDept ?? this.submittedByDept,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      adminReviewNotes: adminReviewNotes ?? this.adminReviewNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'objective': objective,
      'targetAmount': targetAmount,
      'expectedExpenses': expectedExpenses,
      'proposedStrategy': proposedStrategy,
      'targetAudience': targetAudience,
      'category': category,
      'timelineOrDuration': timelineOrDuration,
      'submittedByName': submittedByName,
      'submittedByDept': submittedByDept,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status.name,
      'adminReviewNotes': adminReviewNotes,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  factory FundraisingProposalModel.fromMap(Map<String, dynamic> map, String docId) {
    final statusName = map['status']?.toString() ?? 'pending';
    final status = ProposalStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => ProposalStatus.pending,
    );
    return FundraisingProposalModel(
      id: docId,
      title: map['title'] ?? '',
      objective: map['objective'] ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      expectedExpenses: (map['expectedExpenses'] as num?)?.toDouble() ?? 0.0,
      proposedStrategy: map['proposedStrategy'] ?? '',
      targetAudience: map['targetAudience'] ?? '',
      category: map['category'] ?? 'Bazaar & Exhibition',
      timelineOrDuration: map['timelineOrDuration'] ?? '1 Month',
      submittedByName: map['submittedByName'] ?? '',
      submittedByDept: map['submittedByDept'] ?? FellowshipDepartmentConstants.deptDevelopment,
      submittedAt: map['submittedAt'] != null ? DateTime.tryParse(map['submittedAt']) ?? DateTime.now() : DateTime.now(),
      status: status,
      adminReviewNotes: map['adminReviewNotes'],
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt']) : null,
    );
  }
}

// ============================================================================
// 1. ETHIOPIAN LITURGICAL CALENDAR & FASTING MODELS
// ============================================================================
