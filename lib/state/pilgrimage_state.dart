part of 'fellowship_state.dart';

/// Feature slice managing Pilgrimage Trips, Bus Seat Bookings, QR Boarding & Payment Verification.
class PilgrimageState extends ChangeNotifier {
  final FellowshipState root;
  PilgrimageState(this.root);
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
  final Set<String> _myRegisteredTripIds = <String>{};
  final Set<String> _pendingLocalRegIds = <String>{};

  List<PilgrimageTripModel> get pilgrimageTrips =>
      List.unmodifiable(_pilgrimageTrips);
  List<TripRegistrationModel> get allTripRegistrations =>
      List.unmodifiable(_tripRegistrations);

  String get _userScopedRegKey =>
      'my_registered_trip_ids_${_currentUser.id.trim().isNotEmpty ? _currentUser.id.trim() : "anon"}';

  Future<void> _saveTripRegistrationsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _userScopedRegKey,
        _myRegisteredTripIds.toList(),
      );

      // Serialize all registrations to local JSON for offline and zero-latency retrieval
      final List<Map<String, dynamic>> rawList = _tripRegistrations.map((r) {
        final m = r.toMap();
        m['id'] = r.id;
        return m;
      }).toList();
      await prefs.setString(
        'cached_trip_registrations_v3',
        jsonEncode(rawList),
      );
    } catch (e) {
      debugPrint('Error saving trip registrations locally: $e');
    }
  }

  Future<void> _saveMyRegisteredTripIds() async {
    await _saveTripRegistrationsLocally();
  }

  Future<void> _loadMyRegisteredTripIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _myRegisteredTripIds.clear();
      final savedIds = prefs.getStringList(_userScopedRegKey);
      if (savedIds != null && savedIds.isNotEmpty) {
        // Exclude any tripIds that might have been mistakenly stored in legacy cache
        final knownTripIds = _pilgrimageTrips.map((t) => t.id).toSet();
        _myRegisteredTripIds.addAll(
          savedIds.where((id) => !knownTripIds.contains(id)),
        );
      }

      final cachedJson = prefs.getString('cached_trip_registrations_v3');
      if (cachedJson != null && cachedJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson) as List<dynamic>;
          final Map<String, TripRegistrationModel> map = {
            for (final r in _tripRegistrations) r.id: r,
          };
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final id =
                  item['id']?.toString() ??
                  'reg-${DateTime.now().millisecondsSinceEpoch}';
              if (!map.containsKey(id)) {
                map[id] = TripRegistrationModel.fromMap(item, id);
              }
            }
          }
          final list = map.values.toList();
          list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          _tripRegistrations = list;
        } catch (e) {
          debugPrint('Error decoding cached trip registrations: $e');
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading registered trip IDs: $e');
    }
  }

  List<TripRegistrationModel> get myTripRegistrations {
    final curId = _currentUser.id.trim();

    final results = _tripRegistrations.where((r) {
      // 1. Match by registration ID in current user's local registration list
      if (_myRegisteredTripIds.contains(r.id)) return true;

      // 2. Strict match by Firebase UID
      if (curId.isNotEmpty &&
          (r.studentId == curId || r.studentId == _currentUser.id))
        return true;

      return false;
    }).toList();

    results.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    return results;
  }

  Future<void> registerForTrip({
    required String tripId,
    required PaymentMethodType paymentMethod,
    required String transactionReference,
  }) async {
    final studentUid = _currentUser.id.isNotEmpty
        ? _currentUser.id
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    if (studentUid.isEmpty) return;

    PilgrimageTripModel trip;
    try {
      trip = _pilgrimageTrips.firstWhere((t) => t.id == tripId);
    } catch (_) {
      return;
    }

    final existingIndex = _tripRegistrations.indexWhere(
      (r) => r.tripId == tripId && r.studentId == studentUid,
    );
    final existingLocalRegistration = existingIndex < 0
        ? null
        : _tripRegistrations[existingIndex];
    if (existingLocalRegistration != null &&
        existingLocalRegistration.paymentStatus != TripPaymentStatus.rejected)
      return;

    if (trip.bookedSeats >= trip.totalSeats) {
      debugPrint(
        'Registration aborted: trip $tripId is at full capacity (${trip.totalSeats})',
      );
      return;
    }

    // One deterministic record per student and trip prevents parallel taps or
    // retries from reserving two seats.
    final regId = existingLocalRegistration?.id ?? '${trip.id}_$studentUid';
    int allocatedBus = (trip.bookedSeats ~/ 45) + 1;
    int allocatedSeat = (trip.bookedSeats % 45) + 1;
    bool transactionSucceeded = false;
    bool localOnly = false;
    bool existingCloudBooking = false;
    TripRegistrationModel? committedRegistration;
    TripRegistrationModel? existingCloudRegistration;
    final registeredAt = DateTime.now();

    TripRegistrationModel makeRegistration({
      required int bus,
      required int seat,
    }) {
      return TripRegistrationModel(
        id: regId,
        tripId: trip.id,
        tripTitle: trip.title,
        studentId: studentUid,
        studentName: _currentUser.fullName.isNotEmpty
            ? _currentUser.fullName
            : 'Orthodox Pilgrim',
        studentBaptismalName: _currentUser.baptismalName,
        studentPhone: _currentUser.phoneNumber,
        department: _currentUser.department.isNotEmpty
            ? _currentUser.department
            : 'General',
        academicYear: _currentUser.academicYear > 0
            ? _currentUser.academicYear
            : 1,
        busNumber: bus,
        seatNumber: seat,
        feeAmount: trip.feeAmount,
        isFree: trip.isFree,
        paymentMethod: paymentMethod,
        transactionReference: transactionReference,
        paymentStatus: trip.isFree
            ? TripPaymentStatus.free
            : TripPaymentStatus.pendingVerification,
        qrTicketCode:
            'PILGRIM-${trip.id.length >= 4 ? trip.id.substring(0, 4).toUpperCase() : 'TRIP'}-${studentUid.length >= 5 ? studentUid.substring(0, 5).toUpperCase() : 'USER'}',
        registeredAt: registeredAt,
      );
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final tripRef = firestore.collection('pilgrimage_trips').doc(trip.id);
      final regRef = firestore.collection('trip_registrations').doc(regId);

      await firestore.runTransaction((tx) async {
        existingCloudBooking = false;
        existingCloudRegistration = null;
        transactionSucceeded = false;
        committedRegistration = null;
        final regSnap = await tx.get(regRef);
        final tripSnap = await tx.get(tripRef);
        if (regSnap.exists && regSnap.data() != null) {
          existingCloudBooking = true;
          final existing = TripRegistrationModel.fromMap(
            regSnap.data()!,
            regSnap.id,
          );
          if (existing.paymentStatus == TripPaymentStatus.rejected) {
            existingCloudRegistration = existing.copyWith(
              paymentMethod: paymentMethod,
              transactionReference: transactionReference,
              paymentStatus: trip.isFree
                  ? TripPaymentStatus.free
                  : TripPaymentStatus.pendingVerification,
              rejectionReason: null,
              registeredAt: registeredAt,
            );
            tx.update(regRef, {
              'paymentMethod': paymentMethod.name,
              'transactionReference': transactionReference,
              'paymentStatus': trip.isFree
                  ? TripPaymentStatus.free.name
                  : TripPaymentStatus.pendingVerification.name,
              'rejectionReason': null,
              'registeredAt': registeredAt.toIso8601String(),
            });
            transactionSucceeded = true;
          }
          return;
        }
        if (!tripSnap.exists || tripSnap.data() == null) {
          throw Exception('Trip no longer exists');
        }
        int currentBooked = trip.bookedSeats;
        int totalCap = trip.totalSeats;
        final data = tripSnap.data()!;
        currentBooked = (data['bookedSeats'] as num?)?.toInt() ?? currentBooked;
        totalCap = (data['totalSeats'] as num?)?.toInt() ?? totalCap;

        if (totalCap <= 0 || currentBooked < 0 || currentBooked >= totalCap) {
          throw Exception('Trip is at full capacity');
        }

        allocatedBus = (currentBooked ~/ 45) + 1;
        allocatedSeat = (currentBooked % 45) + 1;

        committedRegistration = makeRegistration(
          bus: allocatedBus,
          seat: allocatedSeat,
        );

        tx.set(regRef, committedRegistration!.toMap());
        tx.update(tripRef, {'bookedSeats': currentBooked + 1});
      });
      transactionSucceeded = true;
    } catch (e) {
      debugPrint('Pilgrimage seat atomic transaction notice: $e');
      final lowerMessage = e.toString().toLowerCase();
      if (lowerMessage.contains('full capacity') ||
          lowerMessage.contains('trip no longer exists')) {
        return;
      }
      // A local-only model is supported for widget/demo environments where
      // Firebase has not been initialized. Network/rules failures must never
      // create a local phantom booking or a second non-atomic Firestore write.
      localOnly =
          lowerMessage.contains('no-app') ||
          lowerMessage.contains('not initialized');
      if (!localOnly) return;
    }

    if (localOnly && existingLocalRegistration != null) {
      final updated = existingLocalRegistration.copyWith(
        paymentMethod: paymentMethod,
        transactionReference: transactionReference,
        paymentStatus: trip.isFree
            ? TripPaymentStatus.free
            : TripPaymentStatus.pendingVerification,
        rejectionReason: null,
        registeredAt: registeredAt,
      );
      final index = _tripRegistrations.indexWhere(
        (registration) => registration.id == updated.id,
      );
      if (index >= 0) _tripRegistrations[index] = updated;
      _myRegisteredTripIds.add(updated.id);
      _pendingLocalRegIds.add(updated.id);
      await _saveTripRegistrationsLocally();
      notifyListeners();
      return;
    }

    if (existingCloudBooking) {
      if (existingCloudRegistration == null) return;
      final existing = existingCloudRegistration!;
      final index = _tripRegistrations.indexWhere(
        (registration) => registration.id == existing.id,
      );
      if (index >= 0) {
        _tripRegistrations[index] = existing;
      } else {
        _tripRegistrations.insert(0, existing);
      }
      _myRegisteredTripIds.add(existing.id);
      await _saveTripRegistrationsLocally();
      notifyListeners();
      return;
    }
    if (!transactionSucceeded && !localOnly) return;
    final reg =
        committedRegistration ??
        makeRegistration(bus: allocatedBus, seat: allocatedSeat);

    final existingRegistrationIndex = _tripRegistrations.indexWhere(
      (existing) => existing.id == reg.id,
    );
    if (existingRegistrationIndex >= 0) {
      _tripRegistrations[existingRegistrationIndex] = reg;
    } else {
      _tripRegistrations.insert(0, reg);
    }
    _myRegisteredTripIds.add(reg.id);
    _pendingLocalRegIds.add(reg.id);
    await _saveTripRegistrationsLocally();

    // Update booked seats locally
    final tripIdx = _pilgrimageTrips.indexWhere((t) => t.id == tripId);
    if (tripIdx != -1) {
      _pilgrimageTrips[tripIdx] = _pilgrimageTrips[tripIdx].copyWith(
        bookedSeats: max(
          _pilgrimageTrips[tripIdx].bookedSeats + 1,
          trip.bookedSeats + 1,
        ),
      );
    }
    notifyListeners();
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

  Future<TripRegistrationModel?> addPilgrimRegistration(
    TripRegistrationModel registration,
  ) async {
    if (!canManagePilgrimages && !isAdmin) return null;
    if (registration.tripId.isEmpty ||
        registration.studentId.isEmpty ||
        registration.studentName.trim().isEmpty)
      return null;

    final tripIndex = _pilgrimageTrips.indexWhere(
      (trip) => trip.id == registration.tripId,
    );
    if (tripIndex < 0) return null;
    if (_tripRegistrations.any(
      (existing) =>
          existing.tripId == registration.tripId &&
          existing.studentId == registration.studentId,
    ))
      return null;

    var savedRegistration = registration;
    var persisted = false;
    try {
      final firestore = FirebaseFirestore.instance;
      final tripRef = firestore
          .collection('pilgrimage_trips')
          .doc(registration.tripId);
      // A deterministic key prevents a coordinator and a student from booking
      // the same person twice while still permitting explicit guest IDs.
      final registrationId = '${registration.tripId}_${registration.studentId}';
      final registrationRef = firestore
          .collection('trip_registrations')
          .doc(registrationId);
      await firestore.runTransaction((transaction) async {
        persisted = false;
        savedRegistration = registration;
        final registrationSnapshot = await transaction.get(registrationRef);
        final tripSnapshot = await transaction.get(tripRef);
        if (registrationSnapshot.exists || !tripSnapshot.exists) return;

        final tripData = tripSnapshot.data() ?? const <String, dynamic>{};
        final bookedSeats = (tripData['bookedSeats'] as num?)?.toInt() ?? 0;
        final totalSeats = (tripData['totalSeats'] as num?)?.toInt() ?? 0;
        if (bookedSeats < 0 || totalSeats <= 0 || bookedSeats >= totalSeats)
          return;

        final seatNumber = bookedSeats + 1;
        final busNumber = ((seatNumber - 1) ~/ 45) + 1;
        savedRegistration = registration.copyWith(
          id: registrationId,
          busNumber: busNumber,
          seatNumber: seatNumber,
          isBoarded: false,
          boardedAt: null,
        );
        transaction.set(registrationRef, savedRegistration.toMap());
        transaction.update(tripRef, {'bookedSeats': seatNumber});
        persisted = true;
      });
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('no-app') || message.contains('not initialized')) {
        final trip = _pilgrimageTrips[tripIndex];
        if (trip.totalSeats <= 0 || trip.bookedSeats >= trip.totalSeats)
          return null;
        final seatNumber = trip.bookedSeats + 1;
        savedRegistration = registration.copyWith(
          id: '${registration.tripId}_${registration.studentId}',
          busNumber: ((seatNumber - 1) ~/ 45) + 1,
          seatNumber: seatNumber,
          isBoarded: false,
          boardedAt: null,
        );
        persisted = true;
      } else {
        debugPrint('Atomic manual trip registration failed: $e');
        return null;
      }
    }
    if (!persisted) return null;

    _tripRegistrations.insert(0, savedRegistration);
    if (_currentUser.id.isNotEmpty &&
        savedRegistration.studentId == _currentUser.id) {
      _myRegisteredTripIds.add(savedRegistration.id);
      await _saveMyRegisteredTripIds();
    }
    _pendingLocalRegIds.add(savedRegistration.id);
    await _saveTripRegistrationsLocally();
    _pilgrimageTrips[tripIndex] = _pilgrimageTrips[tripIndex].copyWith(
      bookedSeats: max(
        _pilgrimageTrips[tripIndex].bookedSeats + 1,
        savedRegistration.seatNumber,
      ),
    );
    notifyListeners();
    return savedRegistration;
  }

  Future<void> deletePilgrimRegistration(String regId) async {
    if (!canManagePilgrimages && !isAdmin) return;
    final idx = _tripRegistrations.indexWhere(
      (registration) => registration.id == regId,
    );
    if (idx == -1) return;
    final registration = _tripRegistrations[idx];

    try {
      final firestore = FirebaseFirestore.instance;
      final registrationRef = firestore
          .collection('trip_registrations')
          .doc(regId);
      final tripRef = firestore
          .collection('pilgrimage_trips')
          .doc(registration.tripId);
      await firestore.runTransaction((transaction) async {
        final registrationSnap = await transaction.get(registrationRef);
        if (!registrationSnap.exists) return;
        final tripSnap = await transaction.get(tripRef);
        if (tripSnap.exists) {
          final currentBooked =
              (tripSnap.data()?['bookedSeats'] as num?)?.toInt() ?? 0;
          if (currentBooked > 0) {
            transaction.update(tripRef, {'bookedSeats': currentBooked - 1});
          }
        }
        transaction.delete(registrationRef);
      });
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('no-app') && !message.contains('not initialized')) {
        debugPrint('Atomic trip registration cancellation failed: $e');
        return;
      }
    }

    _tripRegistrations.removeAt(idx);
    _myRegisteredTripIds.remove(regId);
    _pendingLocalRegIds.remove(regId);
    final tripIdx = _pilgrimageTrips.indexWhere(
      (trip) => trip.id == registration.tripId,
    );
    if (tripIdx != -1) {
      final currentBooked = _pilgrimageTrips[tripIdx].bookedSeats;
      _pilgrimageTrips[tripIdx] = _pilgrimageTrips[tripIdx].copyWith(
        bookedSeats: currentBooked > 0 ? currentBooked - 1 : 0,
      );
    }
    await _saveMyRegisteredTripIds();
    notifyListeners();
  }

  Future<void> updatePilgrimRegistration(TripRegistrationModel updated) async {
    if (!canManagePilgrimages && !isAdmin) return;
    final index = _tripRegistrations.indexWhere((r) => r.id == updated.id);
    if (index < 0) return;
    final previous = _tripRegistrations[index];
    if (updated.tripId != previous.tripId ||
        updated.studentId != previous.studentId)
      return;

    try {
      final reference = FirebaseFirestore.instance
          .collection('trip_registrations')
          .doc(updated.id);
      final committed = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) return false;
        transaction.update(reference, updated.toMap());
        return true;
      });
      if (!committed) return;
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('no-app') && !message.contains('not initialized')) {
        debugPrint('Firestore update pilgrim reg error: $e');
        return;
      }
    }
    _tripRegistrations[index] = updated;
    await _saveTripRegistrationsLocally();
    notifyListeners();
  }

  Future<bool> verifyTripPayment(
    String regId,
    bool approve, {
    String? rejectionReason,
  }) async {
    if (!canVerifyFinances && !canManagePilgrimages) return false;
    final index = _tripRegistrations.indexWhere((r) => r.id == regId);
    if (index < 0) return false;
    final previous = _tripRegistrations[index];
    if (previous.paymentStatus != TripPaymentStatus.pendingVerification)
      return false;

    try {
      final registrationRef = FirebaseFirestore.instance
          .collection('trip_registrations')
          .doc(regId);
      final committed = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final snapshot = await transaction.get(registrationRef);
        if (!snapshot.exists ||
            snapshot.data()?['paymentStatus'] !=
                TripPaymentStatus.pendingVerification.name) {
          return false;
        }
        final updateData = <String, dynamic>{
          'paymentStatus': approve
              ? TripPaymentStatus.verified.name
              : TripPaymentStatus.rejected.name,
          'rejectionReason': approve ? null : rejectionReason?.trim(),
        };
        transaction.update(registrationRef, updateData);
        return true;
      });
      if (!committed) return false;
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('no-app') && !message.contains('not initialized')) {
        debugPrint('Trip payment verification transaction failed: $e');
        return false;
      }
      // Local demo/test mode has no backend, so preserve the same state change.
    }

    _tripRegistrations[index] = previous.copyWith(
      paymentStatus: approve
          ? TripPaymentStatus.verified
          : TripPaymentStatus.rejected,
      rejectionReason: approve ? null : rejectionReason?.trim(),
    );
    await _saveTripRegistrationsLocally();
    notifyListeners();
    return true;
  }

  Future<bool> scanBusBoardingTicket(String qrTicketCode) async {
    if (!canManagePilgrimages && !isAdmin) return false;
    final index = _tripRegistrations.indexWhere(
      (r) =>
          r.qrTicketCode.trim().toUpperCase() ==
          qrTicketCode.trim().toUpperCase(),
    );
    if (index == -1) return false;
    final current = _tripRegistrations[index];
    if (current.isBoarded ||
        (current.paymentStatus != TripPaymentStatus.verified &&
            current.paymentStatus != TripPaymentStatus.free))
      return false;

    try {
      final registrationRef = FirebaseFirestore.instance
          .collection('trip_registrations')
          .doc(current.id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(registrationRef);
        final data = snapshot.data();
        if (!snapshot.exists ||
            data?['qrTicketCode']?.toString().toUpperCase() !=
                qrTicketCode.trim().toUpperCase() ||
            data?['isBoarded'] == true ||
            !['verified', 'free'].contains(data?['paymentStatus'])) {
          throw StateError('Ticket is invalid, already boarded, or unpaid.');
        }
        transaction.update(registrationRef, {
          'isBoarded': true,
          'boardedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (!message.contains('no-app') && !message.contains('not initialized')) {
        debugPrint('Ticket boarding transaction rejected: $e');
        return false;
      }
    }

    _tripRegistrations[index] = current.copyWith(
      isBoarded: true,
      boardedAt: DateTime.now(),
    );
    await _saveTripRegistrationsLocally();
    notifyListeners();
    return true;
  }

  Future<void> togglePassengerBoarded(String regId) async {
    if (!canManagePilgrimages && !isAdmin) return;
    final index = _tripRegistrations.indexWhere((r) => r.id == regId);
    if (index != -1) {
      final current = _tripRegistrations[index];
      if (!current.isBoarded &&
          current.paymentStatus != TripPaymentStatus.verified &&
          current.paymentStatus != TripPaymentStatus.free)
        return;
      final now = DateTime.now();
      final nextBoarded = !current.isBoarded;
      try {
        final ref = FirebaseFirestore.instance
            .collection('trip_registrations')
            .doc(regId);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          final data = snapshot.data();
          if (!snapshot.exists ||
              (!nextBoarded && data?['isBoarded'] != true) ||
              (nextBoarded && data?['isBoarded'] == true) ||
              (nextBoarded &&
                  !['verified', 'free'].contains(data?['paymentStatus']))) {
            throw StateError(
              'Passenger status changed or payment is not verified.',
            );
          }
          transaction.update(ref, {
            'isBoarded': nextBoarded,
            'boardedAt': nextBoarded ? FieldValue.serverTimestamp() : null,
          });
        });
      } catch (e) {
        final message = e.toString().toLowerCase();
        if (!message.contains('no-app') &&
            !message.contains('not initialized')) {
          debugPrint('Firestore toggle passenger boarded error: $e');
          return;
        }
      }
      _tripRegistrations[index] = current.copyWith(
        isBoarded: nextBoarded,
        boardedAt: nextBoarded ? now : null,
      );
      await _saveTripRegistrationsLocally();
      notifyListeners();
    }
  }
}
