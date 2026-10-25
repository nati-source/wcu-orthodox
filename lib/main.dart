import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'models/app_models.dart';
import 'state/fellowship_state.dart';
import 'theme/app_theme.dart';
import 'widgets/experience_switcher_banner.dart';
import 'widgets/orthodox_header.dart';
import 'widgets/edit_profile_modal.dart';
import 'views/student/student_home_screen.dart';
import 'views/student/student_family_screen.dart';
import 'views/student/student_roadmap_screen.dart';
import 'views/student/student_library_screen.dart';
import 'views/student/student_profile_screen.dart';
import 'views/student/student_qr_scanner_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/admin/admin_family_matching_screen.dart';
import 'views/admin/admin_live_attendance_screen.dart';
import 'views/admin/admin_approvals_screen.dart';
import 'views/admin/admin_media_curriculum_screen.dart';
import 'views/coordinator/coordinator_hub_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/register_screen.dart';
import 'views/auth/pending_approval_screen.dart';
import 'views/onboarding/fellowship_onboarding_screen.dart';
import 'views/help/user_guide_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/connectivity_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // ── Step 1: Firebase Core (BLOCKING — everything else depends on this) ──
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ── Step 2: Crash Reporting (BLOCKING — must be set before runApp) ──────
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);

    // ── Step 3: Firestore Offline Persistence (BLOCKING — must apply before
    //           any Firestore reads to avoid "settings changed after use" error)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024, // 50 MB deliberate cache limit to prevent disk bloat
    );

    // ── Step 4: Background message handler must be registered before runApp ──
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // ── Step 5: Non-critical services start IN PARALLEL (non-blocking) ──────
    // These do NOT need to finish before showing the first frame.
    // App Check, Analytics, Performance, Notifications and Connectivity
    // all run concurrently — cutting startup wait from ~3-5s to <1s.
    Future.wait([
      if (kDebugMode)
        FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
        ).catchError((_) {}),
      FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode),
      FirebasePerformance.instance.setPerformanceCollectionEnabled(!kDebugMode),
      NotificationService.instance.initialize(),
      ConnectivityService.instance.initialize(),
    ]).catchError((e) {
      debugPrint('Background service init notice: $e');
      return <void>[];  // catchError on Future<List<void>> must return List<void>
    });
    // ↑ Intentionally NOT awaited — app launches immediately while these warm up

  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  // App is shown immediately after Step 1-4; Step 5 services finish in background
  runApp(const WcuOrthodoxApp());
}

class WcuOrthodoxApp extends StatefulWidget {
  const WcuOrthodoxApp({super.key});

  @override
  State<WcuOrthodoxApp> createState() => _WcuOrthodoxAppState();
}

class _WcuOrthodoxAppState extends State<WcuOrthodoxApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final FellowshipState _fellowshipState = FellowshipState();
  final AuthService _authService = AuthService();
  bool _isDemoMode = false;
  String? _syncedUid;
  bool _isSyncingProfile = false;
  bool _hasCompletedOnboarding = false;
  bool _openRegisterAfterOnboarding = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingStatus();
    NotificationService.globalContextProvider = () => _navigatorKey.currentContext;
    NotificationService.instance.onForegroundMessageReceived = (message) {
      final ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        NotificationService.showForegroundInAppBanner(ctx, message);
      }
    };
  }

  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool('has_completed_onboarding_tour_v1') ?? false;
      if (mounted) {
        setState(() {
          _hasCompletedOnboarding = hasCompleted;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    NotificationService.instance.dispose();
    _fellowshipState.dispose();
    super.dispose();
  }

  void _syncUserProfile(dynamic user) async {
    if (user == null) return;

    final bool isAdminEmail = AppAdminConstants.isAdminEmail(user.email);
    bool cachedApproved = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      cachedApproved = prefs.getBool('user_is_approved_${user.uid}') ?? false;
    } catch (_) {}

    // If designated admin, IMMEDIATELY initialize state with admin privileges and approval on initial load
    if (isAdminEmail) {
      _fellowshipState.markAsOriginalAdmin();
      if (_fellowshipState.currentUser.id != user.uid || !_fellowshipState.currentUser.isApproved) {
        _fellowshipState.updateCurrentUserProfile(
          id: user.uid,
          fullName: (user.displayName != null && (user.displayName as String).trim().isNotEmpty)
              ? (user.displayName as String).trim()
              : (user.email != null && (user.email as String).contains('@')
                  ? (user.email as String).split('@').first
                  : 'Nati (Admin)'),
          role: UserRole.admin,
          isApproved: true,
        );
      }
      _fellowshipState.refreshScopedStreams();
    } else {
      if (_fellowshipState.currentUser.id != user.uid || _fellowshipState.currentUser.isApproved != cachedApproved) {
        _fellowshipState.updateCurrentUserProfile(
          id: user.uid,
          fullName: (user.displayName != null && (user.displayName as String).trim().isNotEmpty)
              ? (user.displayName as String).trim()
              : (user.email != null && (user.email as String).contains('@')
                  ? (user.email as String).split('@').first
                  : 'Student Fellow'),
          role: UserRole.student,
          isApproved: cachedApproved,
        );
      }
    }

    // Only run the full Firestore profile sync once per authenticated user session.
    if (_syncedUid == user.uid) return;
    _syncedUid = user.uid;

    if (mounted && !isAdminEmail) {
      setState(() {
        _isSyncingProfile = true;
      });
      // Safety watchdog: ensure loading spinner is dismissed within 3 seconds under any network condition
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isSyncingProfile) {
          setState(() {
            _isSyncingProfile = false;
          });
        }
      });
    }

    try {
      final profile = await _authService.getUserProfile(user.uid);

      if (profile != null && mounted) {
        final roleStr = profile['role']?.toString().trim() ?? (isAdminEmail ? 'admin' : 'student');
        UserRole role = isAdminEmail ? UserRole.admin : UserRole.student;
        for (final r in UserRole.values) {
          if (r.name.toLowerCase() == roleStr.toLowerCase()) {
            role = r;
            break;
          }
        }

        final rawApproved = profile['isApproved'];
        final bool isApproved = (rawApproved is bool && rawApproved) ||
            rawApproved?.toString().toLowerCase() == 'true' ||
            rawApproved == 1 ||
            (isAdminEmail || role == UserRole.admin);

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('user_is_approved_${user.uid}', isApproved);
        } catch (_) {}

        if (role == UserRole.admin || isAdminEmail) {
          _fellowshipState.markAsOriginalAdmin();
        } else {
          _fellowshipState.revokeAdminPrivileges();
        }

        _fellowshipState.updateCurrentUserProfile(
          id: user.uid,
          fullName: profile['fullName'] ?? user.displayName ?? (role == UserRole.admin ? 'Nati (Admin)' : 'Student Fellow'),
          baptismalName: profile['baptismalName'],
          phoneNumber: profile['phoneNumber'],
          department: profile['department'],
          academicYear: profile['academicYear'] is int ? profile['academicYear'] : int.tryParse(profile['academicYear']?.toString() ?? '1'),
          batchYear: profile['batchYear']?.toString(),
          role: role,
          isApproved: isApproved,
          assignedFamilyId: profile['assignedFamilyId'] ?? profile['familyId'] ?? profile['family'] ?? profile['assignedFamily'],
        );

        _fellowshipState.refreshScopedStreams();

        // Only approved accounts receive role topics. The academic department
        // field is not a coordinator scope; use the explicit RBAC profile.
        if (isApproved) {
          final coordinatorProfile = profile['coordinatorProfile'];
          final departmentId = role == UserRole.volunteerCoordinator && coordinatorProfile is Map
              ? coordinatorProfile['departmentId']?.toString()
              : null;
          unawaited(NotificationService.instance.syncUserFcmToken(
            userId: user.uid,
            role: role.name,
            assignedFamilyId: profile['assignedFamilyId'] ?? profile['familyId'] ?? profile['family'] ?? profile['assignedFamily'],
            departmentId: departmentId,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingProfile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fellowshipState,
      builder: (context, _) {
        final currentPalette = _fellowshipState.currentThemePalette;
        final themeData = AppTheme.getTheme(currentPalette);

        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'WCU Orthodox Fellowship',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          darkTheme: themeData,
          themeMode: currentPalette.isDark ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            return Theme(
              data: themeData,
              child: OfflineAwareBanner(child: child ?? const SizedBox.shrink()),
            );
          },
          home: StreamBuilder(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;

              // Reset session state when user signs out
              if (user == null) {
                if (_isDemoMode || _syncedUid != null) {
                  _isDemoMode = false;
                  _syncedUid = null;
                  _isSyncingProfile = false;
                  _fellowshipState.revokeAdminPrivileges();
                }
              }

              if (user != null) {
                final bool isAdmin = AppAdminConstants.isAdminEmail(user.email) ||
                    _fellowshipState.isAuthorizedAdmin ||
                    _fellowshipState.currentUser.role == UserRole.admin;

                _syncUserProfile(user);

                // Show safe loader while initial profile sync is happening if approval is not yet verified
                if (!isAdmin && _isSyncingProfile && !_fellowshipState.currentUser.isApproved) {
                  return Scaffold(
                    backgroundColor: const Color(0xFF070F1E),
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.gold),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading profile... / በመጫን ላይ...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              if (mounted) {
                                setState(() {
                                  _isSyncingProfile = false;
                                });
                              }
                            },
                            child: const Text(
                              'Continue / በቀጥታ ግባ',
                              style: TextStyle(color: AppTheme.gold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Show pending screen if student is not yet approved
                if (!isAdmin && !_fellowshipState.currentUser.isApproved) {
                  return PendingApprovalScreen(
                    fullName: _fellowshipState.currentUser.fullName,
                    email: user.email,
                    onCheckStatus: () {
                      _syncedUid = null;
                      _syncUserProfile(user);
                    },
                  );
                }

                return MainFellowshipScaffold(state: _fellowshipState);
              }
              if (_isDemoMode) {
                return MainFellowshipScaffold(state: _fellowshipState);
              }
              if (!_hasCompletedOnboarding) {
                return FellowshipOnboardingScreen(
                  state: _fellowshipState,
                  onFinish: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_completed_onboarding_tour_v1', true);
                    } catch (_) {}
                    if (mounted) {
                      setState(() {
                        _hasCompletedOnboarding = true;
                        _openRegisterAfterOnboarding = true;
                      });
                    }
                  },
                  onSignIn: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('has_completed_onboarding_tour_v1', true);
                    } catch (_) {}
                    if (mounted) {
                      setState(() {
                        _hasCompletedOnboarding = true;
                        _openRegisterAfterOnboarding = false;
                      });
                    }
                  },
                );
              }
              if (_openRegisterAfterOnboarding) {
                return RegisterScreen(
                  state: _fellowshipState,
                  onRegisterSuccess: () {
                    if (mounted) {
                      setState(() {
                        _openRegisterAfterOnboarding = false;
                      });
                    }
                  },
                  onSignInTap: () {
                    if (mounted) {
                      setState(() {
                        _openRegisterAfterOnboarding = false;
                      });
                    }
                  },
                );
              }
              return LoginScreen(
                state: _fellowshipState,
                onLoginSuccess: () {
                  setState(() {});
                },
                onSkipDemo: () {
                  setState(() {
                    _isDemoMode = true;
                  });
                },
              );
            },
          ),
        );
      },
    );
  }
}

class MainFellowshipScaffold extends StatefulWidget {
  final FellowshipState state;

  const MainFellowshipScaffold({super.key, required this.state});

  @override
  State<MainFellowshipScaffold> createState() => _MainFellowshipScaffoldState();
}

class _MainFellowshipScaffoldState extends State<MainFellowshipScaffold> {
  int _studentTabIndex = 0;
  int _adminTabIndex = 0;
  int _coordinatorTabIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(MainFellowshipScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListenableBuilder(
          listenable: widget.state,
          builder: (context, _) => StudentQrScannerScreen(state: widget.state),
        ),
      ),
    );
  }


  void _openNotificationsModal(BuildContext context, bool isAdmin) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final alert = state.latestEmergencyBroadcast;
    final pendingCount = state.pendingApprovals.length;
    final volunteerCount = state.volunteerApplications.where((a) => a.status == ApplicationStatus.pending).length;
    final apptCount = state.myConfessionAppointments.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.notifications_active, color: primaryAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Fellowship Alerts & Notices',
                          style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alert != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.crimson.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.campaign, color: AppTheme.crimson, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(alert.title, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Text(alert.description, style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Live General Announcements
                        ...state.announcements.take(4).map((ann) {
                          final isUrgent = ann['isUrgent'] == true;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (isUrgent ? AppTheme.crimson : primaryAccent).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isUrgent ? Icons.warning_amber_rounded : Icons.campaign_outlined,
                                  color: isUrgent ? AppTheme.crimson : primaryAccent,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ann['title']?.toString() ?? 'Announcement',
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          if (ann['category'] != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: primaryAccent.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                ann['category'].toString(),
                                                style: TextStyle(color: primaryAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ann['content']?.toString() ?? '',
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Live Department Broadcasts
                        ...state.departmentBroadcasts.take(4).map((bcast) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.mark_chat_unread_outlined, color: primaryAccent, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              bcast.title,
                                              style: TextStyle(
                                                color: theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          if (bcast.departmentId.isNotEmpty)
                                            Text(
                                              bcast.departmentId,
                                              style: TextStyle(color: primaryAccent, fontSize: 10, fontWeight: FontWeight.w600),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        bcast.body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // Sunday Divine Liturgy regular notice
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.church_outlined, color: primaryAccent, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Upcoming Sunday Divine Liturgy', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text('St. Mary\'s Orthodox Church • Liturgy starts at 6:00 AM (12:00 LT)', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isAdmin) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.azure.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, color: AppTheme.azure, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '$pendingCount student registrations & $volunteerCount department applications require admin review.',
                                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (apptCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.emerald, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'You have active Confession Father counseling appointments. Check your Prep & Checklist tab.',
                                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 14),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserGuideScreen(state: widget.state, onOpenScanner: _openQrScanner),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 18),
                    label: const Text(
                      'User Guide & Manual • የተጠቃሚ መመሪያ',
                      style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isAdmin = state.activeRole == UserRole.admin;
    final isCoordinator = state.activeRole == UserRole.volunteerCoordinator;

    final theme = AppTheme.getTheme(state.currentThemePalette);

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Experience Switcher Bar (Hidden for regular students in production; visible for Admin or when Dev Mode is toggled)
            if (state.canSwitchRoles)
              ExperienceSwitcherBanner(state: state),

            // Authentic Orthodox Header Bar
            OrthodoxHeader(
              state: state,
              title: isAdmin
                  ? 'WCU Management'
                  : isCoordinator
                      ? 'Coordinator Portal'
                      : 'Wachamo University Fellowship',
              subtitle: isAdmin
                  ? 'Admin Portal • ${state.activeRole.displayName}'
                  : isCoordinator
                      ? (state.currentUser.coordinatorProfile?.departmentNameAmharic ?? 'Department Coordinator')
                      : 'Welcome, ${state.currentUser.fullName.trim().isEmpty ? "Fellow" : state.currentUser.fullName.trim().split(' ').first}',
              showQrIcon: true,
              onQrTap: _openQrScanner,
              onNotificationTap: () => _openNotificationsModal(context, isAdmin),
              onProfileTap: () {
                if (isAdmin) {
                  EditProfileModal.show(context, widget.state);
                } else if (isCoordinator) {
                  setState(() => _coordinatorTabIndex = 3);
                } else {
                  setState(() => _studentTabIndex = 4);
                }
              },
            ),

            // User-Facing Error Boundary Banner
            if (state.lastErrorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.crimson.withValues(alpha: 0.45)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.crimson, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.lastErrorMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: state.clearError,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Dismiss', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                    ),
                  ],
                ),
              ),

            // Main Body Content
            Expanded(
              child: isAdmin
                  ? _buildAdminBody()
                  : isCoordinator
                      ? _buildCoordinatorBody()
                      : _buildStudentBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isAdmin
          ? _buildAdminBottomNav(theme)
          : isCoordinator
              ? _buildCoordinatorBottomNav(theme)
              : _buildStudentBottomNav(theme),
      ),
    );
  }

  // ----------------------------------------------------
  // STUDENT EXPERIENCE NAVIGATION & SCREENS
  // ----------------------------------------------------
  Widget _buildStudentBody() {
    switch (_studentTabIndex) {
      case 0:
        return StudentHomeScreen(
          state: widget.state,
          onNavigateTab: (index) => setState(() => _studentTabIndex = index),
          onOpenScanner: _openQrScanner,
        );
      case 1:
        return StudentFamilyScreen(state: widget.state);
      case 2:
        return StudentRoadmapScreen(
          state: widget.state,
          onOpenScanner: _openQrScanner,
        );
      case 3:
        return StudentLibraryScreen(state: widget.state);
      case 4:
        return StudentProfileScreen(state: widget.state);
      default:
        return StudentHomeScreen(
          state: widget.state,
          onNavigateTab: (index) => setState(() => _studentTabIndex = index),
          onOpenScanner: _openQrScanner,
        );
    }
  }

  Widget _buildStudentBottomNav(ThemeData theme) {
    final unselectedColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65) ?? AppTheme.slateMuted;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        currentIndex: _studentTabIndex,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: unselectedColor,
        onTap: (index) => setState(() => _studentTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.home, color: theme.colorScheme.primary),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline, color: unselectedColor),
            activeIcon: Icon(Icons.people, color: theme.colorScheme.primary),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.timeline, color: theme.colorScheme.primary),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.account_circle, color: theme.colorScheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // ADMIN MANAGEMENT DASHBOARD NAVIGATION & SCREENS
  // ----------------------------------------------------
  Widget _buildAdminBody() {
    switch (_adminTabIndex) {
      case 0:
        return AdminDashboardScreen(
          state: widget.state,
          onOpenFamilyMatching: () => setState(() => _adminTabIndex = 1),
          onOpenLiveAttendance: () => setState(() => _adminTabIndex = 2),
          onOpenApprovals: () => setState(() => _adminTabIndex = 3),
        );
      case 1:
        return AdminFamilyMatchingScreen(
          state: widget.state,
          onBackPressed: () => setState(() => _adminTabIndex = 0),
        );
      case 2:
        return AdminLiveAttendanceScreen(
          state: widget.state,
          onBackPressed: () => setState(() => _adminTabIndex = 0),
        );
      case 3:
        return AdminApprovalsScreen(
          state: widget.state,
          onBackPressed: () => setState(() => _adminTabIndex = 0),
        );
      case 4:
        return AdminMediaCurriculumScreen(
          state: widget.state,
          onBackPressed: () => setState(() => _adminTabIndex = 0),
        );
      default:
        return AdminDashboardScreen(
          state: widget.state,
          onOpenFamilyMatching: () => setState(() => _adminTabIndex = 1),
          onOpenLiveAttendance: () => setState(() => _adminTabIndex = 2),
          onOpenApprovals: () => setState(() => _adminTabIndex = 3),
        );
    }
  }

  Widget _buildAdminBottomNav(ThemeData theme) {
    final unselectedColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65) ?? AppTheme.slateMuted;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        currentIndex: _adminTabIndex.clamp(0, 4),
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: unselectedColor,
        onTap: (index) => setState(() => _adminTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.dashboard, color: theme.colorScheme.primary),
            label: 'Dash',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.hub, color: theme.colorScheme.primary),
            label: 'Matching',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2, color: unselectedColor),
            activeIcon: Icon(Icons.qr_code_2, color: theme.colorScheme.primary),
            label: 'Live QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.verified_user, color: theme.colorScheme.primary),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.library_add, color: theme.colorScheme.primary),
            label: 'Publish',
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // COORDINATOR EXPERIENCE NAVIGATION & SCREENS
  // ----------------------------------------------------
  Widget _buildCoordinatorBody() {
    switch (_coordinatorTabIndex) {
      case 0:
        return CoordinatorHubScreen(state: widget.state);
      case 1:
        return StudentRoadmapScreen(
          state: widget.state,
          onOpenScanner: _openQrScanner,
        );
      case 2:
        return StudentLibraryScreen(state: widget.state);
      case 3:
        return StudentProfileScreen(state: widget.state);
      default:
        return CoordinatorHubScreen(state: widget.state);
    }
  }

  Widget _buildCoordinatorBottomNav(ThemeData theme) {
    final unselectedColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65) ?? AppTheme.slateMuted;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        currentIndex: _coordinatorTabIndex.clamp(0, 3),
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: unselectedColor,
        onTap: (index) => setState(() => _coordinatorTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.hub, color: theme.colorScheme.primary),
            label: 'Coord Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.timeline, color: theme.colorScheme.primary),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined, color: unselectedColor),
            activeIcon: Icon(Icons.account_circle, color: theme.colorScheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
