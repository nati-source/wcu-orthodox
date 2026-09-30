import 'package:flutter/material.dart';
import 'models/app_models.dart';
import 'state/fellowship_state.dart';
import 'theme/app_theme.dart';
import 'widgets/experience_switcher_banner.dart';
import 'widgets/orthodox_header.dart';
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
import 'firebase_options.dart';
import 'views/auth/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const WcuOrthodoxApp());
}

class WcuOrthodoxApp extends StatefulWidget {
  const WcuOrthodoxApp({super.key});

  @override
  State<WcuOrthodoxApp> createState() => _WcuOrthodoxAppState();
}

class _WcuOrthodoxAppState extends State<WcuOrthodoxApp> {
  final FellowshipState _fellowshipState = FellowshipState();
  final AuthService _authService = AuthService();
  bool _isDemoMode = false;
  String? _syncedUid;

  @override
  void dispose() {
    _fellowshipState.dispose();
    super.dispose();
  }

  void _syncUserProfile(dynamic user) async {
    if (user == null || _syncedUid == user.uid) return;
    _syncedUid = user.uid;

    if (user.displayName != null && (user.displayName as String).trim().isNotEmpty) {
      _fellowshipState.updateCurrentUserProfile(
        id: user.uid,
        fullName: (user.displayName as String).trim(),
      );
    }

    try {
      final profile = await _authService.getUserProfile(user.uid);
      if (profile != null && mounted) {
        final roleStr = profile['role'] as String?;
        UserRole role = UserRole.student;
        if (roleStr != null) {
          for (final r in UserRole.values) {
            if (r.name == roleStr) {
              role = r;
              break;
            }
          }
        }
        _fellowshipState.updateCurrentUserProfile(
          id: user.uid,
          fullName: profile['fullName'] ?? user.displayName ?? 'Student Fellow',
          baptismalName: profile['baptismalName'],
          phoneNumber: profile['phoneNumber'],
          department: profile['department'],
          academicYear: profile['academicYear'] is int ? profile['academicYear'] : int.tryParse(profile['academicYear']?.toString() ?? '1'),
          batchYear: profile['batchYear']?.toString(),
          role: role,
          assignedFamilyId: profile['assignedFamilyId'] ?? profile['familyId'] ?? profile['family'] ?? profile['assignedFamily'],
        );
        _fellowshipState.autoSeedIfEmpty();
      }
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fellowshipState,
      builder: (context, _) {
        return MaterialApp(
          title: 'WCU Orthodox Fellowship',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(_fellowshipState.currentThemePalette),
          home: StreamBuilder(
            stream: _authService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null) {
                _syncUserProfile(user);
                return MainFellowshipScaffold(state: _fellowshipState);
              }
              if (_isDemoMode) {
                return MainFellowshipScaffold(state: _fellowshipState);
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
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
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
                          color: primaryAccent.withOpacity(0.15),
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
              if (alert != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.crimson.withOpacity(0.5)),
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
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(14),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.azure.withOpacity(0.4)),
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
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.emerald.withOpacity(0.4)),
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
              const SizedBox(height: 16),
            ],
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

    final theme = Theme.of(context);

    return Scaffold(
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
                      ? '${state.currentUser.coordinatorProfile?.departmentNameAmharic ?? "Department Coordinator"}'
                      : 'Welcome, ${state.currentUser.fullName.split(' ').first}',
              showQrIcon: true,
              onQrTap: _openQrScanner,
              onNotificationTap: () => _openNotificationsModal(context, isAdmin),
            ),

            // User-Facing Error Boundary Banner
            if (state.lastErrorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.crimson.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.crimson.withOpacity(0.45)),
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
          ? _buildAdminBottomNav()
          : isCoordinator
              ? _buildCoordinatorBottomNav()
              : _buildStudentBottomNav(),
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

  Widget _buildStudentBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _studentTabIndex,
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: AppTheme.slateMuted,
        onTap: (index) => setState(() => _studentTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: theme.colorScheme.primary),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people, color: theme.colorScheme.primary),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline, color: theme.colorScheme.primary),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
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
        );
    }
  }

  Widget _buildAdminBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _adminTabIndex.clamp(0, 4),
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: AppTheme.slateMuted,
        onTap: (index) => setState(() => _adminTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: theme.colorScheme.primary),
            label: 'Dash',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.hub_outlined),
            activeIcon: Icon(Icons.hub, color: theme.colorScheme.primary),
            label: 'Matching',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.qr_code_2),
            activeIcon: Icon(Icons.qr_code_2, color: theme.colorScheme.primary),
            label: 'Live QR',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user, color: theme.colorScheme.primary),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_add_outlined),
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

  Widget _buildCoordinatorBottomNav() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _coordinatorTabIndex.clamp(0, 3),
        backgroundColor: theme.scaffoldBackgroundColor,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: AppTheme.slateMuted,
        onTap: (index) => setState(() => _coordinatorTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.hub_outlined),
            activeIcon: Icon(Icons.hub, color: theme.colorScheme.primary),
            label: 'Coord Hub',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline, color: theme.colorScheme.primary),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book, color: theme.colorScheme.primary),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle, color: theme.colorScheme.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
