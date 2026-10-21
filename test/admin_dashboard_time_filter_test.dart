import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/admin/admin_dashboard_screen.dart';

void main() {
  testWidgets(
    'Admin Dashboard: Uses a truthful current snapshot without fake history',
    (WidgetTester tester) async {
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

      expect(find.text('DATABASE'), findsWidgets);
      expect(find.text('NO SESSION HISTORY'), findsOneWidget);
      expect(
        find.text('Attendance Distribution • Attendance History'),
        findsOneWidget,
      );
      expect(
        find.text('Latest Session Attendance Breakdown'),
        findsOneWidget,
      );
      expect(find.text('No Current Follow-ups'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.text('This Week'), findsNothing);
      expect(find.text('Sarah Jenkins'), findsNothing);
      expect(find.text('78.0%'), findsNothing);
      expect(find.text('Database Test Fixtures • የዳታቤዝ መሞከሪያ'), findsNothing);

      state.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
