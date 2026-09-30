part of 'fellowship_state.dart';

/// Feature slice managing Pilgrimage Trips, Bus Seat Bookings, QR Boarding & Payment Verification.
class PilgrimageState extends ChangeNotifier {
  final FellowshipState root; PilgrimageState(this.root);
  void refresh() => notifyListeners();
}

mixin PilgrimageStateMixin on ChangeNotifier {
  FirestoreService get _firestoreService;
  UserModel get _currentUser;
  bool get isAdmin;
  bool get canManagePilgrimages;
  bool get canVerifyFinances;

  // ----------------------------------------------------
  // DOMAIN 11: PILGRIMAGE & MONASTERY TRIP COORDINATOR
  // ----------------------------------------------------
  List<PilgrimageTripModel> _pilgrimageTrips = [];
  List<TripRegistrationModel> _tripRegistrations = [];

  List<PilgrimageTripModel> get pilgrimageTrips => List.unmodifiable(_pilgrimageTrips);
  List<TripRegistrationModel> get allTripRegistrations => List.unmodifiable(_tripRegistrations);

  List<TripRegistrationModel> get myTripRegistrations =>
      _tripRegistrations.where((r) => r.studentId == _currentUser.id).toList();

  Future<void> registerForTrip({
    required String tripId,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
  }) async {
    PilgrimageTripModel trip;
    try {
      trip = _pilgrimageTrips.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return;
    }

    final reg = TripRegistrationModel(
      id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
      tripId: trip.id,
      tripTitle: trip.title,
      studentId: _currentUser.id,
      studentName: _currentUser.fullName,
      studentBaptismalName: _currentUser.baptismalName,
      studentPhone: _currentUser.phoneNumber,
      department: _currentUser.department,
      academicYear: _currentUser.academicYear,
      busNumber: (trip.bookedSeats ~/ 45) + 1,
      seatNumber: (trip.bookedSeats % 45) + 1,
      feeAmount: trip.feeAmount,
      isFree: trip.isFree,
      paymentMethod: paymentMethod,
      transactionReference: transactionReference,
      paymentStatus: trip.isFree ? TripPaymentStatus.free : TripPaymentStatus.pendingVerification,
      qrTicketCode: 'PILGRIM-${trip.id.length >= 4 ? trip.id.substring(0, 4).toUpperCase() : 'TRIP'}-${_currentUser.id.length >= 5 ? _currentUser.id.substring(0, 5).toUpperCase() : 'USER'}',
      registeredAt: DateTime.now(),
    );

    _tripRegistrations.insert(0, reg);

    // Update booked seats locally
    final tripIdx = _pilgrimageTrips.indexWhere((t) => t.id == tripId);
    if (tripIdx != -1) {
      _pilgrimageTrips[tripIdx] = _pilgrimageTrips[tripIdx].copyWith(
        bookedSeats: _pilgrimageTrips[tripIdx].bookedSeats + 1,
      );
    }
    notifyListeners();

    // Persist to Cloud Firestore for cross-device real-time sync
    try {
      await _firestoreService.upsertTripRegistration(reg);
      if (tripIdx != -1) {
        await _firestoreService.upsertPilgrimageTrip(_pilgrimageTrips[tripIdx]);
      }
    } catch (e) {
      debugPrint('Firestore trip registration sync error: $e');
    }
  }

  Future<void> addPilgrimageTrip(PilgrimageTripModel trip) async {
    final idx = _pilgrimageTrips.indexWhere((t) => t.id == trip.id);
    if (idx >= 0) {
      _pilgrimageTrips[idx] = trip;
    } else {
      _pilgrimageTrips.insert(0, trip);
    }
    notifyListeners();

    try {
      await _firestoreService.upsertPilgrimageTrip(trip);
    } catch (e) {
      debugPrint('Firestore add pilgrimage trip error: $e');
    }
  }

  Future<void> updatePilgrimageTrip(PilgrimageTripModel updatedTrip) async {
    final idx = _pilgrimageTrips.indexWhere((t) => t.id == updatedTrip.id);
    if (idx != -1) {
      _pilgrimageTrips[idx] = updatedTrip;
      notifyListeners();
    }

    try {
      await _firestoreService.upsertPilgrimageTrip(updatedTrip);
    } catch (e) {
      debugPrint('Firestore update pilgrimage trip error: $e');
    }
  }

  Future<void> removePilgrimageTrip(String tripId) async {
    _pilgrimageTrips.removeWhere((t) => t.id == tripId);
    _tripRegistrations.removeWhere((r) => r.tripId == tripId);
    notifyListeners();

    try {
      await _firestoreService.deletePilgrimageTrip(tripId);
    } catch (e) {
      debugPrint('Firestore remove pilgrimage trip error: $e');
    }
  }

  Future<void> addPilgrimRegistration(TripRegistrationModel reg) async {
    final rIdx = _tripRegistrations.indexWhere((r) => r.id == reg.id);
    if (rIdx >= 0) {
      _tripRegistrations[rIdx] = reg;
    } else {
      _tripRegistrations.insert(0, reg);
    }
    final tripIdx = _pilgrimageTrips.indexWhere((t) => t.id == reg.tripId);
    if (tripIdx != -1) {
      _pilgrimageTrips[tripIdx] = _pilgrimageTrips[tripIdx].copyWith(
        bookedSeats: _pilgrimageTrips[tripIdx].bookedSeats + 1,
      );
    }
    notifyListeners();

    try {
      await _firestoreService.upsertTripRegistration(reg);
      if (tripIdx != -1) {
        await _firestoreService.upsertPilgrimageTrip(_pilgrimageTrips[tripIdx]);
      }
    } catch (e) {
      debugPrint('Firestore addPilgrimRegistration error: $e');
    }
  }

  Future<void> deletePilgrimRegistration(String regId) async {
    final idx = _tripRegistrations.indexWhere((r) => r.id == regId);
    if (idx != -1) {
      final reg = _tripRegistrations.removeAt(idx);
      final tripIdx = _pilgrimageTrips.indexWhere((t) => t.id == reg.tripId);
      if (tripIdx != -1) {
        final currentBooked = _pilgrimageTrips[tripIdx].bookedSeats;
        _pilgrimageTrips[tripIdx] = _pilgrimageTrips[tripIdx].copyWith(
          bookedSeats: currentBooked > 0 ? currentBooked - 1 : 0,
        );
      }
      notifyListeners();

      try {
        await _firestoreService.deleteTripRegistration(regId);
        if (tripIdx != -1) {
          await _firestoreService.upsertPilgrimageTrip(_pilgrimageTrips[tripIdx]);
        }
      } catch (e) {
        debugPrint('Firestore delete pilgrim reg error: $e');
      }
    }
  }

  Future<void> updatePilgrimRegistration(TripRegistrationModel updated) async {
    if (!canManagePilgrimages && !isAdmin) return;
    final index = _tripRegistrations.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _tripRegistrations[index] = updated;
      notifyListeners();
    }

    try {
      await _firestoreService.upsertTripRegistration(updated);
    } catch (e) {
      debugPrint('Firestore update pilgrim reg error: $e');
    }
  }

  void verifyTripPayment(String regId, bool approve) {
    if (!canVerifyFinances && !canManagePilgrimages) return;
    final index = _tripRegistrations.indexWhere((r) => r.id == regId);
    if (index != -1) {
      _tripRegistrations[index] = _tripRegistrations[index].copyWith(
        paymentStatus: approve ? TripPaymentStatus.verified : TripPaymentStatus.rejected,
      );
      notifyListeners();

      // Persist to Cloud Firestore
      try {
        FirebaseFirestore.instance.collection('trip_registrations').doc(regId).update({
          'paymentStatus': approve ? TripPaymentStatus.verified.name : TripPaymentStatus.rejected.name,
        });
      } catch (e) {
        debugPrint('Firestore verify trip payment error: $e');
      }
    }
  }

  bool scanBusBoardingTicket(String qrTicketCode) {
    if (!canManagePilgrimages && !isAdmin) return false;
    final index = _tripRegistrations.indexWhere(
      (r) => r.qrTicketCode.trim().toUpperCase() == qrTicketCode.trim().toUpperCase(),
    );
    if (index != -1) {
      final now = DateTime.now();
      _tripRegistrations[index] = _tripRegistrations[index].copyWith(
        isBoarded: true,
        boardedAt: now,
      );
      notifyListeners();

      // Persist to Cloud Firestore
      try {
        FirebaseFirestore.instance.collection('trip_registrations').doc(_tripRegistrations[index].id).update({
          'isBoarded': true,
          'boardedAt': now.toIso8601String(),
        });
      } catch (e) {
        debugPrint('Firestore scan ticket error: $e');
      }
      return true;
    }
    return false;
  }

  void togglePassengerBoarded(String regId) {
    if (!canManagePilgrimages && !isAdmin) return;
    final index = _tripRegistrations.indexWhere((r) => r.id == regId);
    if (index != -1) {
      final current = _tripRegistrations[index];
      final now = DateTime.now();
      _tripRegistrations[index] = current.copyWith(
        isBoarded: !current.isBoarded,
        boardedAt: !current.isBoarded ? now : null,
      );
      notifyListeners();

      // Persist to Cloud Firestore
      try {
        FirebaseFirestore.instance.collection('trip_registrations').doc(regId).update({
          'isBoarded': !current.isBoarded,
          'boardedAt': !current.isBoarded ? now.toIso8601String() : null,
        });
      } catch (e) {
        debugPrint('Firestore toggle passenger boarded error: $e');
      }
    }
  }

}

