part of 'fellowship_state.dart';

/// Feature slice managing Student Mutual Aid, Charity Campaigns, Dues & Disbursements.
class CharityState extends ChangeNotifier {
  final FellowshipState root; CharityState(this.root);
  void refresh() => notifyListeners();
}

mixin CharityStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
  UserModel get _currentUser;
  bool get isAdmin;
  bool get canManageCharityAndAid;
  bool get canVerifyFinances;
  bool get canManageEmergencyAid;

  // ----------------------------------------------------
  // DOMAIN 12: STUDENT MUTUAL AID & CHARITY FUND
  // ----------------------------------------------------
  List<CharityCampaignModel> _charityCampaigns = [];
  List<DuesPaymentModel> _duesPayments = [];
  List<CharityDisbursementModel> _charityDisbursements = [];
  List<EmergencyAidRequestModel> _emergencyAidRequests = [];

  List<CharityCampaignModel> get charityCampaigns => List.unmodifiable(_charityCampaigns);
  List<DuesPaymentModel> get duesPayments => List.unmodifiable(_duesPayments);
  List<CharityDisbursementModel> get charityDisbursements => List.unmodifiable(_charityDisbursements);
  List<EmergencyAidRequestModel> get emergencyAidRequests => List.unmodifiable(_emergencyAidRequests);

  List<EmergencyAidRequestModel> get myEmergencyAidRequests =>
      _emergencyAidRequests.where((r) => r.studentId == _currentUser.id).toList();

  void addCharityCampaign(CharityCampaignModel campaign) {
    if (!canManageCharityAndAid && !isAdmin) return;
    _charityCampaigns.insert(0, campaign);
    notifyListeners();

    try {
      FirebaseFirestore.instance.collection('charity_campaigns').doc(campaign.id).set(
        campaign.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Firestore addCharityCampaign notice: $e');
    }
  }

  void updateCharityCampaign(CharityCampaignModel updatedCampaign) {
    if (!canManageCharityAndAid && !isAdmin) return;
    final idx = _charityCampaigns.indexWhere((c) => c.id == updatedCampaign.id);
    if (idx != -1) {
      _charityCampaigns[idx] = updatedCampaign;
      notifyListeners();

      try {
        FirebaseFirestore.instance.collection('charity_campaigns').doc(updatedCampaign.id).set(
          updatedCampaign.toMap(),
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('Firestore updateCharityCampaign notice: $e');
      }
    }
  }

  void removeCharityCampaign(String campaignId) {
    _charityCampaigns.removeWhere((c) => c.id == campaignId);
    notifyListeners();

    try {
      _firestoreService.deleteCharityCampaign(campaignId);
    } catch (e) {
      debugPrint('Firestore removeCharityCampaign notice: $e');
    }
  }

  void deleteDuesPayment(String paymentId) {
    _duesPayments.removeWhere((d) => d.id == paymentId);
    notifyListeners();

    try {
      _firestoreService.deleteDuesPayment(paymentId);
    } catch (e) {
      debugPrint('Firestore deleteDuesPayment notice: $e');
    }
  }

  void updateDuesPayment(DuesPaymentModel updated) {
    if (!canVerifyFinances && !canManageCharityAndAid && !isAdmin) return;
    final index = _duesPayments.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      _duesPayments[index] = updated;
      notifyListeners();

      try {
        _firestoreService.recordDuesPayment(updated);
      } catch (e) {
        debugPrint('Firestore updateDuesPayment notice: $e');
      }
    }
  }

  void addCharityDisbursement(CharityDisbursementModel disbursement) {
    _charityDisbursements.insert(0, disbursement);
    notifyListeners();

    try {
      _firestoreService.recordCharityDisbursement(disbursement);
    } catch (e) {
      debugPrint('Firestore addCharityDisbursement notice: $e');
    }
  }

  void updateCharityDisbursement(CharityDisbursementModel updated) {
    final index = _charityDisbursements.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      _charityDisbursements[index] = updated;
      notifyListeners();

      try {
        _firestoreService.recordCharityDisbursement(updated);
      } catch (e) {
        debugPrint('Firestore updateCharityDisbursement notice: $e');
      }
    }
  }

  void deleteCharityDisbursement(String disbursementId) {
    _charityDisbursements.removeWhere((d) => d.id == disbursementId);
    notifyListeners();

    try {
      _firestoreService.deleteCharityDisbursement(disbursementId);
    } catch (e) {
      debugPrint('Firestore deleteCharityDisbursement notice: $e');
    }
  }

  void submitDuesPayment({
    required double amount,
    required String purpose,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
  }) {
    final payment = DuesPaymentModel(
      id: 'due-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      amount: amount,
      purpose: purpose,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: 'Pending Verification',
      submittedAt: DateTime.now(),
    );
    _duesPayments.insert(0, payment);
    notifyListeners();

    try {
      _firestoreService.recordDuesPayment(payment);
    } catch (e) {
      debugPrint('Firestore submitDuesPayment notice: $e');
    }
  }

  void verifyDuesPayment(String duesId, bool approve) {
    final index = _duesPayments.indexWhere((d) => d.id == duesId);
    if (index != -1) {
      final d = _duesPayments[index];
      final updated = DuesPaymentModel(
        id: d.id,
        studentId: d.studentId,
        studentName: d.studentName,
        amount: d.amount,
        purpose: d.purpose,
        paymentMethod: d.paymentMethod,
        transactionReference: d.transactionReference,
        status: approve ? 'Verified' : 'Declined',
        submittedAt: d.submittedAt,
      );
      _duesPayments[index] = updated;
      notifyListeners();

      try {
        _firestoreService.recordDuesPayment(updated);
      } catch (e) {
        debugPrint('Firestore verifyDuesPayment notice: $e');
      }
    }
  }

  void donateToCharityCampaign(String campaignId, double amount) {
    submitCampaignDonation(
      campaignId: campaignId,
      amount: amount,
      paymentMethod: PaymentMethodType.telebirr,
      transactionReference: 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  Future<void> submitCampaignDonation({
    required String campaignId,
    required double amount,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
    String? donorName,
  }) async {
    final campIndex = _charityCampaigns.indexWhere((c) => c.id == campaignId);
    final campTitle = campIndex != -1 ? _charityCampaigns[campIndex].title : 'Charity Campaign';
    final name = (donorName != null && donorName.trim().isNotEmpty) ? donorName.trim() : _currentUser.fullName;

    // 1. Record Dues/Donation payment in treasury ledger
    final payment = DuesPaymentModel(
      id: 'due-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: name,
      amount: amount,
      purpose: 'Donation: $campTitle',
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: 'Verified',
      submittedAt: DateTime.now(),
    );
    _duesPayments.insert(0, payment);

    // 2. Update campaign raised amount and donor count
    if (campIndex != -1) {
      final camp = _charityCampaigns[campIndex];
      _charityCampaigns[campIndex] = CharityCampaignModel(
        id: camp.id,
        title: camp.title,
        description: camp.description,
        targetAmount: camp.targetAmount,
        raisedAmount: camp.raisedAmount + amount,
        donorsCount: camp.donorsCount + 1,
        deadline: camp.deadline,
        isEmergency: camp.isEmergency,
        category: camp.category,
      );
    }
    notifyListeners();

    try {
      await _firestoreService.recordDuesPayment(payment);
      if (campIndex != -1) {
        await _firestoreService.upsertCharityCampaign(_charityCampaigns[campIndex]);
      }
    } catch (e) {
      debugPrint('Firestore submitCampaignDonation notice: $e');
    }
  }

  void submitEmergencyAidRequest({
    required EmergencyAidCategory category,
    required String description,
    required double amountRequested,
  }) {
    final req = EmergencyAidRequestModel(
      id: 'aid-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentPhone: _currentUser.phoneNumber,
      department: _currentUser.department,
      academicYear: _currentUser.academicYear,
      category: category,
      description: description,
      amountRequested: amountRequested,
      status: EmergencyAidStatus.underReview,
      submittedAt: DateTime.now(),
    );
    _emergencyAidRequests.insert(0, req);
    notifyListeners();

    try {
      _firestoreService.submitAidRequest(req);
    } catch (e) {
      debugPrint('Firestore submitEmergencyAidRequest notice: $e');
    }
  }

  void updateAidRequestStatus(String reqId, EmergencyAidStatus status, {String? adminNote}) {
    if (!canManageEmergencyAid && !canVerifyFinances && !isAdmin) return;
    final index = _emergencyAidRequests.indexWhere((r) => r.id == reqId);
    if (index != -1) {
      final updated = _emergencyAidRequests[index].copyWith(
        status: status,
        adminNote: adminNote,
      );
      _emergencyAidRequests[index] = updated;
      notifyListeners();

      try {
        _firestoreService.updateAidRequestStatus(reqId, status.name, adminNote: adminNote);
      } catch (e) {
        debugPrint('Firestore updateAidRequestStatus notice: $e');
      }
    }
  }

  Future<void> disburseEmergencyAid({
    required String requestId,
    required double amount,
    required String paymentMethod,
    required String voucherReference,
    String? note,
  }) async {
    if (!canManageEmergencyAid && !canVerifyFinances && !isAdmin) return;
    final index = _emergencyAidRequests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    final req = _emergencyAidRequests[index];

    // 1. Update Aid Request status
    final updatedReq = req.copyWith(
      status: EmergencyAidStatus.disbursed,
      adminNote: note ?? 'Disbursed $amount ETB via $paymentMethod (Voucher: $voucherReference)',
    );
    _emergencyAidRequests[index] = updatedReq;

    // 2. Create Charity Disbursement voucher record in treasury
    final disbursement = CharityDisbursementModel(
      id: 'disb-${DateTime.now().millisecondsSinceEpoch}',
      beneficiaryName: '${req.studentName} (${req.studentBaptismalName}) • ${req.studentPhone}',
      assistanceType: req.category.displayName,
      amount: amount,
      voucherReference: voucherReference,
      approvedBy: _currentUser.fullName.isNotEmpty ? _currentUser.fullName : 'Treasury Officer',
      disbursedAt: DateTime.now(),
      notes: note ?? 'Disbursed for emergency assistance',
    );
    _charityDisbursements.insert(0, disbursement);
    notifyListeners();

    // 3. Persist to Firestore
    try {
      await _firestoreService.updateAidRequestStatus(requestId, 'disbursed', adminNote: updatedReq.adminNote);
      await _firestoreService.recordCharityDisbursement(disbursement);
    } catch (e) {
      debugPrint('Firestore disburseEmergencyAid notice: $e');
    }
  }

  void verifyEmergencyAid(String reqId, EmergencyAidStatus status, {String? adminNote}) {
    updateAidRequestStatus(reqId, status, adminNote: adminNote);
  }

}

