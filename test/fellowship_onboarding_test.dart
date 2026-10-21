import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wcu_orthodox/models/app_models.dart';
import 'package:wcu_orthodox/state/fellowship_state.dart';
import 'package:wcu_orthodox/theme/app_theme.dart';
import 'package:wcu_orthodox/views/onboarding/fellowship_onboarding_screen.dart';

void main() {
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

    // 1. Verify Slide 1: Light for the Path
    expect(find.text('LIGHT FOR THE PATH'), findsOneWidget);
    expect(find.text('— መዝሙር ፻፲፱:፻፭'), findsOneWidget);
    expect(find.text('መብራት'), findsOneWidget);
    expect(find.text('ብርሃን'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    // Tap Continue -> Slide 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('STUDY DEEPER'), findsOneWidget);
    expect(find.text('JOHN 1:1 • ዮሐንስ ፩:፩'), findsOneWidget);
    expect(find.text("STRONG'S G3056 • ግዕዝ: ቃል"), findsOneWidget);

    // Tap Continue -> Slide 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('EVERY DAY'), findsOneWidget);
    expect(find.text('የዕለቱ ንባብና ስንክሳር'), findsOneWidget);
    expect(find.text('ዮሐንስ ፫ • የቅዳሴ ዝማሬ'), findsOneWidget);

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

    expect(find.text('MADE FOR YOU'), findsOneWidget);
    expect(find.text('Set up my Fellowship'), findsOneWidget);

    // Tap Set up my Fellowship -> Transitions to Wizard Step 1: FOCUS
    await tester.tap(find.text('Set up my Fellowship'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR FOCUS'), findsOneWidget);
    expect(find.text('Choose your first fellowship path.'), findsOneWidget);

    // Select Education & Apostolic ministry
    await tester.tap(find.text('Education & Apostolic (ትምህርት)'));
    await tester.pumpAndSettle();

    // Tap Continue -> Wizard Step 2: DAILY
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR DAILY READING'), findsOneWidget);
    expect(find.text('Daily Reading Reminder'), findsOneWidget);

    // Tap Continue -> Wizard Step 3: SACRED LOOK
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR SACRED LOOK'), findsOneWidget);
    expect(find.text('ዮሐንስ ፩:፲፬ • John 1:14'), findsOneWidget);

    // Tap Axumite Emerald palette swatch
    await tester.tap(find.text('Axumite Emerald'));
    await tester.pumpAndSettle();

    // Tap Enter Fellowship
    await tester.tap(find.text('Enter Fellowship • ወደ ግቢ ጉባኤ ግባ'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
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
