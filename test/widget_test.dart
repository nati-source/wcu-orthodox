import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/main.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';

void main() {
  testWidgets('WCU Orthodox App smoke & role switcher test', (WidgetTester tester) async {
    await tester.pumpWidget(const WcuOrthodoxApp());
    await tester.pumpAndSettle();

    // Verify initial Student Header and Liturgy section
    expect(find.text('Wachamo University Fellowship'), findsOneWidget);
    expect(find.text('Upcoming Liturgy'), findsOneWidget);
    expect(find.text('Scan\nAttendance'), findsOneWidget);
    expect(find.text('Fellowship\nFamily'), findsOneWidget);
    expect(find.text('Digital\nLibrary'), findsOneWidget);
  });

  test('FellowshipState logic test: constrained matching and rolling pin check-in', () async {
    final state = FellowshipState();

    expect(state.allStudents.isNotEmpty, true);
    expect(state.families.isNotEmpty, true);

    // Test Smart Matching
    await state.runSmartMatching();
    for (final fam in state.families) {
      expect(fam.memberIds.isNotEmpty, true);
    }

    // Test Check-In with correct PIN
    final activePin = state.activeSession.rollingPin;
    final checkInSuccess = state.checkInStudent(
      studentId: state.currentUser.id,
      enteredPinOrCode: activePin,
      method: AttendanceCheckInMethod.pin,
    );
    expect(checkInSuccess, true);

    // Test Invalid PIN
    final checkInFail = state.checkInStudent(
      studentId: 'usr-random',
      enteredPinOrCode: '000000',
      method: AttendanceCheckInMethod.pin,
    );
    expect(checkInFail, false);
  });
}
