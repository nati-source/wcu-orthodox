import 'package:flutter/material.dart';


enum PaymentMethodType {
  telebirr,
  cbeBirr,
  cbeAccount,
  cash,
  free,
}

extension PaymentMethodTypeExt on PaymentMethodType {
  String get displayName {
    switch (this) {
      case PaymentMethodType.telebirr:
        return 'Telebirr (ቴሌብር)';
      case PaymentMethodType.cbeBirr:
        return 'CBE Birr (ሲቢኢ ብር)';
      case PaymentMethodType.cbeAccount:
        return 'CBE Account Transfer (የንግድ ባንክ ሒሳብ)';
      case PaymentMethodType.cash:
        return 'Cash in Hand (በእጅ ጥሬ ገንዘብ)';
      case PaymentMethodType.free:
        return 'Free / No Fee (ነፃ)';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethodType.telebirr:
        return Icons.phone_android;
      case PaymentMethodType.cbeBirr:
        return Icons.account_balance_wallet;
      case PaymentMethodType.cbeAccount:
        return Icons.account_balance;
      case PaymentMethodType.cash:
        return Icons.payments_outlined;
      case PaymentMethodType.free:
        return Icons.check_circle_outline;
    }
  }
}

enum TripPaymentStatus {
  pendingVerification,
  verified,
  rejected,
  free,
}

extension TripPaymentStatusExt on TripPaymentStatus {
  String get displayName {
    switch (this) {
      case TripPaymentStatus.pendingVerification:
        return 'Pending Verification';
      case TripPaymentStatus.verified:
        return 'Confirmed / Ticket Issued';
      case TripPaymentStatus.rejected:
        return 'Payment Declined';
      case TripPaymentStatus.free:
        return 'Confirmed (Free)';
    }
  }

  Color get color {
    switch (this) {
      case TripPaymentStatus.pendingVerification:
        return const Color(0xFFF59E0B);
      case TripPaymentStatus.verified:
      case TripPaymentStatus.free:
        return const Color(0xFF10B981);
      case TripPaymentStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }
}

class PilgrimageTripModel {
  final String id;
  final String title;
  final String destination;
  final DateTime departureDate;
  final DateTime returnDate;
  final String departurePoint;
  final bool isFree;
  final double feeAmount; // 0.0 if free
  final String telebirrNumber;
  final String telebirrAccountName;
  final String cbeAccountNumber;
  final String cbeAccountName;
  final int totalSeats;
  final int bookedSeats;
  final List<String> itinerary;
  final List<String> packingList;
  final String coordinatorName;
  final String coordinatorPhone;
  final String? bannerAssetPath;

  const PilgrimageTripModel({
    required this.id,
    required this.title,
    required this.destination,
    required this.departureDate,
    required this.returnDate,
    required this.departurePoint,
    this.isFree = false,
    this.feeAmount = 0.0,
    required this.telebirrNumber,
    required this.telebirrAccountName,
    required this.cbeAccountNumber,
    required this.cbeAccountName,
    required this.totalSeats,
    required this.bookedSeats,
    required this.itinerary,
    required this.packingList,
    required this.coordinatorName,
    required this.coordinatorPhone,
    this.bannerAssetPath,
  });

  int get availableSeats => (totalSeats - bookedSeats).clamp(0, totalSeats);

  PilgrimageTripModel copyWith({
    String? id,
    String? title,
    String? destination,
    DateTime? departureDate,
    DateTime? returnDate,
    String? departurePoint,
    bool? isFree,
    double? feeAmount,
    String? telebirrNumber,
    String? telebirrAccountName,
    String? cbeAccountNumber,
    String? cbeAccountName,
    int? totalSeats,
    int? bookedSeats,
    List<String>? itinerary,
    List<String>? packingList,
    String? coordinatorName,
    String? coordinatorPhone,
    String? bannerAssetPath,
  }) {
    return PilgrimageTripModel(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      departurePoint: departurePoint ?? this.departurePoint,
      isFree: isFree ?? this.isFree,
      feeAmount: feeAmount ?? this.feeAmount,
      telebirrNumber: telebirrNumber ?? this.telebirrNumber,
      telebirrAccountName: telebirrAccountName ?? this.telebirrAccountName,
      cbeAccountNumber: cbeAccountNumber ?? this.cbeAccountNumber,
      cbeAccountName: cbeAccountName ?? this.cbeAccountName,
      totalSeats: totalSeats ?? this.totalSeats,
      bookedSeats: bookedSeats ?? this.bookedSeats,
      itinerary: itinerary ?? this.itinerary,
      packingList: packingList ?? this.packingList,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorPhone: coordinatorPhone ?? this.coordinatorPhone,
      bannerAssetPath: bannerAssetPath ?? this.bannerAssetPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'destination': destination,
      'departureDate': departureDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'departurePoint': departurePoint,
      'isFree': isFree,
      'feeAmount': feeAmount,
      'telebirrNumber': telebirrNumber,
      'telebirrAccountName': telebirrAccountName,
      'cbeAccountNumber': cbeAccountNumber,
      'cbeAccountName': cbeAccountName,
      'totalSeats': totalSeats,
      'bookedSeats': bookedSeats,
      'itinerary': itinerary,
      'packingList': packingList,
      'coordinatorName': coordinatorName,
      'coordinatorPhone': coordinatorPhone,
      'bannerAssetPath': bannerAssetPath,
    };
  }

  factory PilgrimageTripModel.fromMap(Map<String, dynamic> map, String docId) {
    return PilgrimageTripModel(
      id: docId,
      title: map['title'] ?? '',
      destination: map['destination'] ?? '',
      departureDate: map['departureDate'] != null ? DateTime.tryParse(map['departureDate']) ?? DateTime.now() : DateTime.now(),
      returnDate: map['returnDate'] != null ? DateTime.tryParse(map['returnDate']) ?? DateTime.now() : DateTime.now(),
      departurePoint: map['departurePoint'] ?? 'WCU Main Gate',
      isFree: map['isFree'] ?? false,
      feeAmount: (map['feeAmount'] as num?)?.toDouble() ?? 0.0,
      telebirrNumber: map['telebirrNumber'] ?? '+251911223344',
      telebirrAccountName: map['telebirrAccountName'] ?? 'WCU Orthodox Fellowship',
      cbeAccountNumber: map['cbeAccountNumber'] ?? '1000293848123',
      cbeAccountName: map['cbeAccountName'] ?? 'WCU Orthodox Student Fellowship',
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 90,
      bookedSeats: (map['bookedSeats'] as num?)?.toInt() ?? 0,
      itinerary: (map['itinerary'] as List?)?.map((e) => e.toString()).toList() ?? [],
      packingList: (map['packingList'] as List?)?.map((e) => e.toString()).toList() ?? [],
      coordinatorName: map['coordinatorName'] ?? 'Coordinator',
      coordinatorPhone: map['coordinatorPhone'] ?? '',
      bannerAssetPath: map['bannerAssetPath'],
    );
  }
}

class TripRegistrationModel {
  final String id;
  final String tripId;
  final String tripTitle;
  final String studentId;
  final String studentName;
  final String studentBaptismalName;
  final String studentPhone;
  final String department;
  final int academicYear;
  final int busNumber;
  final int seatNumber;
  final double feeAmount;
  final bool isFree;
  final PaymentMethodType paymentMethod;
  final String transactionReference;
  final TripPaymentStatus paymentStatus;
  final String qrTicketCode;
  final bool isBoarded;
  final DateTime? boardedAt;
  final DateTime registeredAt;

  TripRegistrationModel({
    required this.id,
    required this.tripId,
    required this.tripTitle,
    required this.studentId,
    required this.studentName,
    required this.studentBaptismalName,
    required this.studentPhone,
    required this.department,
    required this.academicYear,
    required this.busNumber,
    required this.seatNumber,
    required this.feeAmount,
    this.isFree = false,
    required this.paymentMethod,
    required this.transactionReference,
    this.paymentStatus = TripPaymentStatus.pendingVerification,
    required this.qrTicketCode,
    this.isBoarded = false,
    this.boardedAt,
    required this.registeredAt,
  });

  TripRegistrationModel copyWith({
    String? id,
    String? tripId,
    String? tripTitle,
    String? studentId,
    String? studentName,
    String? studentBaptismalName,
    String? studentPhone,
    String? department,
    int? academicYear,
    int? busNumber,
    int? seatNumber,
    double? feeAmount,
    bool? isFree,
    PaymentMethodType? paymentMethod,
    String? transactionReference,
    TripPaymentStatus? paymentStatus,
    String? qrTicketCode,
    bool? isBoarded,
    DateTime? boardedAt,
    DateTime? registeredAt,
  }) {
    return TripRegistrationModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      tripTitle: tripTitle ?? this.tripTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentBaptismalName: studentBaptismalName ?? this.studentBaptismalName,
      studentPhone: studentPhone ?? this.studentPhone,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      busNumber: busNumber ?? this.busNumber,
      seatNumber: seatNumber ?? this.seatNumber,
      feeAmount: feeAmount ?? this.feeAmount,
      isFree: isFree ?? this.isFree,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionReference: transactionReference ?? this.transactionReference,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      qrTicketCode: qrTicketCode ?? this.qrTicketCode,
      isBoarded: isBoarded ?? this.isBoarded,
      boardedAt: boardedAt ?? this.boardedAt,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'tripTitle': tripTitle,
      'studentId': studentId,
      'studentName': studentName,
      'studentBaptismalName': studentBaptismalName,
      'studentPhone': studentPhone,
      'department': department,
      'academicYear': academicYear,
      'busNumber': busNumber,
      'seatNumber': seatNumber,
      'feeAmount': feeAmount,
      'isFree': isFree,
      'paymentMethod': paymentMethod.name,
      'transactionReference': transactionReference,
      'paymentStatus': paymentStatus.name,
      'qrTicketCode': qrTicketCode,
      'isBoarded': isBoarded,
      'boardedAt': boardedAt?.toIso8601String(),
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  factory TripRegistrationModel.fromMap(Map<String, dynamic> map, String docId) {
    final methodStr = map['paymentMethod']?.toString() ?? 'telebirr';
    final method = PaymentMethodType.values.firstWhere(
      (m) => m.name == methodStr,
      orElse: () => PaymentMethodType.telebirr,
    );
    final statusStr = map['paymentStatus']?.toString() ?? 'pendingVerification';
    final status = TripPaymentStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => TripPaymentStatus.pendingVerification,
    );

    return TripRegistrationModel(
      id: docId,
      tripId: map['tripId'] ?? '',
      tripTitle: map['tripTitle'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentBaptismalName: map['studentBaptismalName'] ?? '',
      studentPhone: map['studentPhone'] ?? '',
      department: map['department'] ?? '',
      academicYear: (map['academicYear'] as num?)?.toInt() ?? 1,
      busNumber: (map['busNumber'] as num?)?.toInt() ?? 1,
      seatNumber: (map['seatNumber'] as num?)?.toInt() ?? 1,
      feeAmount: (map['feeAmount'] as num?)?.toDouble() ?? 0.0,
      isFree: map['isFree'] ?? false,
      paymentMethod: method,
      transactionReference: map['transactionReference'] ?? '',
      paymentStatus: status,
      qrTicketCode: map['qrTicketCode'] ?? '',
      isBoarded: map['isBoarded'] ?? false,
      boardedAt: map['boardedAt'] != null ? DateTime.tryParse(map['boardedAt']) : null,
      registeredAt: map['registeredAt'] != null ? DateTime.tryParse(map['registeredAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// ============================================================================
// 5. STUDENT MUTUAL AID & CHARITY FUND MODELS
// ============================================================================
