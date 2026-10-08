import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/admin/admin_dashboard_screen.dart';

void main() {
  testWidgets('Admin Dashboard: Toggling Time Filter Dropdown changes all metrics, charts, breakdown, and activities', (WidgetTester tester) async {
    final state = FellowshipState();

    tester.view.physicalSize = const Size(380, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: AdminDashboardScreen(
            state: state,
            onOpenFamilyMatching: () {},
            onOpenLiveAttendance: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Initial State: 'This Week'
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('WEEKLY'), findsOneWidget);
    expect(find.text('This Week Attendance Breakdown'), findsOneWidget);
    expect(find.text('78.0%'), findsOneWidget);
    expect(find.text('Sarah Jenkins'), findsOneWidget);

    // 2. Select 'This Month' from Dropdown
    final dropdownFinder = find.byType(DropdownButton<String>);
    expect(dropdownFinder, findsOneWidget);
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final monthItem = find.text('This Month').last;
    await tester.tap(monthItem);
    await tester.pumpAndSettle();

    // Verify UI updated to 'This Month'
    expect(find.text('MONTHLY'), findsOneWidget);
    expect(find.text('This Month Attendance Breakdown'), findsOneWidget);
    expect(find.text('82.3%'), findsOneWidget);
    expect(find.text('Monthly Fellowship Liturgy'), findsOneWidget);

    // 3. Select 'Semester' from Dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final semesterItem = find.text('Semester').last;
    await tester.tap(semesterItem);
    await tester.pumpAndSettle();

    // Verify UI updated to 'Semester'
    expect(find.text('SEMESTER'), findsOneWidget);
    expect(find.text('Semester Attendance Breakdown'), findsOneWidget);
    expect(find.text('80.2%'), findsOneWidget);
    expect(find.text('Dogma Curriculum Milestone'), findsOneWidget);

    // 4. Select 'Annual' from Dropdown
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();

    final annualItem = find.text('Annual').last;
    await tester.tap(annualItem);
    await tester.pumpAndSettle();

    // Verify UI updated to 'Annual'
    expect(find.text('ANNUAL'), findsOneWidget);
    expect(find.text('Annual Attendance Breakdown'), findsOneWidget);
    expect(find.text('82.8%'), findsOneWidget);
    expect(find.text('Annual General Assembly'), findsOneWidget);

    // 5. Select 'CS Dept' Batch Pill
    final csPill = find.text('CS DEPT');
    expect(csPill, findsOneWidget);
    await tester.tap(csPill);
    await tester.pumpAndSettle();

    // CS Dept has higher attendance (89.2%) and 97 registered students for Annual (84 * 1.15)
    expect(find.text('89.2%'), findsOneWidget);
    expect(find.text('97'), findsOneWidget);

    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
