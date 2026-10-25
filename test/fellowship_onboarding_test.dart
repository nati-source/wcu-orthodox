import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/onboarding/fellowship_onboarding_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FellowshipOnboardingScreen: Full Interactive Flow & Wizard Test', (tester) async {
    final state = FellowshipState();
    bool finished = false;
    bool signedIn = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppThemePalette.midnightFellowship),
        home: FellowshipOnboardingScreen(
          state: state,
          onFinish: () => finished = true,
          onSignIn: () => signedIn = true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Slide 1: Spiritual Family & Mentorship
    expect(find.text('SPIRITUAL FAMILY & MENTORSHIP'), findsOneWidget);
    expect(find.text('— መዝሙር ፻፴፪፥፩ • Psalm 133:1'), findsOneWidget);
    expect(find.text('ወንድሞች'), findsOneWidget);
    expect(find.text('በኅብረት'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue -> Slide 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 2. Verify Slide 2: Serve & Grow
    expect(find.text('SERVE & GROW'), findsOneWidget);
    expect(find.text('1 PETER 4:10 • ፩ ጴጥሮስ ፬፥፲'), findsOneWidget);
    expect(find.text('CONFESSOR FATHERS & PATRISTICS • የንስሐ አባትና ነገረ አበው'), findsOneWidget);

    // Tap Continue -> Slide 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 3. Verify Slide 3: Campus Fellowship Life
    expect(find.text('CAMPUS FELLOWSHIP LIFE'), findsOneWidget);
    expect(find.text('የዕለቱ ስንክሳር፣ ቅዳሴና የንግሥ ጉዞ'), findsOneWidget);
    expect(find.text('ቅዱስ ያሬድ (St. Yared) • የሰንበት መዝሙርና ዲጂታል ላይብረሪ'), findsOneWidget);

    // Tap audio play button in preview
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    // Pause audio so animation controller stops before pumpAndSettle
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tap Continue -> Slide 4
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 4. Verify Slide 4: Made for WCU Fellows
    expect(find.text('MADE FOR WCU FELLOWS'), findsOneWidget);
    expect(find.text('Set up my Fellowship'), findsOneWidget);

    // Tap Set up my Fellowship -> Transitions to Wizard Step 1: FOCUS
    await tester.tap(find.text('Set up my Fellowship'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR FOCUS'), findsOneWidget);
    expect(find.text('Choose your first fellowship path.'), findsOneWidget);

    // Select Education & Apostolic ministry
    await tester.tap(find.text('Education & Apostolic (ትምህርት)'));
    await tester.pumpAndSettle();

    // Tap Continue -> Wizard Step 2: ALERTS
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('FELLOWSHIP ALERTS'), findsOneWidget);
    expect(find.text('Liturgy & Fellowship Reminders'), findsOneWidget);

    // Tap Continue -> Wizard Step 3: SACRED LOOK
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR SACRED LOOK'), findsOneWidget);
    expect(find.text('ዮሐንስ ፩:፲፬ • John 1:14 — ቅዱስ ዮሐንስ ወንጌላዊ'), findsOneWidget);

    // Tap Axumite Emerald palette swatch
    await tester.tap(find.text('Axumite Emerald'));
    await tester.pumpAndSettle();

    // Tap Enter Fellowship
    await tester.tap(find.text('Enter Fellowship • ወደ ግቢ ጉባኤ ግባ'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(signedIn, isFalse);
    expect(state.currentThemePalette, equals(AppThemePalette.axumiteEmerald));
    state.dispose();
  });

  testWidgets('FellowshipOnboardingScreen: Compact Mobile Viewport 320x680 Zero Overflow Test', (tester) async {
    final state = FellowshipState();

    tester.view.physicalSize = const Size(320, 680);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(AppThemePalette.midnightFellowship),
        home: FellowshipOnboardingScreen(
          state: state,
          onFinish: () {},
          onSignIn: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify slide 1 renders cleanly without overflow on 320px
    expect(tester.takeException(), isNull);
    state.dispose();
  });
}
