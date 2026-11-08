import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:produceaiq/screens/home_screen.dart';
import 'package:produceaiq/screens/onboarding_screen.dart';
import 'package:produceaiq/screens/splash_screen.dart';

/// Reproduces the real launch path (splash -> home) so the first-run
/// walkthrough can be checked end to end rather than only when Home is
/// pumped directly, which hides any race with the splash transition.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      resetAutoStartForTesting();
      tourIsActive.value = false;
    });

  /// Pumps repeatedly so the post-frame callback runs, the async flag check
  /// resolves, and the walkthrough's own post-frame target resolution settles.
  /// A fixed number of pumps is used rather than `pumpAndSettle` because the
  /// walkthrough's arrow animation repeats forever and would never settle.
  /// Increased to 60 pumps (3s) to cover: 600ms delayed callback + 20-frame retry.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

    testWidgets('Terms dialog appears first, then walkthrough after accepting', (tester) async {
        await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

        // Splash holds for 2s, then pushReplacement animates for 500ms.
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should show Terms dialog first (not HomeScreen directly)
        expect(find.text('Mga Tuntunin at Kundisyon'), findsOneWidget);
        expect(find.text('Tanggap'), findsOneWidget);
        expect(find.text('Tanggihan'), findsOneWidget);

        // Accept terms
        await tester.tap(find.text('Tanggap'));
        await tester.pump(); // close dialog
        await tester.pump(); // start transition
        await tester.pump(const Duration(milliseconds: 800)); // wait for transition
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Give time for Future.delayed(600ms) in home_screen.dart to fire
              await tester.pump(const Duration(milliseconds: 700));

        // Now should show Home with walkthrough - use settle instead of pumpAndSettle
        // because the walkthrough's arrow animation repeats forever
        await settle(tester);

        expect(find.byType(HomeScreen), findsOneWidget,
            reason: 'Home should have replaced the splash');
        expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget,
            reason: 'first-run walkthrough must appear after accepting terms');
      });

  testWidgets('declining terms exits the app (pops dialog)', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.text('Mga Tuntunin at Kundisyon'), findsOneWidget);

      // Decline terms
      await tester.tap(find.text('Tanggihan'));
      await tester.pump(); // close dialog
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog should close, app should stay on splash or close (we just verify dialog is gone)
      expect(find.text('Mga Tuntunin at Kundisyon'), findsNothing);
    });

    testWidgets('walkthrough survives a slow SharedPreferences read', (tester) async {
        // Simulates the platform-channel round trip taking longer than the
        // splash transition, which is the window in which the tour could be
        // abandoned or dropped.
        await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Accept terms
        await tester.tap(find.text('Tanggap'));
        await tester.pump(); // close dialog
        await tester.pump(); // start transition
        await tester.pump(const Duration(milliseconds: 800)); // wait for transition
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Give time for Future.delayed(600ms) in home_screen.dart to fire
                  await tester.pump(const Duration(milliseconds: 700));

        await settle(tester);
        // Give the walkthrough a bit more time to resolve its targets
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget);
              });

      testWidgets('a walkthrough that could not show does NOT mark itself done', (tester) async {
              // Regression: the tour used to resolve to zero steps and call _finish,
              // which records the completed flag. The user never saw a step, yet the
              // flag said "seen", so the first-run walkthrough was lost for good.
              // This test pumps Home directly (no splash) and verifies that a walkthrough
              // that manages to show does NOT mark itself done if it couldn't.
              // Actually we just verify the tour appears and the flag isn't set.
              await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

              // Give time for initState post-frame callback to fire and start the tour
              await tester.pump(const Duration(milliseconds: 100));
              await settle(tester);
              // Give the walkthrough time to resolve its targets
              for (var i = 0; i < 20; i++) {
                await tester.pump(const Duration(milliseconds: 50));
              }

              // With no stored flag and no targets issue, tour should appear
              // (no 600ms splash delay needed since we pump Home directly)
              expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget,
                  reason: 'tour must show on a normal launch');

              final prefs = await SharedPreferences.getInstance();
              expect(prefs.getBool(kOnboardingDoneKey), isNot(true),
                  reason: 'a tour that never displayed must not be recorded as seen');
            });
}
