import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/admin/admin_approvals_screen.dart';
import 'package:wcu_orthodox/views/admin/admin_dashboard_screen.dart';
import 'package:wcu_orthodox/views/admin/admin_family_matching_screen.dart';
import 'package:wcu_orthodox/views/admin/admin_live_attendance_screen.dart';
import 'package:wcu_orthodox/views/admin/admin_media_curriculum_screen.dart';
import 'package:wcu_orthodox/views/auth/login_screen.dart';
import 'package:wcu_orthodox/views/auth/register_screen.dart';
import 'package:wcu_orthodox/views/coordinator/coordinator_hub_screen.dart';
import 'package:wcu_orthodox/views/student/student_charity_screen.dart';
import 'package:wcu_orthodox/views/student/student_confessor_screen.dart';
import 'package:wcu_orthodox/views/student/student_family_screen.dart';
import 'package:wcu_orthodox/views/student/student_home_screen.dart';
import 'package:wcu_orthodox/views/student/student_library_screen.dart';
import 'package:wcu_orthodox/views/student/student_liturgical_calendar_screen.dart';
import 'package:wcu_orthodox/views/student/student_mentorship_screen.dart';
import 'package:wcu_orthodox/views/student/student_ministry_screen.dart';
import 'package:wcu_orthodox/views/student/student_pilgrimage_screen.dart';
import 'package:wcu_orthodox/views/student/student_prayer_book_screen.dart';
import 'package:wcu_orthodox/views/student/student_profile_screen.dart';
import 'package:wcu_orthodox/views/student/student_qr_scanner_screen.dart';
import 'package:wcu_orthodox/views/student/student_registration_screen.dart';
import 'package:wcu_orthodox/views/student/student_roadmap_screen.dart';
import 'package:wcu_orthodox/views/student/student_trivia_screen.dart';
import 'package:wcu_orthodox/widgets/experience_switcher_banner.dart';
import 'package:wcu_orthodox/widgets/orthodox_header.dart';

void main() {
  testWidgets('Exhaustive Mobile Viewport Overflow Audit (320px & 360px widths)', (WidgetTester tester) async {
    final state = FellowshipState();

    final List<String> overflowErrors = [];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final fullStr = details.toString();
      if (fullStr.contains('overflowed')) {
        final lines = fullStr.split('\n');
        final relevantLine = lines.firstWhere(
          (l) => l.contains('lib/'),
          orElse: () => details.exceptionAsString(),
        );
        overflowErrors.add('${details.exceptionAsString()} AT $relevantLine');
      }
    };

    Future<void> pumpScreen(String name, Widget child, {Size size = const Size(320, 680)}) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      final beforeCount = overflowErrors.length;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(body: child),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      if (overflowErrors.length > beforeCount) {
        for (int i = beforeCount; i < overflowErrors.length; i++) {
          overflowErrors[i] = '[$name @ ${size.width.toInt()}x${size.height.toInt()}] ${overflowErrors[i]}';
        }
      }
    }

    for (final width in [320.0, 360.0]) {
      final size = Size(width, 680);

      // 1. Auth Screens
      await pumpScreen('LoginScreen', LoginScreen(onLoginSuccess: () {}, onSkipDemo: () {}, state: state), size: size);
      await pumpScreen('RegisterScreen', RegisterScreen(onRegisterSuccess: () {}, state: state), size: size);

      // 2. Header & Switcher Widgets
      state.switchRole(UserRole.admin);
      await pumpScreen('OrthodoxHeader', OrthodoxHeader(state: state, onQrTap: () {}, onNotificationTap: () {}), size: size);
      state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: FellowshipDepartmentConstants.deptEducation);
      await pumpScreen('ExperienceSwitcherBanner', ExperienceSwitcherBanner(state: state), size: size);

      // 3. Student Screens
      state.switchRole(UserRole.student);
      await pumpScreen('StudentHomeScreen', StudentHomeScreen(state: state, onNavigateTab: (_) {}, onOpenScanner: () {}), size: size);
      await pumpScreen('StudentProfileScreen', StudentProfileScreen(state: state), size: size);

      // StudentPilgrimageScreen (Tab 0 & Tab 1)
      await pumpScreen('StudentPilgrimageScreen-Tab0', StudentPilgrimageScreen(state: state), size: size);
      final pilgrimTab1 = find.textContaining('My Digital Passes');
      if (pilgrimTab1.evaluate().isNotEmpty) {
        await tester.tap(pilgrimTab1.first);
        await tester.pump(const Duration(milliseconds: 200));
      }

      // StudentCharityScreen (All 3 Tabs)
      await pumpScreen('StudentCharityScreen-Tab0', StudentCharityScreen(state: state), size: size);
      for (final tabLabel in ['Monthly Dues', 'Emergency Aid']) {
        final tabFinder = find.textContaining(tabLabel);
        if (tabFinder.evaluate().isNotEmpty) {
          await tester.tap(tabFinder.first);
          await tester.pump(const Duration(milliseconds: 200));
          if (overflowErrors.isNotEmpty && !overflowErrors.last.startsWith('[')) {
            overflowErrors[overflowErrors.length - 1] = '[StudentCharityScreen-$tabLabel @ ${width.toInt()}] ${overflowErrors.last}';
          }
        }
      }

      // StudentConfessorScreen (All Tabs)
      await pumpScreen('StudentConfessorScreen', StudentConfessorScreen(state: state), size: size);
      for (final tabLabel in ['My Appointments', 'Spiritual Q&A']) {
        final tabFinder = find.textContaining(tabLabel);
        if (tabFinder.evaluate().isNotEmpty) {
          await tester.tap(tabFinder.first);
          await tester.pump(const Duration(milliseconds: 200));
          if (overflowErrors.isNotEmpty && !overflowErrors.last.startsWith('[')) {
            overflowErrors[overflowErrors.length - 1] = '[StudentConfessorScreen-$tabLabel @ ${width.toInt()}] ${overflowErrors.last}';
          }
        }
      }

      await pumpScreen('StudentFamilyScreen', StudentFamilyScreen(state: state), size: size);
      await pumpScreen('StudentLibraryScreen', StudentLibraryScreen(state: state), size: size);
      await pumpScreen('StudentLiturgicalCalendarScreen', StudentLiturgicalCalendarScreen(state: state), size: size);
      await pumpScreen('StudentMentorshipScreen', StudentMentorshipScreen(state: state), size: size);
      await pumpScreen('StudentMinistryScreen', StudentMinistryScreen(state: state), size: size);
      await pumpScreen('StudentPrayerBookScreen', StudentPrayerBookScreen(state: state), size: size);
      await pumpScreen('StudentQrScannerScreen', StudentQrScannerScreen(state: state), size: size);
      await pumpScreen('StudentRegistrationScreen', StudentRegistrationScreen(state: state, onRegistered: () {}), size: size);
      await pumpScreen('StudentRoadmapScreen', StudentRoadmapScreen(state: state, onOpenScanner: () {}), size: size);
      await pumpScreen('StudentTriviaScreen', StudentTriviaScreen(state: state), size: size);

      // Spiritual Parent role on Family & Roadmap screens
      state.switchRole(UserRole.spiritualParent);
      await pumpScreen('StudentFamilyScreen-ParentRole', StudentFamilyScreen(state: state), size: size);
      await pumpScreen('StudentRoadmapScreen-ParentRole', StudentRoadmapScreen(state: state, onOpenScanner: () {}), size: size);

      // 4. Coordinator Hub across all 10 Departments
      for (final deptId in FellowshipDepartmentConstants.allDepartmentIds) {
        state.switchRole(UserRole.volunteerCoordinator, coordinatorDeptId: deptId);
        await pumpScreen('CoordinatorHub-$deptId', CoordinatorHubScreen(state: state), size: size);
      }

      // 5. Admin Screens
      state.switchRole(UserRole.admin);
      await pumpScreen('AdminDashboardScreen', AdminDashboardScreen(state: state, onOpenFamilyMatching: () {}, onOpenLiveAttendance: () {}), size: size);
      await pumpScreen('AdminApprovalsScreen', AdminApprovalsScreen(state: state), size: size);
      await pumpScreen('AdminFamilyMatchingScreen', AdminFamilyMatchingScreen(state: state), size: size);
      await pumpScreen('AdminLiveAttendanceScreen', AdminLiveAttendanceScreen(state: state), size: size);
      await pumpScreen('AdminMediaCurriculumScreen', AdminMediaCurriculumScreen(state: state), size: size);
    }

    FlutterError.onError = originalOnError;
    await tester.pumpWidget(const SizedBox());
    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();

    if (overflowErrors.isNotEmpty) {
      for (final err in overflowErrors) {
        // ignore: avoid_print
        print('OVERFLOW_LOC: $err');
      }
    }
    expect(overflowErrors, isEmpty);
  });
}
