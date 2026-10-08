import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/firestore_service.dart';

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

  final bool isDemoMode;

  FellowshipState({this.isDemoMode = false}) {
    _loadSavedTheme();
    if (isDemoMode) {
      _seedDemoData();
    }
    _startPinRotation();
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
    } else if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://') && !cleanUrl.startsWith('tg://')) {
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
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      debugPrint('Firebase not initialized; running FellowshipState in local/mock mode.');
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
    _autoSyncInitialDataToCloud();
  }

  /// Automatically seed Firestore if missing key collections like pilgrimage_trips or families.
  /// ADMIN ONLY — prevents any normal user from writing bulk mock data to the shared database.
  Future<void> autoSeedIfEmpty() async {




    try {
      debugPrint('autoSeedIfEmpty: skipped — auto-seeding is disabled.');

      final tripSnap = await FirebaseFirestore.instance.collection('pilgrimage_trips').limit(1).get();
      final famSnap = await FirebaseFirestore.instance.collection('families').limit(1).get();
      if (false) {
        debugPrint('Firestore database initial check: missing pilgrimage_trips or families detected, seeding all 20 collections...');
        await seedEntireDatabaseToFirestore();
      }
    } catch (e) {
      debugPrint('Firestore autoSeedIfEmpty error: $e');
    }
  }

  void _autoSyncInitialDataToCloud() async {
    // Only admins can trigger bulk seeding
    // if (isAdmin) await autoSeedIfEmpty();
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
  StreamSubscription? _quizAttemptsSubscription;
  // Newly wired subscriptions
  StreamSubscription? _announcementsSubscription;
  StreamSubscription? _triviaLeaderboardSubscription;
  StreamSubscription? _attendanceSessionsSubscription;
  StreamSubscription? _triviaQuizzesSubscription;
  StreamSubscription? _ministriesSubscription;

  void _listenToPilgrimageTrips() {
    try {
      _pilgrimageTripsSubscription?.cancel();
      _pilgrimageTripsSubscription = FirebaseFirestore.instance
          .collection('pilgrimage_trips')
          .snapshots()
          .listen((snapshot) {
        _pilgrimageTrips = snapshot.docs.map((doc) => PilgrimageTripModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore pilgrimage_trips sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore pilgrimage_trips listener setup: $e');
    }
  }

  void _listenToTripRegistrations() {
    try {
      _tripRegistrationsSubscription?.cancel();
      _tripRegistrationsSubscription = FirebaseFirestore.instance
          .collection('trip_registrations')
          .snapshots()
          .listen((snapshot) {
        _tripRegistrations = snapshot.docs.map((doc) => TripRegistrationModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore trip_registrations sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore trip_registrations listener setup: $e');
    }
  }

  void _listenToRegisteredUsers() {
    try {
      _usersSubscription = FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
        final currentDocIds = snapshot.docs.map((d) => d.id).toSet();

        // Prune deleted users from pending queue if they were removed from Firestore
        _pendingApprovals.removeWhere((u) => !currentDocIds.contains(u.id) && !u.id.startsWith('usr-p'));

        if (snapshot.docs.isNotEmpty) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final rawEmail = data['email']?.toString();
            final bool isAdminDoc = AppAdminConstants.isAdminEmail(rawEmail) || doc.id == 'gonGT6FkXzZTlHQkXWTFokH8GZF3';

            var user = UserModel.fromMap(data, doc.id);
            if (isAdminDoc) {
              user = user.copyWith(role: UserRole.admin, isApproved: true);
            }

            if (!user.isApproved && !isAdminDoc) {
              final pIdx = _pendingApprovals.indexWhere((u) => u.id == user.id);
              if (pIdx >= 0) {
                _pendingApprovals[pIdx] = user;
              } else {
                _pendingApprovals.insert(0, user);
              }
              _allStudents.removeWhere((u) => u.id == user.id);
            } else {
              _pendingApprovals.removeWhere((u) => u.id == user.id);
              final idx = _allStudents.indexWhere(
                (u) => u.id == user.id || u.fullName.trim().toLowerCase() == user.fullName.trim().toLowerCase(),
              );
              if (idx >= 0) {
                _allStudents[idx] = user;
              } else {
                _allStudents.insert(0, user);
              }
            }
            if (_currentUser.id == user.id ||
                (_currentUser.fullName.trim().isNotEmpty &&
                 _currentUser.fullName.trim().toLowerCase() == user.fullName.trim().toLowerCase())) {
              if (isAdminDoc) {
                _currentUser = user.copyWith(role: UserRole.admin, isApproved: true);
                _activeRole = UserRole.admin;
                _authenticatedRole = UserRole.admin;
                _assignedRole = UserRole.admin;
              } else {
                _currentUser = user;
              }
            }
          }
        }
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore users sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore users listener setup: $e');
    }
  }

  void _listenToFamilies() {
    try {
      _familiesSubscription?.cancel();
      _familiesSubscription = FirebaseFirestore.instance.collection('families').snapshots().listen((snapshot) {
        _families = snapshot.docs.map((doc) => FamilyModel.fromMap(doc.data(), doc.id)).toList();
        if (_families.any((f) => f.isPublished)) {
          _isFamilyPublished = true;
        }
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore families sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore families listener setup: $e');
    }
  }

  void _listenToFamilyConfig() {
    try {
      _familyConfigSubscription?.cancel();
      _familyConfigSubscription = _firestoreService.streamFamilyConfig().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          final isPub = data['isFamilyPublished'] == true || data['isPublished'] == true;
          if (isPub) {
            _isFamilyPublished = true;
            _families = _families.map((f) => f.copyWith(isPublished: true)).toList();
            notifyListeners();
          }
        }
      }, onError: (err) {
        debugPrint('Firestore family_config sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore family_config listener setup: $e');
    }
  }

  bool _hasReceivedLibraryStream = false;

  void _listenToLibraryItems() {
    try {
      _libraryItemsSubscription?.cancel();
      _libraryItemsSubscription = FirebaseFirestore.instance.collection('library_items').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _hasReceivedLibraryStream = true;
          _libraryItems = snapshot.docs.map((doc) => LibraryItemModel.fromMap(doc.data(), doc.id)).toList();
          if (_activeAudioMezmur != null && !_libraryItems.any((i) => i.id == _activeAudioMezmur!.id)) {
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
      }, onError: (err) {
        debugPrint('Firestore library_items sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore library_items listener setup: $e');
    }
  }

  void _listenToPrograms() {
    try {
      _programsSubscription?.cancel();
      _programsSubscription = FirebaseFirestore.instance.collection('church_programs').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _programs = snapshot.docs.map((doc) => ChurchProgramModel.fromMap(doc.data(), doc.id)).toList();
          _tickCountdown();

          // Real-time synchronization of emergency broadcast across ALL student and user screens
          final emergencies = _programs.where((p) => p.isEmergency).toList();
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
          _latestEmergencyBroadcast = null;
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore church_programs sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore church_programs listener setup: $e');
    }
  }

  void _listenToDepartmentBroadcasts() {
    try {
      _departmentBroadcastsSubscription = FirebaseFirestore.instance.collection('department_broadcasts').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudBroadcasts = snapshot.docs.map((doc) => DepartmentBroadcastMessageModel.fromMap(doc.data(), doc.id)).toList();
          for (final b in cloudBroadcasts) {
            final idx = _departmentBroadcasts.indexWhere((x) => x.id == b.id);
            if (idx >= 0) {
              _departmentBroadcasts[idx] = b;
            } else {
              _departmentBroadcasts.insert(0, b);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore department_broadcasts sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore department_broadcasts listener setup: $e');
    }
  }

  void _listenToFundraisingProposals() {
    try {
      _fundraisingProposalsSubscription = FirebaseFirestore.instance.collection('fundraising_proposals').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudProposals = snapshot.docs.map((doc) => FundraisingProposalModel.fromMap(doc.data(), doc.id)).toList();
          for (final prop in cloudProposals) {
            final idx = _fundraisingProposals.indexWhere((p) => p.id == prop.id);
            if (idx >= 0) {
              _fundraisingProposals[idx] = prop;
            } else {
              _fundraisingProposals.insert(0, prop);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore fundraising_proposals sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore fundraising_proposals listener setup: $e');
    }
  }

  void _listenToVolunteerApplications() {
    try {
      _volunteerApplicationsSubscription = FirebaseFirestore.instance.collection('department_applications').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudApps = snapshot.docs.map((doc) => VolunteerApplicationModel.fromMap(doc.data(), doc.id)).toList();
          for (final app in cloudApps) {
            final idx = _volunteerApplications.indexWhere((a) => a.id == app.id);
            if (idx >= 0) {
              _volunteerApplications[idx] = app;
            } else {
              _volunteerApplications.insert(0, app);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore department_applications sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore department_applications listener setup: $e');
    }
  }

  void _listenToMinistries() {
    try {
      _ministriesSubscription?.cancel();
      _ministriesSubscription = FirebaseFirestore.instance.collection('ministries').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudList = snapshot.docs.map((doc) => MinistryModel.fromMap(doc.data(), doc.id)).toList();
          final mergedMap = {for (final m in MinistryModel.defaultMinistries) m.id: m};
          for (final cloudMin in cloudList) {
            mergedMap[cloudMin.id] = cloudMin;
          }
          _ministries = mergedMap.values.toList();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore ministries sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore ministries listener setup: $e');
    }
  }

  void _listenToDepartmentMembers() {
    try {
      _departmentMembersSubscription = FirebaseFirestore.instance.collection('department_members').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudMembers = snapshot.docs.map((doc) => DepartmentMemberModel.fromMap(doc.data(), doc.id)).toList();
          for (final mem in cloudMembers) {
            final idx = _departmentMembers.indexWhere((m) => m.id == mem.id);
            if (idx >= 0) {
              _departmentMembers[idx] = mem;
            } else {
              _departmentMembers.insert(0, mem);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore department_members sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore department_members listener setup: $e');
    }
  }

  void _listenToConfessorFathers() {
    try {
      _confessorFathersSubscription = FirebaseFirestore.instance.collection('confessors').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _confessorFathers = snapshot.docs.map((doc) => ConfessorFatherModel.fromMap(doc.data(), doc.id)).toList();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore confessors sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore confessors listener setup: $e');
    }
  }

  void _listenToConfessionAppointments() {
    try {
      _confessionAppointmentsSubscription = FirebaseFirestore.instance.collection('confession_appointments').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudAppts = snapshot.docs.map((doc) => ConfessionAppointmentModel.fromMap(doc.data(), doc.id)).toList();
          for (final appt in cloudAppts) {
            final idx = _confessionAppointments.indexWhere((a) => a.id == appt.id);
            if (idx >= 0) {
              _confessionAppointments[idx] = appt;
            } else {
              _confessionAppointments.insert(0, appt);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore confession_appointments sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore confession_appointments listener setup: $e');
    }
  }

  void _listenToSpiritualQuestions() {
    try {
      _spiritualQuestionsSubscription = FirebaseFirestore.instance.collection('spiritual_questions').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudQs = snapshot.docs.map((doc) => AnonymousSpiritualQuestionModel.fromMap(doc.data(), doc.id)).toList();
          for (final q in cloudQs) {
            final idx = _spiritualQuestions.indexWhere((x) => x.id == q.id);
            if (idx >= 0) {
              _spiritualQuestions[idx] = q;
            } else {
              _spiritualQuestions.insert(0, q);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore spiritual_questions sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore spiritual_questions listener setup: $e');
    }
  }

  void _listenToCharityCampaigns() {
    try {
      _charityCampaignsSubscription = FirebaseFirestore.instance.collection('charity_campaigns').snapshots().listen((snapshot) {
        _charityCampaigns = snapshot.docs.map((doc) => CharityCampaignModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore charity_campaigns sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore charity_campaigns listener setup: $e');
    }
  }

  void _listenToDuesPayments() {
    try {
      _duesPaymentsSubscription = FirebaseFirestore.instance.collection('financial_dues').snapshots().listen((snapshot) {
        _duesPayments = snapshot.docs.map((doc) => DuesPaymentModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore financial_dues sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore financial_dues listener setup: $e');
    }
  }

  void _listenToCharityDisbursements() {
    try {
      _charityDisbursementsSubscription = FirebaseFirestore.instance.collection('charity_disbursements').snapshots().listen((snapshot) {
        _charityDisbursements = snapshot.docs.map((doc) => CharityDisbursementModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore charity_disbursements sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore charity_disbursements listener setup: $e');
    }
  }

  void _listenToEmergencyAidRequests() {
    try {
      _emergencyAidRequestsSubscription = FirebaseFirestore.instance.collection('emergency_aid_requests').snapshots().listen((snapshot) {
        _emergencyAidRequests = snapshot.docs.map((doc) => EmergencyAidRequestModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore emergency_aid_requests sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore emergency_aid_requests listener setup: $e');
    }
  }

  void _listenToAcademicMentors() {
    try {
      _academicMentorsSubscription = FirebaseFirestore.instance.collection('academic_mentors').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudMentors = snapshot.docs.map((doc) => AcademicMentorModel.fromMap(doc.data(), doc.id)).toList();
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
      }, onError: (err) {
        debugPrint('Firestore academic_mentors sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore academic_mentors listener setup: $e');
    }
  }

  void _listenToMentorshipRequests() {
    try {
      _mentorshipRequestsSubscription = FirebaseFirestore.instance.collection('mentorship_requests').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudReqs = snapshot.docs.map((doc) => MentorshipRequestModel.fromMap(doc.data(), doc.id)).toList();
          for (final r in cloudReqs) {
            final idx = _mentorshipRequests.indexWhere((x) => x.id == r.id);
            if (idx >= 0) {
              _mentorshipRequests[idx] = r;
            } else {
              _mentorshipRequests.insert(0, r);
            }
          }
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore mentorship_requests sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore mentorship_requests listener setup: $e');
    }
  }

  void _listenToQuizAttempts() {
    try {
      _quizAttemptsSubscription = FirebaseFirestore.instance.collection('quiz_attempts').snapshots().listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cloudAttempts = snapshot.docs.map((doc) => QuizAttemptModel.fromMap(doc.data(), doc.id)).toList();
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
      }, onError: (err) {
        debugPrint('Firestore quiz_attempts sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore quiz_attempts listener setup: $e');
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
          .listen((snapshot) {
        _announcements = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore announcements sync: $err');
      });
    } catch (e) {
      debugPrint('Firestore announcements setup: $e');
    }
  }

  void _listenToTriviaLeaderboard() {
    try {
      _triviaLeaderboardSubscription?.cancel();
      _triviaLeaderboardSubscription = FirebaseFirestore.instance
          .collection('trivia_scores')
          .orderBy('totalScore', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
        _globalTriviaLeaderboard = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore trivia_scores sync: $err');
      });
    } catch (e) {
      debugPrint('Firestore trivia_scores setup: $e');
    }
  }

  void _listenToActiveSessions() {
    try {
      _attendanceSessionsSubscription?.cancel();
      _attendanceSessionsSubscription = FirebaseFirestore.instance
          .collection('attendance_sessions')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final data = doc.data();
          final cloudPin = data['rollingPin'] as String?;
          final cloudCode = data['code'] as String?;
          if (cloudPin != null && cloudPin.isNotEmpty &&
              cloudPin != _activeSession.rollingPin) {
            _activeSession = _activeSession.copyWith(
              rollingPin: cloudPin,
              code: cloudCode ?? _activeSession.code,
            );
            notifyListeners();
          }
        }
      }, onError: (err) {
        debugPrint('Firestore attendance active sync: $err');
      });
    } catch (e) {
      debugPrint('Firestore attendance sessions setup: $e');
    }
  }

  void _listenToTriviaQuizzes() {
    try {
      _triviaQuizzesSubscription?.cancel();
      _triviaQuizzesSubscription = FirebaseFirestore.instance.collection('trivia_quizzes').snapshots().listen((snapshot) {
        _triviaQuizzes = snapshot.docs.map((doc) => TriviaQuizModel.fromMap(doc.data(), doc.id)).toList();
        _triviaQuizzes.sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore trivia_quizzes sync notice: $err');
      });
    } catch (e) {
      debugPrint('Firestore trivia_quizzes listener setup: $e');
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
