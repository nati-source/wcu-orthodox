part of 'fellowship_state.dart';

/// Feature slice managing Student Mutual Aid, Charity Campaigns, Dues & Disbursements.
class CharityState extends ChangeNotifier {
  final FellowshipState root;
  CharityState(this.root);
  void refresh() => notifyListeners();
}

mixin CharityStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
  UserModel get _currentUser;
  bool get isAdmin;
  bool get canManageCharityAndAid;
  bool get canVerifyFinances;
  bool get canManageEmergencyAid;
  bool get isDemoMode;
  bool get _isLocalOrDemo => isDemoMode || !_firestoreService.isAvailable;

  // ----------------------------------------------------
  // DOMAIN 12: STUDENT MUTUAL AID & CHARITY FUND
  // ----------------------------------------------------
  List<CharityCampaignModel> _charityCampaigns = [];
  List<DuesPaymentModel> _duesPayments = [];
  List<CharityDisbursementModel> _charityDisbursements = [];
  List<EmergencyAidRequestModel> _emergencyAidRequests = [];

  List<CharityCampaignModel> get charityCampaigns =>
      List.unmodifiable(_charityCampaigns);
  List<DuesPaymentModel> get duesPayments => List.unmodifiable(_duesPayments);
  List<CharityDisbursementModel> get charityDisbursements =>
      List.unmodifiable(_charityDisbursements);
  List<EmergencyAidRequestModel> get emergencyAidRequests =>
      List.unmodifiable(_emergencyAidRequests);

  List<EmergencyAidRequestModel> get myEmergencyAidRequests =>
      _emergencyAidRequests
          .where((r) => r.studentId == _currentUser.id)
          .toList();

  Future<void> addCharityCampaign(CharityCampaignModel campaign) async {
    final safeCampaign = _isLocalOrDemo
        ? campaign
        : campaign.copyWith(raisedAmount: 0, donorsCount: 0);
    _charityCampaigns.removeWhere((item) => item.id == campaign.id);
    _charityCampaigns.insert(0, safeCampaign);
    notifyListeners();

    try {
      await _firestoreService.upsertCharityCampaign(campaign);
      debugPrint('Firestore addCharityCampaign success: ${campaign.id}');
    } catch (e) {
      debugPrint('Firestore addCharityCampaign notice: $e');
      if (!_isLocalOrDemo) rethrow;
    }
  }

  Future<void> updateCharityCampaign(
    CharityCampaignModel updatedCampaign,
  ) async {
    final idx = _charityCampaigns.indexWhere(
      (c) => c.id == updatedCampaign.id,
    );
    final preservedRaised = idx == -1
        ? 0.0
        : _charityCampaigns[idx].raisedAmount;
    final preservedDonors = idx == -1
        ? 0
        : _charityCampaigns[idx].donorsCount;
    final safeCampaign = updatedCampaign.copyWith(
      raisedAmount: preservedRaised,
      donorsCount: preservedDonors,
    );
    if (idx == -1) {
      _charityCampaigns.insert(0, safeCampaign);
    } else {
      _charityCampaigns[idx] = safeCampaign;
    }
    notifyListeners();

    try {
      await _firestoreService.upsertCharityCampaign(updatedCampaign);
      debugPrint(
        'Firestore updateCharityCampaign success: ${updatedCampaign.id}',
      );
    } catch (e) {
      debugPrint('Firestore updateCharityCampaign notice: $e');
      if (!_isLocalOrDemo) rethrow;
    }
  }

  Future<void> removeCharityCampaign(String campaignId) async {
    _charityCampaigns.removeWhere((c) => c.id == campaignId);
    notifyListeners();

    try {
      await _firestoreService.deleteCharityCampaign(campaignId);
      debugPrint('Firestore removeCharityCampaign success: $campaignId');
    } catch (e) {
      debugPrint('Firestore removeCharityCampaign notice: $e');
      if (!_isLocalOrDemo) rethrow;
    }
  }

  Future<void> deleteDuesPayment(String paymentId) async {
    _duesPayments.removeWhere((d) => d.id == paymentId);
    notifyListeners();

    try {
      await _firestoreService.deleteDuesPayment(paymentId);
      debugPrint('Firestore deleteDuesPayment success: $paymentId');
    } catch (e) {
      debugPrint('Firestore deleteDuesPayment error: $e');
    }
  }

  Future<void> updateDuesPayment(DuesPaymentModel updated) async {
    final index = _duesPayments.indexWhere((d) => d.id == updated.id);
    if (index != -1) {
      _duesPayments[index] = updated;
      notifyListeners();

      try {
        await _firestoreService.recordDuesPayment(updated);
        debugPrint('Firestore updateDuesPayment success: ${updated.id}');
      } catch (e) {
        debugPrint('Firestore updateDuesPayment error: $e');
      }
    }
  }

  Future<void> addCharityDisbursement(
    CharityDisbursementModel disbursement,
  ) async {
    _charityDisbursements.insert(0, disbursement);
    notifyListeners();

    try {
      final serverId = await _firestoreService.recordCharityDisbursement(
        disbursement,
      );
      final idx = _charityDisbursements.indexWhere((d) => d.id == disbursement.id);
      if (idx != -1) {
        _charityDisbursements[idx] = disbursement.copyWith(id: serverId);
        notifyListeners();
      }
      debugPrint('Firestore addCharityDisbursement success: $serverId');
    } catch (e) {
      debugPrint('Firestore addCharityDisbursement notice: $e');
      if (!_isLocalOrDemo) rethrow;
    }
  }

  Future<void> updateCharityDisbursement(
    CharityDisbursementModel updated,
  ) async {
    if (_isLocalOrDemo) {
      final index = _charityDisbursements.indexWhere((d) => d.id == updated.id);
      if (index != -1) {
        _charityDisbursements[index] = updated;
        notifyListeners();
      }
      return;
    }
    throw StateError('Disbursement records are immutable.');
  }

  Future<void> deleteCharityDisbursement(String disbursementId) async {
    if (_isLocalOrDemo) {
      _charityDisbursements.removeWhere((d) => d.id == disbursementId);
      notifyListeners();
      return;
    }
    throw StateError('Disbursement records are immutable.');
  }

  Future<void> submitDuesPayment({
    required double amount,
    required String purpose,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
  }) async {
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
      await _firestoreService.recordDuesPayment(payment);
      debugPrint('Firestore submitDuesPayment success: ${payment.id}');
    } catch (e) {
      debugPrint('Firestore submitDuesPayment notice: $e');
    }
  }

  Future<void> verifyDuesPayment(String duesId, bool approve) async {
    if (!canVerifyFinances && !isAdmin) return;
    final index = _duesPayments.indexWhere((d) => d.id == duesId);
    if (index == -1) return;
    final payment = _duesPayments[index];
    if (!{
      'Pending',
      'Pending Verification',
      'pendingVerification',
      'pending',
    }.contains(payment.status)) {
      return;
    }

    try {
      await FirebaseCallableService.instance.call('verifyDuesPayment', {
        'duesId': duesId,
        'approve': approve,
      });
      _duesPayments[index] = payment.copyWith(
        status: approve ? 'Verified' : 'Declined',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Trusted dues verification failed: $e');
      if (!_isLocalOrDemo) rethrow;
      _duesPayments[index] = payment.copyWith(
        status: approve ? 'Verified' : 'Declined',
      );
      if (approve && payment.campaignId != null) {
        final cIndex = _charityCampaigns.indexWhere(
          (c) => c.id == payment.campaignId,
        );
        if (cIndex != -1) {
          final c = _charityCampaigns[cIndex];
          _charityCampaigns[cIndex] = c.copyWith(
            raisedAmount: c.raisedAmount + payment.amount,
            donorsCount: c.donorsCount + 1,
          );
        }
      }
      notifyListeners();
    }
  }

  void donateToCharityCampaign(String campaignId, double amount) {
    submitCampaignDonation(
      campaignId: campaignId,
      amount: amount,
      paymentMethod: PaymentMethodType.telebirr,
      transactionReference:
          'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
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
    final campTitle = campIndex != -1
        ? _charityCampaigns[campIndex].title
        : 'Charity Campaign';
    final name = (donorName != null && donorName.trim().isNotEmpty)
        ? donorName.trim()
        : _currentUser.fullName;

    // 1. Record Dues/Donation payment in treasury ledger as Pending verification
    final payment = DuesPaymentModel(
      id: 'due-${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentUser.id,
      studentName: name,
      amount: amount,
      purpose: 'Donation: $campTitle',
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      status: 'Pending',
      submittedAt: DateTime.now(),
      campaignId: campaignId,
    );
    _duesPayments.insert(0, payment);
    notifyListeners();

    try {
      await _firestoreService.recordDuesPayment(payment);
      debugPrint('Firestore submitCampaignDonation success: ${payment.id}');
    } catch (e) {
      _duesPayments.removeWhere((p) => p.id == payment.id);
      notifyListeners();
      debugPrint(
        'Firestore submitCampaignDonation notice, reverted local entry: $e',
      );
    }
  }

  Future<void> submitEmergencyAidRequest({
    required EmergencyAidCategory category,
    required String description,
    required double amountRequested,
  }) async {
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
      await _firestoreService.submitAidRequest(req);
      debugPrint('Firestore submitEmergencyAidRequest success: ${req.id}');
    } catch (e) {
      debugPrint('Firestore submitEmergencyAidRequest notice: $e');
    }
  }

  Future<void> updateAidRequestStatus(
    String reqId,
    EmergencyAidStatus status, {
    String? adminNote,
  }) async {
    if (!canManageEmergencyAid && !isAdmin) return;
    final index = _emergencyAidRequests.indexWhere((r) => r.id == reqId);
    final previous = index == -1 ? null : _emergencyAidRequests[index];
    if (index != -1 && previous != null) {
      _emergencyAidRequests[index] = previous.copyWith(
        status: status,
        adminNote: adminNote,
      );
      notifyListeners();
    }

    try {
      await _firestoreService.updateAidRequestStatus(
        reqId,
        status.name,
        adminNote: adminNote,
      );
      debugPrint('Firestore updateAidRequestStatus success: $reqId');
    } catch (e) {
      debugPrint('Firestore updateAidRequestStatus notice: $e');
      if (!_isLocalOrDemo) {
        if (index != -1 && previous != null) {
          _emergencyAidRequests[index] = previous;
          notifyListeners();
        }
        rethrow;
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
    final req = index == -1 ? null : _emergencyAidRequests[index];
    final localDisbId = 'disb-${DateTime.now().millisecondsSinceEpoch}';
    if (index != -1 && req != null) {
      _emergencyAidRequests[index] = req.copyWith(
        status: EmergencyAidStatus.disbursed,
        adminNote: note ?? 'Emergency aid disbursed.',
      );
      _charityDisbursements.insert(
        0,
        CharityDisbursementModel(
          id: localDisbId,
          beneficiaryName: req.studentName,
          assistanceType: req.category.displayName,
          amount: amount,
          paymentMethod: paymentMethod,
          voucherReference: voucherReference,
          approvedBy: _currentUser.fullName,
          disbursedAt: DateTime.now(),
          notes: note ?? '',
        ),
      );
      notifyListeners();
    }

    try {
      final response = await FirebaseCallableService.instance.call(
        'disburseEmergencyAid',
        {
          'requestId': requestId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'voucherReference': voucherReference,
          'note': note ?? '',
        },
      );
      final serverId = response['disbursementId']?.toString();
      if (serverId != null) {
        final dIdx = _charityDisbursements.indexWhere((d) => d.id == localDisbId);
        if (dIdx != -1) {
          _charityDisbursements[dIdx] = _charityDisbursements[dIdx].copyWith(id: serverId);
          notifyListeners();
        }
      }
      debugPrint('Trusted emergency aid disbursement recorded.');
    } catch (e) {
      debugPrint('Trusted emergency aid disbursement notice: $e');
      if (!_isLocalOrDemo) {
        if (index != -1 && req != null) {
          _emergencyAidRequests[index] = req;
          _charityDisbursements.removeWhere((d) => d.id == localDisbId);
          notifyListeners();
        }
        rethrow;
      }
    }
  }

  void verifyEmergencyAid(
    String reqId,
    EmergencyAidStatus status, {
    String? adminNote,
  }) {
    if (!canManageEmergencyAid && !isAdmin) return;
    updateAidRequestStatus(reqId, status, adminNote: adminNote);
  }
}
