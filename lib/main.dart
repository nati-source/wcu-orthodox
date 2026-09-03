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
import 'views/student/student_registration_screen.dart';
import 'views/admin/admin_dashboard_screen.dart';
import 'views/admin/admin_family_matching_screen.dart';
import 'views/admin/admin_live_attendance_screen.dart';
import 'views/admin/admin_approvals_screen.dart';
import 'views/admin/admin_media_curriculum_screen.dart';

void main() {
  runApp(const WcuOrthodoxApp());
}

class WcuOrthodoxApp extends StatefulWidget {
  const WcuOrthodoxApp({super.key});

  @override
  State<WcuOrthodoxApp> createState() => _WcuOrthodoxAppState();
}

class _WcuOrthodoxAppState extends State<WcuOrthodoxApp> {
  final FellowshipState _fellowshipState = FellowshipState();

  @override
  void dispose() {
    _fellowshipState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WCU Orthodox Fellowship',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AnimatedBuilder(
        animation: _fellowshipState,
        builder: (context, _) {
          return MainFellowshipScaffold(state: _fellowshipState);
        },
      ),
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

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentQrScannerScreen(state: widget.state),
      ),
    );
  }

  void _openRegistrationModal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentRegistrationScreen(
          state: widget.state,
          onRegistered: () {
            setState(() {
              _studentTabIndex = 0;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isAdmin = state.activeRole == UserRole.admin;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Experience Switcher Bar (For testing both Student & Admin workflows)
            ExperienceSwitcherBanner(state: state),

            // Authentic Orthodox Header Bar
            OrthodoxHeader(
              state: state,
              title: isAdmin ? 'WCU Management' : 'Wachamo University Fellowship',
              subtitle: isAdmin
                  ? 'Admin Portal • ${state.activeRole.displayName}'
                  : 'Welcome, ${state.currentUser.fullName.split(' ').first}',
              showQrIcon: true,
              onQrTap: _openQrScanner,
              onNotificationTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isAdmin
                        ? 'Admin Alerts: 4 pending student registrations require approval.'
                        : 'Fellowship Alerts: Upcoming Sunday Divine Liturgy in 2h 15m.'),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                );
              },
            ),

            // Main Body Content
            Expanded(
              child: isAdmin
                  ? _buildAdminBody()
                  : _buildStudentBody(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isAdmin
          ? _buildAdminBottomNav()
          : _buildStudentBottomNav(),
      floatingActionButton: !isAdmin && _studentTabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openRegistrationModal,
              backgroundColor: const Color(0xFFD4690B),
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
              label: const Text(
                'Registration Form',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            )
          : null,
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
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        border: Border(top: BorderSide(color: Color(0xFF1E2838), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _studentTabIndex,
        onTap: (index) => setState(() => _studentTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: Color(0xFFF5A65E)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people, color: Color(0xFFF5A65E)),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timeline_outlined),
            activeIcon: Icon(Icons.timeline, color: Color(0xFFF5A65E)),
            label: 'Roadmap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book, color: Color(0xFFF5A65E)),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle, color: Color(0xFFF5A65E)),
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
        return AdminFamilyMatchingScreen(state: widget.state);
      case 2:
        return AdminLiveAttendanceScreen(state: widget.state);
      case 3:
        return AdminApprovalsScreen(state: widget.state);
      case 4:
        return AdminMediaCurriculumScreen(state: widget.state);
      default:
        return AdminDashboardScreen(
          state: widget.state,
          onOpenFamilyMatching: () => setState(() => _adminTabIndex = 1),
          onOpenLiveAttendance: () => setState(() => _adminTabIndex = 2),
        );
    }
  }

  Widget _buildAdminBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0C1017),
        border: Border(top: BorderSide(color: Color(0xFF1E2838), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _adminTabIndex.clamp(0, 4),
        onTap: (index) => setState(() => _adminTabIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard, color: Color(0xFFF5A65E)),
            label: 'Dash',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_outlined),
            activeIcon: Icon(Icons.hub, color: Color(0xFFF5A65E)),
            label: 'Matching',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            activeIcon: Icon(Icons.qr_code_2, color: Color(0xFFF5A65E)),
            label: 'Live QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user, color: Color(0xFFF5A65E)),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_add_outlined),
            activeIcon: Icon(Icons.library_add, color: Color(0xFFF5A65E)),
            label: 'Publish',
          ),
        ],
      ),
    );
  }
}
