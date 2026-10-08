import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/auth/login_screen.dart';
import 'package:wcu_orthodox/views/student/student_profile_screen.dart';

void main() {
  testWidgets('Password Reset Dialog: Opens smoothly without overflow, displays test accounts and spam instructions', (WidgetTester tester) async {
    final state = FellowshipState();

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: LoginScreen(
            onLoginSuccess: () {},
            onSkipDemo: () {},
            state: state,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Find and tap Forgot Password link
    final forgotBtn = find.textContaining('Forgot Password');
    expect(forgotBtn, findsOneWidget);
    await tester.tap(forgotBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Dialog opened with no overflow exceptions
    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('የይለፍ ቃል መልሶ ማግኛ'), findsOneWidget);
    expect(find.textContaining('Test Accounts Credentials:'), findsOneWidget);

    // Verify Autofill buttons are present
    expect(find.textContaining('Autofill Admin'), findsOneWidget);
    expect(find.textContaining('Autofill Student'), findsOneWidget);

    // Tap cancel
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Dialog should be dismissed
    expect(find.text('Reset Password'), findsNothing);

    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('Student Profile Change Password: Opens dialog without overflow and handles validation', (WidgetTester tester) async {
    final state = FellowshipState();

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: StudentProfileScreen(state: state),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Find Change Password button and scroll to it if needed
    final changePwBtn = find.textContaining('Change Password');
    await tester.ensureVisible(changePwBtn);
    expect(changePwBtn, findsOneWidget);
    await tester.tap(changePwBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Dialog contents
    expect(find.text('Change Password'), findsWidgets);
    expect(find.text('የይለፍ ቃል ቀይር'), findsOneWidget);
    expect(find.textContaining('Current Password'), findsOneWidget);
    expect(find.textContaining('min 6 characters'), findsOneWidget);
    expect(find.textContaining('Confirm New Password'), findsOneWidget);
    expect(find.textContaining('Forgot current password?'), findsOneWidget);

    // Tap Update Password with empty inputs -> shows validation error
    final updateBtn = find.text('Update Password');
    expect(updateBtn, findsOneWidget);
    await tester.tap(updateBtn);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Please enter your current password.'), findsOneWidget);

    // Close dialog
    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.tap(cancelBtn);
    await tester.pump(const Duration(milliseconds: 300));

    state.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
