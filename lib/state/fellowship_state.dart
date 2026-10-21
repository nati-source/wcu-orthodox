import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_models.dart';
import '../services/firestore_service.dart';
import '../services/firebase_callable_service.dart';
import '../services/notification_service.dart';

part 'auth_state.dart';
part 'family_state.dart';
part 'attendance_state.dart';
part 'roadmap_state.dart';
part 'library_state.dart';
part 'broadcast_state.dart';
part 'ministry_state.dart';
part 'spiritual_state.dart';
part 'confessor_state.dart';
part 'pilgrimage_state.dart';
part 'charity_state.dart';
part 'mentorship_state.dart';
part 'trivia_state.dart';
part 'mock_data_seeder.dart';

/// Root AppState / FellowshipState composing modular feature-slice ChangeNotifiers.
class FellowshipState extends ChangeNotifier
    with
        AuthStateMixin,
        FamilyStateMixin,
        AttendanceStateMixin,
        RoadmapStateMixin,
        LibraryStateMixin,
        BroadcastStateMixin,
        MinistryStateMixin,
        SpiritualStateMixin,
        ConfessorStateMixin,
        PilgrimageStateMixin,
        CharityStateMixin,
        MentorshipStateMixin,
        TriviaStateMixin {
  @override
  final FirestoreService _firestoreService = FirestoreService();
  @override
  FirestoreService get firestoreService => _firestoreService;

  // Feature-slice ChangeNotifiers for scoped listening & unit testing
  late final AuthState authState = AuthState(this);
  late final FamilyState familyState = FamilyState(this);
  late final AttendanceState attendanceState = AttendanceState(this);
  late final RoadmapState roadmapState = RoadmapState(this);
  late final LibraryState libraryState = LibraryState(this);
  late final BroadcastState broadcastState = BroadcastState(this);
  late final MinistryState ministryState = MinistryState(this);
  late final SpiritualState spiritualState = SpiritualState(this);
  late final ConfessorState confessorState = ConfessorState(this);
  late final PilgrimageState pilgrimageState = PilgrimageState(this);
  late final CharityState charityState = CharityState(this);
  late final MentorshipState mentorshipState = MentorshipState(this);
  late final TriviaState triviaState = TriviaState(this);

  /// User-facing error banner / notification state when cloud operations fail
  String? _lastErrorMessage;
  String? get lastErrorMessage => _lastErrorMessage;

  void reportError(String message) {
    _lastErrorMessage = message;
    notifyListeners();
  }

  void clearError() {
    if (_lastErrorMessage != null) {
      _lastErrorMessage = null;
      notifyListeners();
    }
  }

  @override
  final bool isDemoMode;

  FellowshipState({this.isDemoMode = false}) {
    _loadSavedTheme();
    _loadMyRegisteredTripIds();
    if (isDemoMode) {
      _seedDemoData();
    }
    _startCountdownTicker();
    _initCloudStreams();
  }

  // ----------------------------------------------------
  // URL LAUNCHER SHORTCUTS (TELEGRAM, CALL, SMS)
  // ----------------------------------------------------
  Future<bool> launchCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(' ', '').trim();
    if (cleanPhone.isEmpty || cleanPhone == '-') return false;
    try {
      final Uri uri = Uri(scheme: 'tel', path: cleanPhone);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> launchSms(String phoneNumber, {String? body}) async {
    final cleanPhone = phoneNumber.replaceAll(' ', '').trim();
    if (cleanPhone.isEmpty || cleanPhone == '-') return false;
    try {
      final Uri uri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: body != null ? {'body': body} : null,
      );
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      return false;
    }
  }

  Future<bool> launchTelegram(String telegramUrl) async {
    String cleanUrl = telegramUrl.trim();
    if (cleanUrl.isEmpty || cleanUrl == '-') return false;

    // 1. If it is a phone number, convert to international Telegram direct link
    final numericOnly = cleanUrl.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (RegExp(r'^\+?[0-9]{9,15}$').hasMatch(numericOnly)) {
      String phone = numericOnly;
      if (phone.startsWith('0')) {
        phone = '+251${phone.substring(1)}';
      } else if (!phone.startsWith('+')) {
        phone = '+$phone';
      }
      cleanUrl = 'https://t.me/$phone';
    } else if (cleanUrl.startsWith('@')) {
      // 2. If it is a username like @channel or @username
      cleanUrl = 'https://t.me/${cleanUrl.substring(1)}';
    } else if (!cleanUrl.startsWith('http://') &&
        !cleanUrl.startsWith('https://') &&
        !cleanUrl.startsWith('tg://')) {
      // 3. If it is a bare link like t.me/... or a username
      if (cleanUrl.startsWith('t.me/')) {
        cleanUrl = 'https://$cleanUrl';
      } else {
        cleanUrl = 'https://t.me/$cleanUrl';
      }
    }

    try {
      final Uri uri = Uri.parse(cleanUrl);
      // Attempt to launch via external application (native Telegram or Browser)
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      return true;
    } catch (_) {
      try {
        final Uri fallbackUri = Uri.parse(cleanUrl);
        return await launchUrl(fallbackUri, mode: LaunchMode.platformDefault);
      } catch (_) {
        return false;
      }
    }
  }

  void _initCloudStreams() {
    try {
      FirebaseFirestore.instance;
    } catch (_) {
      debugPrint(
        'Firebase not initialized; running FellowshipState in local/mock mode.',
      );
      _startCountdownTicker();
      return;
    }

    _listenToRegisteredUsers();
    _listenToFamilies();
    _listenToFamilyConfig();
    _listenToPilgrimageTrips();
    _listenToTripRegistrations();
    _listenToLibraryItems();
    _listenToPrograms();
    _listenToDepartmentBroadcasts();
    _listenToFundraisingProposals();
    _listenToVolunteerApplications();
    _listenToDepartmentMembers();
    _listenToConfessorFathers();
    _listenToConfessionAppointments();
    _listenToSpiritualQuestions();
    _listenToCharityCampaigns();
    _listenToDuesPayments();
    _listenToCharityDisbursements();
    _listenToEmergencyAidRequests();
    _listenToAcademicMentors();
    _listenToMentorshipRequests();
    _listenToQuizAttempts();
    _listenToAnnouncements();
    _listenToTriviaLeaderboard();
    _listenToActiveSessions();
    _listenToTriviaQuizzes();
    _listenToMinistries();
    _startCountdownTicker();
  }

  StreamSubscription? _usersSubscription;
  StreamSubscription? _familiesSubscription;
  StreamSubscription? _familyConfigSubscription;
  StreamSubscription? _pilgrimageTripsSubscription;
  StreamSubscription? _tripRegistrationsSubscription;
  StreamSubscription? _libraryItemsSubscription;
  StreamSubscription? _programsSubscription;
  StreamSubscription? _departmentBroadcastsSubscription;
  StreamSubscription? _fundraisingProposalsSubscription;
  StreamSubscription? _volunteerApplicationsSubscription;
  StreamSubscription? _departmentMembersSubscription;
  StreamSubscription? _confessorFathersSubscription;
  StreamSubscription? _confessionAppointmentsSubscription;
  StreamSubscription? _spiritualQuestionsSubscription;
  StreamSubscription? _charityCampaignsSubscription;
  StreamSubscription? _duesPaymentsSubscription;
  StreamSubscription? _charityDisbursementsSubscription;
  StreamSubscription? _emergencyAidRequestsSubscription;
  StreamSubscription? _academicMentorsSubscription;
  StreamSubscription? _mentorshipRequestsSubscription;
  bool _legacyTriviaMigrationStarted = false;
  StreamSubscription? _quizAttemptsSubscription;
  // Newly wired subscriptions
  StreamSubscription? _announcementsSubscription;
  StreamSubscription? _triviaLeaderboardSubscription;
  StreamSubscription? _attendanceSessionsSubscription;
  StreamSubscription? _attendanceScansSubscription;
  StreamSubscription? _triviaQuizzesSubscription;
  StreamSubscription? _ministriesSubscription;

  void _listenToPilgrimageTrips() {
    try {
      _pilgrimageTripsSubscription?.cancel();
      _pilgrimageTripsSubscription = FirebaseFirestore.instance
          .collection('pilgrimage_trips')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final List<PilgrimageTripModel> cloudTrips = [];
                for (final doc in snapshot.docs) {
                  try {
                    cloudTrips.add(
                      PilgrimageTripModel.fromMap(doc.data(), doc.id),
                    );
                  } catch (e) {
                    debugPrint(
                      'Error parsing pilgrimage trip doc ${doc.id}: $e',
                    );
                  }
                }
                if (cloudTrips.isNotEmpty) {
                  _pilgrimageTrips = cloudTrips;
                  notifyListeners();
                }
              }
            },
            onError: (err) {
              debugPrint('Firestore pilgrimage_trips sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore pilgrimage_trips listener setup: $e');
    }
  }

  void _listenToTripRegistrations() {
    try {
      _tripRegistrationsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'trip_registrations',
      );
      if (!isAdmin && !canManagePilgrimages && _currentUser.id.isNotEmpty) {
        query = query.where('studentId', isEqualTo: _currentUser.id);
      }
      _tripRegistrationsSubscription = query.snapshots().listen(
        (snapshot) {
          final List<TripRegistrationModel> cloudRegs = [];
          for (final doc in snapshot.docs) {
            try {
              final reg = TripRegistrationModel.fromMap(doc.data(), doc.id);
              cloudRegs.add(reg);
              _pendingLocalRegIds.remove(reg.id);
            } catch (e) {
              debugPrint('Error parsing trip registration doc ${doc.id}: $e');
            }
          }

          // Build merged map starting with cloud registrations
          final Map<String, TripRegistrationModel> map = {
            for (final r in cloudRegs) r.id: r,
          };

          // Retain any existing local registrations if not yet in snapshot
          for (final r in _tripRegistrations) {
            if (!map.containsKey(r.id)) {
              map[r.id] = r;
            }
          }

          final list = map.values.toList();
          list.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          _tripRegistrations = list;
          _saveTripRegistrationsLocally();
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore trip_registrations sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore trip_registrations listener setup: $e');
    }
  }

  void _listenToRegisteredUsers() {
    try {
      _usersSubscription?.cancel();
      final users = FirebaseFirestore.instance.collection('users');
      final canReviewAllUsers =
          isAdmin ||
          isCoordinatorOf(FellowshipDepartmentConstants.deptMemberCare);
      if (canReviewAllUsers) {
        _usersSubscription = users.snapshots().listen(
          (snapshot) {
            final currentDocIds = snapshot.docs.map((d) => d.id).toSet();

            // Prune deleted users from pending queue if they were removed from Firestore
            if (isAdmin) {
              _pendingApprovals.removeWhere(
                (u) =>
                    !currentDocIds.contains(u.id) && !u.id.startsWith('usr-p'),
              );
            }

            if (snapshot.docs.isNotEmpty) {
              for (final doc in snapshot.docs) {
                final data = doc.data();
                final user = UserModel.fromMap(data, doc.id);

                if (!user.isApproved) {
                  final pIdx = _pendingApprovals.indexWhere(
                    (u) => u.id == user.id,
                  );
                  if (pIdx >= 0) {
                    _pendingApprovals[pIdx] = user;
                  } else {
                    _pendingApprovals.insert(0, user);
                  }
                  _allStudents.removeWhere((u) => u.id == user.id);
                } else {
                  _pendingApprovals.removeWhere((u) => u.id == user.id);
                  final idx = _allStudents.indexWhere((u) => u.id == user.id);
                  if (idx >= 0) {
                    _allStudents[idx] = user;
                  } else {
                    _allStudents.insert(0, user);
                  }
                }
                if (_currentUser.id == user.id) {
                  if (user.role == UserRole.admin) {
                    _isOriginalAdmin = true;
                    _authenticatedRole = UserRole.admin;
                    _assignedRole = UserRole.admin;
                    _currentUser = user;
                  } else {
                    // If revoked or changed from admin to student/coordinator, update state immediately
                    _isOriginalAdmin = false;
                    _authenticatedRole = user.role;
                    _assignedRole = user.role;
                    _activeRole = user.role;
                    _currentUser = user;
                  }
                }
              }
            }
            notifyListeners();
          },
          onError: (err) {
            debugPrint('Firestore users sync notice: $err');
          },
        );
      } else if (_currentUser.id.isNotEmpty) {
        final familyId = _currentUser.assignedFamilyId;
        final Query<Map<String, dynamic>> profileQuery =
            _currentUser.role == UserRole.spiritualParent &&
                familyId != null &&
                familyId.isNotEmpty
            ? users.where('assignedFamilyId', isEqualTo: familyId)
            : users.where(FieldPath.documentId, isEqualTo: _currentUser.id);
        _usersSubscription = profileQuery.snapshots().listen(
          (snapshot) {
            for (final doc in snapshot.docs) {
              final user = UserModel.fromMap(doc.data(), doc.id);
              final idx = _allStudents.indexWhere((u) => u.id == user.id);
              if (user.id == _currentUser.id) {
                _currentUser = user;
              }
              if (user.role == UserRole.student && idx >= 0) {
                _allStudents[idx] = user;
              } else if (user.role == UserRole.student) {
                _allStudents.add(user);
              }
            }
            notifyListeners();
          },
          onError: (err) {
            debugPrint('Firestore self user sync notice: $err');
          },
        );
      }
    } catch (e) {
      debugPrint('Firestore users listener setup: $e');
    }
  }

  void _listenToFamilies() {
    try {
      _familiesSubscription?.cancel();
      final familyCollection = FirebaseFirestore.instance.collection(
        'families',
      );
      Query<Map<String, dynamic>> familyQuery;
      if (isAdmin ||
          isCoordinatorOf(FellowshipDepartmentConstants.deptMemberCare)) {
        familyQuery = familyCollection;
      } else if (_currentUser.role == UserRole.spiritualParent) {
        final parentField = _currentUser.gender.toLowerCase() == 'female'
            ? 'spiritualMother.id'
            : 'spiritualFather.id';
        familyQuery = familyCollection.where(
          parentField,
          isEqualTo: _currentUser.id,
        );
      } else {
        familyQuery = familyCollection.where(
          'memberIds',
          arrayContains: _currentUser.id,
        );
      }
      _familiesSubscription = familyQuery.snapshots().listen(
        (snapshot) {
          _families = snapshot.docs
              .map(
                (doc) => FamilyModel.fromMap(
                  doc.data(),
                  doc.id,
                ).copyWith(isPublished: _isFamilyPublished),
              )
              .toList();
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore families sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore families listener setup: $e');
    }
  }

  void _listenToFamilyConfig() {
    try {
      _familyConfigSubscription?.cancel();
      _familyConfigSubscription = _firestoreService.streamFamilyConfig().listen(
        (snap) {
          final data = snap.data();
          final configuredValue =
              data != null && data.containsKey('isFamilyPublished')
              ? data['isFamilyPublished']
              : data?['isPublished'];
          _isFamilyPublished = snap.exists && configuredValue == true;
          _families = _families
              .map((family) => family.copyWith(isPublished: _isFamilyPublished))
              .toList();
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore family_config sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore family_config listener setup: $e');
    }
  }

  bool _hasReceivedLibraryStream = false;

  void _listenToLibraryItems() {
    try {
      _libraryItemsSubscription?.cancel();
      _libraryItemsSubscription = FirebaseFirestore.instance
          .collection('library_items')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                _hasReceivedLibraryStream = true;
                _libraryItems = snapshot.docs
                    .map((doc) => LibraryItemModel.fromMap(doc.data(), doc.id))
                    .toList();
                if (_activeAudioMezmur != null &&
                    !_libraryItems.any((i) => i.id == _activeAudioMezmur!.id)) {
                  _activeAudioMezmur = null;
                  _isAudioPlaying = false;
                }
                notifyListeners();
              } else if (_hasReceivedLibraryStream) {
                _libraryItems = [];
                _activeAudioMezmur = null;
                _isAudioPlaying = false;
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore library_items sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore library_items listener setup: $e');
    }
  }

  void _listenToPrograms() {
    try {
      _programsSubscription?.cancel();
      _programsSubscription = FirebaseFirestore.instance
          .collection('church_programs')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                _programs = snapshot.docs
                    .map(
                      (doc) => ChurchProgramModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                _tickCountdown();

                // Real-time synchronization of emergency broadcast across ALL student and user screens
                final emergencies = _programs
                    .where((p) => p.isEmergency)
                    .toList();
                if (emergencies.isNotEmpty) {
                  emergencies.sort((a, b) => b.dateTime.compareTo(a.dateTime));
                  final topEmergency = emergencies.first;
                  if (!_dismissedEmergencyIds.contains(topEmergency.id)) {
                    _latestEmergencyBroadcast = topEmergency;
                  } else {
                    _latestEmergencyBroadcast = null;
                  }
                } else {
                  _latestEmergencyBroadcast = null;
                }
                notifyListeners();
              } else {
                _programs = [];
                _tickCountdown();
                _latestEmergencyBroadcast = null;
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore church_programs sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore church_programs listener setup: $e');
    }
  }

  void _listenToDepartmentBroadcasts() {
    try {
      _departmentBroadcastsSubscription = FirebaseFirestore.instance
          .collection('department_broadcasts')
          .snapshots()
          .listen(
            (snapshot) {
              final cloudBroadcasts = snapshot.docs
                  .map(
                    (doc) => DepartmentBroadcastMessageModel.fromMap(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList();
              cloudBroadcasts.sort((a, b) => b.sentAt.compareTo(a.sentAt));
              _departmentBroadcasts = cloudBroadcasts;
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore department_broadcasts sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore department_broadcasts listener setup: $e');
    }
  }

  void _listenToFundraisingProposals() {
    try {
      _fundraisingProposalsSubscription = FirebaseFirestore.instance
          .collection('fundraising_proposals')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final cloudProposals = snapshot.docs
                    .map(
                      (doc) =>
                          FundraisingProposalModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                for (final prop in cloudProposals) {
                  final idx = _fundraisingProposals.indexWhere(
                    (p) => p.id == prop.id,
                  );
                  if (idx >= 0) {
                    _fundraisingProposals[idx] = prop;
                  } else {
                    _fundraisingProposals.insert(0, prop);
                  }
                }
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore fundraising_proposals sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore fundraising_proposals listener setup: $e');
    }
  }

  void _listenToVolunteerApplications() {
    try {
      _volunteerApplicationsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'department_applications',
      );
      if (!isAdmin &&
          isCoordinator &&
          _currentUser.coordinatorProfile != null &&
          _currentUser.coordinatorProfile!.isReadOnlyAudit != true) {
        // Enforce department scope in data queries aligned with Firestore rules
        query = query.where(
          'ministryId',
          isEqualTo: _currentUser.coordinatorProfile!.departmentId,
        );
      } else if (!isAdmin && !isCoordinator && _currentUser.id.isNotEmpty) {
        query = query.where('studentId', isEqualTo: _currentUser.id);
      }
      _volunteerApplicationsSubscription = query.snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final cloudApps = snapshot.docs
                .map(
                  (doc) =>
                      VolunteerApplicationModel.fromMap(doc.data(), doc.id),
                )
                .toList();
            for (final app in cloudApps) {
              final idx = _volunteerApplications.indexWhere(
                (a) => a.id == app.id,
              );
              if (idx >= 0) {
                _volunteerApplications[idx] = app;
              } else {
                _volunteerApplications.insert(0, app);
              }
            }
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore department_applications sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore department_applications listener setup: $e');
    }
  }

  void _listenToMinistries() {
    try {
      _ministriesSubscription?.cancel();
      _ministriesSubscription = FirebaseFirestore.instance
          .collection('ministries')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final cloudList = snapshot.docs
                    .map((doc) => MinistryModel.fromMap(doc.data(), doc.id))
                    .toList();
                final mergedMap = {
                  for (final m in MinistryModel.defaultMinistries) m.id: m,
                };
                for (final cloudMin in cloudList) {
                  mergedMap[cloudMin.id] = cloudMin;
                }
                _ministries = mergedMap.values.toList();
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore ministries sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore ministries listener setup: $e');
    }
  }

  void _listenToDepartmentMembers() {
    try {
      _departmentMembersSubscription = FirebaseFirestore.instance
          .collection('department_members')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final cloudMembers = snapshot.docs
                    .map(
                      (doc) =>
                          DepartmentMemberModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                for (final mem in cloudMembers) {
                  final idx = _departmentMembers.indexWhere(
                    (m) => m.id == mem.id,
                  );
                  if (idx >= 0) {
                    _departmentMembers[idx] = mem;
                  } else {
                    _departmentMembers.insert(0, mem);
                  }
                }
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore department_members sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore department_members listener setup: $e');
    }
  }

  void _listenToConfessorFathers() {
    try {
      _confessorFathersSubscription?.cancel();
      _confessorFathersSubscription = FirebaseFirestore.instance
          .collection('confessors')
          .snapshots()
          .listen(
            (snapshot) {
              _confessorFathers = snapshot.docs
                  .map(
                    (doc) => ConfessorFatherModel.fromMap(doc.data(), doc.id),
                  )
                  .toList();
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore confessors sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore confessors listener setup: $e');
    }
  }

  void _listenToConfessionAppointments() {
    try {
      _confessionAppointmentsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'confession_appointments',
      );
      if (!isAdmin && _currentUser.id.isNotEmpty) {
        query = query.where('studentId', isEqualTo: _currentUser.id);
      }
      _confessionAppointmentsSubscription = query.snapshots().listen(
        (snapshot) {
          final cloudAppts = snapshot.docs
              .map(
                (doc) => ConfessionAppointmentModel.fromMap(doc.data(), doc.id),
              )
              .toList();
          cloudAppts.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
          _confessionAppointments = cloudAppts;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore confession_appointments sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore confession_appointments listener setup: $e');
    }
  }

  void _listenToSpiritualQuestions() {
    try {
      _spiritualQuestionsSubscription?.cancel();
      _spiritualQuestionsSubscription = FirebaseFirestore.instance
          .collection('spiritual_questions')
          .snapshots()
          .listen(
            (snapshot) {
              final cloudQs = snapshot.docs
                  .map(
                    (doc) => AnonymousSpiritualQuestionModel.fromMap(
                      doc.data(),
                      doc.id,
                    ),
                  )
                  .toList();
              cloudQs.sort((a, b) => b.askedAt.compareTo(a.askedAt));
              _spiritualQuestions = cloudQs;
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore spiritual_questions sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore spiritual_questions listener setup: $e');
    }
  }

  void _listenToCharityCampaigns() {
    try {
      _charityCampaignsSubscription = FirebaseFirestore.instance
          .collection('charity_campaigns')
          .snapshots()
          .listen(
            (snapshot) {
              _charityCampaigns = snapshot.docs
                  .map(
                    (doc) => CharityCampaignModel.fromMap(doc.data(), doc.id),
                  )
                  .toList();
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore charity_campaigns sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore charity_campaigns listener setup: $e');
    }
  }

  void _listenToDuesPayments() {
    try {
      _duesPaymentsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'financial_dues',
      );
      if (!isAdmin && !canVerifyFinances && _currentUser.id.isNotEmpty) {
        query = query.where('studentId', isEqualTo: _currentUser.id);
      }
      _duesPaymentsSubscription = query.snapshots().listen(
        (snapshot) {
          _duesPayments = snapshot.docs
              .map((doc) => DuesPaymentModel.fromMap(doc.data(), doc.id))
              .toList();
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore financial_dues sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore financial_dues listener setup: $e');
    }
  }

  void _listenToCharityDisbursements() {
    try {
      _charityDisbursementsSubscription?.cancel();
      if (canManageCharityAndAid ||
          canVerifyFinances ||
          canManageEmergencyAid ||
          isAdmin) {
        _charityDisbursementsSubscription = FirebaseFirestore.instance
            .collection('charity_disbursements')
            .snapshots()
            .listen(
              (snapshot) {
                _charityDisbursements = snapshot.docs
                    .map(
                      (doc) =>
                          CharityDisbursementModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                notifyListeners();
              },
              onError: (err) {
                debugPrint('Firestore charity_disbursements sync notice: $err');
              },
            );
      } else if (_currentUser.id.isNotEmpty) {
        _charityDisbursementsSubscription = FirebaseFirestore.instance
            .collection('charity_disbursements')
            .where('beneficiaryId', isEqualTo: _currentUser.id)
            .snapshots()
            .listen(
              (snapshot) {
                _charityDisbursements = snapshot.docs
                    .map(
                      (doc) =>
                          CharityDisbursementModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                notifyListeners();
              },
              onError: (err) {
                debugPrint(
                  'Firestore charity_disbursements user sync notice: $err',
                );
              },
            );
      }
    } catch (e) {
      debugPrint('Firestore charity_disbursements listener setup: $e');
    }
  }

  void _listenToEmergencyAidRequests() {
    try {
      _emergencyAidRequestsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'emergency_aid_requests',
      );
      if (!isAdmin && !canManageEmergencyAid && _currentUser.id.isNotEmpty) {
        query = query.where('studentId', isEqualTo: _currentUser.id);
      }
      _emergencyAidRequestsSubscription = query.snapshots().listen(
        (snapshot) {
          _emergencyAidRequests = snapshot.docs
              .map(
                (doc) => EmergencyAidRequestModel.fromMap(doc.data(), doc.id),
              )
              .toList();
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore emergency_aid_requests sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore emergency_aid_requests listener setup: $e');
    }
  }

  void _listenToAcademicMentors() {
    try {
      _academicMentorsSubscription = FirebaseFirestore.instance
          .collection('academic_mentors')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final cloudMentors = snapshot.docs
                    .map(
                      (doc) => AcademicMentorModel.fromMap(doc.data(), doc.id),
                    )
                    .toList();
                for (final m in cloudMentors) {
                  final idx = _academicMentors.indexWhere((x) => x.id == m.id);
                  if (idx >= 0) {
                    _academicMentors[idx] = m;
                  } else {
                    _academicMentors.add(m);
                  }
                }
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore academic_mentors sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore academic_mentors listener setup: $e');
    }
  }

  void _listenToMentorshipRequests() {
    try {
      _mentorshipRequestsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'mentorship_requests',
      );
      if (!isAdmin &&
          !isCoordinatorOf(FellowshipDepartmentConstants.deptMemberCare) &&
          _currentUser.id.isNotEmpty) {
        query = query.where('juniorStudentId', isEqualTo: _currentUser.id);
      }
      _mentorshipRequestsSubscription = query.snapshots().listen(
        (snapshot) {
          final cloudReqs = snapshot.docs
              .map((doc) => MentorshipRequestModel.fromMap(doc.data(), doc.id))
              .toList();
          cloudReqs.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
          _mentorshipRequests = cloudReqs;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore mentorship_requests sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore mentorship_requests listener setup: $e');
    }
  }

  void _listenToQuizAttempts() {
    try {
      _quizAttemptsSubscription?.cancel();
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'quiz_attempts',
      );
      query = query.where('trustedScoreVersion', isEqualTo: 1);
      if (!isAdmin && _currentUser.id.isNotEmpty) {
        query = query.where('studentId', isEqualTo: _currentUser.id);
      }
      _quizAttemptsSubscription = query.snapshots().listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final cloudAttempts = snapshot.docs
                .map((doc) => QuizAttemptModel.fromMap(doc.data(), doc.id))
                .toList();
            for (final a in cloudAttempts) {
              final idx = _quizAttempts.indexWhere((x) => x.id == a.id);
              if (idx >= 0) {
                _quizAttempts[idx] = a;
              } else {
                _quizAttempts.insert(0, a);
              }
            }
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore quiz_attempts sync notice: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore quiz_attempts listener setup: $e');
    }
  }

  /// Re-scopes and re-binds Firestore streams when the active user role or UID updates.
  void refreshScopedStreams() {
    _listenToRegisteredUsers();
    _listenToTripRegistrations();
    _listenToVolunteerApplications();
    _listenToConfessionAppointments();
    _listenToDuesPayments();
    _listenToCharityDisbursements();
    _listenToEmergencyAidRequests();
    _listenToMentorshipRequests();
    _listenToQuizAttempts();
    if (isAdmin && !_legacyTriviaMigrationStarted) {
      _legacyTriviaMigrationStarted = true;
      unawaited(
        FirebaseCallableService.instance
            .call('migrateLegacyTriviaQuizzes')
            .then((result) {
              debugPrint('Legacy trivia migration: $result');
            })
            .catchError((Object error) {
              _legacyTriviaMigrationStarted = false;
              debugPrint('Legacy trivia migration unavailable: $error');
            }),
      );
    }
  }

  // -------------------------------------------------------------------
  // NEWLY WIRED STREAMS: Announcements, Trivia Leaderboard, Active Sessions
  // -------------------------------------------------------------------

  void _listenToAnnouncements() {
    try {
      _announcementsSubscription?.cancel();
      _announcementsSubscription = FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _announcements = snapshot.docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = doc.id;
                return data;
              }).toList();
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore announcements sync: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore announcements setup: $e');
    }
  }

  void _listenToTriviaLeaderboard() {
    try {
      _triviaLeaderboardSubscription?.cancel();
      _triviaLeaderboardSubscription = FirebaseFirestore.instance
          .collection('trivia_scores')
          .where('trustedScoreVersion', isEqualTo: 1)
          .orderBy('totalScore', descending: true)
          .limit(50)
          .snapshots()
          .listen(
            (snapshot) {
              _globalTriviaLeaderboard = snapshot.docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = doc.id;
                return data;
              }).toList();
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore trivia_scores sync: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore trivia_scores setup: $e');
    }
  }

  void _listenToActiveSessions() {
    try {
      _attendanceSessionsSubscription?.cancel();
      final canManageAttendance =
          isAdmin ||
          isCoordinatorOf(FellowshipDepartmentConstants.deptEducation);
      final collectionName = canManageAttendance
          ? 'attendance_sessions'
          : 'attendance_session_status';
      _attendanceSessionsSubscription = FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                final activeDoc = snapshot.docs.firstWhere(
                  (doc) => (doc.data()['isActive'] == true),
                  orElse: () => snapshot.docs.first,
                );
                final data = activeDoc.data();
                final cloudPin = canManageAttendance
                    ? (data['rollingPin'] as String? ?? '----')
                    : '';
                final cloudCode = canManageAttendance
                    ? (data['code'] as String? ?? 'ORTH-301-STANDBY')
                    : '';
                final storedIsActive = data['isActive'] as bool? ?? false;
                final storedIsExpired = data['isExpired'] as bool? ?? false;
                final courseName = data['courseName'] as String?;
                final courseCode = data['courseCode'] as String?;
                final faculty = data['faculty'] as String?;

                DateTime? generatedAt;
                if (data['generatedAt'] is Timestamp) {
                  generatedAt = (data['generatedAt'] as Timestamp).toDate();
                } else if (data['generatedAt'] is String) {
                  generatedAt = DateTime.tryParse(
                    data['generatedAt'] as String,
                  );
                }

                DateTime? expDate;
                if (data['expiresAt'] != null) {
                  if (data['expiresAt'] is Timestamp) {
                    expDate = (data['expiresAt'] as Timestamp).toDate();
                  } else if (data['expiresAt'] is String) {
                    expDate = DateTime.tryParse(data['expiresAt']);
                  }
                }

                final expiredByTime =
                    expDate != null && !expDate.isAfter(DateTime.now());
                final isActive = storedIsActive && !expiredByTime;
                final isExpired = storedIsExpired || expiredByTime;

                if (isActive && expDate != null) {
                  final remainingSeconds = expDate
                      .difference(DateTime.now())
                      .inSeconds;
                  if (remainingSeconds > 0) {
                    pinCountdownNotifier.value = remainingSeconds.clamp(0, 30);
                  }
                }

                final sessionId = activeDoc.id;
                _activeSession = _activeSession.copyWith(
                  sessionId: sessionId,
                  rollingPin: cloudPin,
                  code: cloudCode,
                  generatedAt: generatedAt,
                  isActive: isActive,
                  isExpired: isExpired,
                  expiresAt: expDate,
                  courseName: courseName,
                  courseCode: courseCode,
                  faculty: faculty,
                );
                notifyListeners();

                if (canManageAttendance) {
                  _listenToAttendanceScansForSession(sessionId);
                } else {
                  _attendanceScansSubscription?.cancel();
                  _activeSession = _activeSession.copyWith(scans: const []);
                }
              }
            },
            onError: (err) {
              debugPrint('Firestore attendance active sync: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore attendance sessions setup: $e');
    }
  }

  void _listenToAttendanceScansForSession(String sessionId) {
    try {
      _attendanceScansSubscription?.cancel();
      _attendanceScansSubscription = FirebaseFirestore.instance
          .collection('attendance_sessions')
          .doc(sessionId)
          .collection('scans')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final fetchedScans = snapshot.docs.map((doc) {
                return AttendanceRecordModel.fromMap(doc.data(), doc.id);
              }).toList();

              _activeSession = _activeSession.copyWith(scans: fetchedScans);
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore attendance scans sync: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore attendance scans setup: $e');
    }
  }

  void _listenToTriviaQuizzes() {
    try {
      _triviaQuizzesSubscription?.cancel();
      _triviaQuizzesSubscription = FirebaseFirestore.instance
          .collection('trivia_public_quizzes')
          .snapshots()
          .listen(
            (snapshot) {
              _triviaQuizzes = snapshot.docs
                  .map((doc) => TriviaQuizModel.fromMap(doc.data(), doc.id))
                  .toList();
              _triviaQuizzes.sort(
                (a, b) => b.weekNumber.compareTo(a.weekNumber),
              );
              notifyListeners();
            },
            onError: (err) {
              debugPrint('Firestore trivia_public_quizzes sync notice: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore trivia_public_quizzes listener setup: $e');
    }
  }

  @override
  void dispose() {
    _usersSubscription?.cancel();
    _familiesSubscription?.cancel();
    _familyConfigSubscription?.cancel();
    _pilgrimageTripsSubscription?.cancel();
    _tripRegistrationsSubscription?.cancel();
    _libraryItemsSubscription?.cancel();
    _programsSubscription?.cancel();
    _departmentBroadcastsSubscription?.cancel();
    _fundraisingProposalsSubscription?.cancel();
    _volunteerApplicationsSubscription?.cancel();
    _departmentMembersSubscription?.cancel();
    _confessorFathersSubscription?.cancel();
    _confessionAppointmentsSubscription?.cancel();
    _spiritualQuestionsSubscription?.cancel();
    _charityCampaignsSubscription?.cancel();
    _duesPaymentsSubscription?.cancel();
    _charityDisbursementsSubscription?.cancel();
    _emergencyAidRequestsSubscription?.cancel();
    _academicMentorsSubscription?.cancel();
    _mentorshipRequestsSubscription?.cancel();
    _quizAttemptsSubscription?.cancel();
    _announcementsSubscription?.cancel();
    _triviaLeaderboardSubscription?.cancel();
    _attendanceSessionsSubscription?.cancel();
    _attendanceScansSubscription?.cancel();
    _triviaQuizzesSubscription?.cancel();
    _ministriesSubscription?.cancel();
    _pinTimer?.cancel();
    _countdownTimer?.cancel();
    pinCountdownNotifier.dispose();
    liturgyCountdownNotifier.dispose();
    authState.dispose();
    familyState.dispose();
    attendanceState.dispose();
    roadmapState.dispose();
    libraryState.dispose();
    broadcastState.dispose();
    ministryState.dispose();
    spiritualState.dispose();
    confessorState.dispose();
    pilgrimageState.dispose();
    charityState.dispose();
    mentorshipState.dispose();
    triviaState.dispose();
    super.dispose();
  }
}
