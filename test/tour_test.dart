import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:produceaiq/screens/home_screen.dart';
import 'package:produceaiq/screens/how_it_works_screen.dart';
import 'package:produceaiq/screens/onboarding_screen.dart';
import 'package:produceaiq/screens/scanner_screen.dart';
import 'package:produceaiq/screens/tour_targets.dart';

/// Pumps the real Home screen inside a MaterialApp and waits for the first-run
/// walkthrough to appear.
Future<void> pumpHome(WidgetTester tester) async {
  // Reset the auto-start flag so each test gets a fresh walkthrough.
  resetAutoStartForTesting();
  tourIsActive.value = false;
  await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
  await settle(tester);
}

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

/// Like [settle] but long enough for an animated route transition to finish --
/// popping back to Home is animated, so a short settle leaves the old screen
/// still on top.
Future<void> settleRoute(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // First run: no stored flag.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tourIsActive.value = false;
  });

  group('TourTargets', () {
    testWidgets('rectOf returns null for an unmounted key instead of throwing',
        (tester) async {
      final orphan = GlobalKey();
      expect(TourTargets.rectOf(orphan), isNull);
    });

    testWidgets('rectOf returns real bounds once a widget is mounted',
        (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(key: key, width: 40, height: 20),
          ),
        ),
      );
      final rect = TourTargets.rectOf(key);
      expect(rect, isNotNull);
      expect(rect!.width, 40);
      expect(rect.height, 20);
    });
  });

  group('first-run walkthrough', () {
    testWidgets('starts automatically on Home and shows step 1', (tester) async {
          await pumpHome(tester);
          expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget);
          expect(find.text('Maligayang pagdating sa ProduceAIQ'), findsOneWidget);
        });

    testWidgets('a fresh install shows it even if the stored flag is corrupt',
        (tester) async {
      // A stored value of the wrong type makes SharedPreferences.getBool throw.
      // The walkthrough must still appear: reporting "already seen" on a read
      // failure is what would silently swallow the first-run walkthrough.
      SharedPreferences.setMockInitialValues(<String, Object>{
              kOnboardingDoneKey: 'corrupt-not-a-bool',
            });

            await pumpHome(tester);
            expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget,
                reason: 'first-run walkthrough must survive a storage read failure');
          });

    testWidgets('does NOT start when the completed flag is already set',
        (tester) async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{kOnboardingDoneKey: true},
      );
      await pumpHome(tester);
      expect(find.textContaining('Hakbang'), findsNothing);
    });

    testWidgets('shows all steps and links the last one to the Guide',
                (tester) async {
              await pumpHome(tester);

              // Step 1 -> 2 via Next (Susunod).
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 2 ng 7'), findsOneWidget);
              expect(find.text('Simula \u2014 Mag-scan Button'), findsOneWidget);

              // Step 2 -> 3
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 3 ng 7'), findsOneWidget);
              expect(find.text('Simula \u2014 Pagsisimula ng Scan'), findsOneWidget);

              // Step 3 -> 4
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 4 ng 7'), findsOneWidget);
              expect(find.text('Mga Tuntunin \u2014 Terms & Conditions'), findsOneWidget);

              // Step 4 -> 5
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 5 ng 7'), findsOneWidget);
              expect(find.text('Gabay \u2014 Buong Walkthrough'), findsOneWidget);

              // Step 5 -> 6
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 6 ng 7'), findsOneWidget);
              expect(find.text('Settings \u2014 Account at Theme'), findsOneWidget);

              // Step 6 -> 7 (final step)
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 7 ng 7'), findsOneWidget);
              expect(find.text('Handa ka na'), findsOneWidget);
              expect(find.text('Buksan ang Gabay'), findsOneWidget);
              // Skip on final step shows "Tapusin"
              expect(find.text('Tapusin'), findsOneWidget);
            });

    testWidgets('tapping the real scan tab advances instead of scanning',
                (tester) async {
              await pumpHome(tester);

              // Move to step 2, whose target is the scanButton.
              await tester.tap(find.text('Susunod'));
              await settle(tester);
              expect(find.textContaining('Hakbang 2 ng 7'), findsOneWidget);

              final rect = TourTargets.rectOf(TourTargets.scanButton);
              expect(rect, isNotNull, reason: 'scan button should be on screen');

              // Press the real control's centre.
              await tester.tapAt(rect!.center);
              await settle(tester);

              // Advanced to step 3
              expect(find.textContaining('Hakbang 3 ng 7'), findsOneWidget);
            });

    testWidgets('Back returns to the previous step', (tester) async {
          await pumpHome(tester);
          await tester.tap(find.text('Susunod'));
          await settle(tester);
          expect(find.textContaining('Hakbang 2 ng 7'), findsOneWidget);

          await tester.tap(find.text('Bumalik'));
          await settle(tester);
          expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget);
        });

    testWidgets('Skip closes the walkthrough and stores the flag',
        (tester) async {
      await pumpHome(tester);
      expect(find.textContaining('Hakbang'), findsOneWidget);

      // On step 1 (not final), Skip button says "Laktawan"
      await tester.tap(find.text('Laktawan'));
      await settle(tester);

      expect(find.textContaining('Hakbang'), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingDoneKey), isTrue);
    });

    testWidgets('targets really are the live Home controls', (tester) async {
              await pumpHome(tester);
              expect(TourTargets.rectOf(TourTargets.scanCard), isNotNull);
              expect(TourTargets.rectOf(TourTargets.scanButton), isNotNull);
              expect(TourTargets.rectOf(TourTargets.scanTab), isNotNull);
              expect(TourTargets.rectOf(TourTargets.termsTab), isNotNull);
              expect(TourTargets.rectOf(TourTargets.guideTab), isNotNull);
              expect(TourTargets.rectOf(TourTargets.settingsTab), isNotNull);
            });

    testWidgets('final step opens the Guide module', (tester) async {
              await pumpHome(tester);
              // Advance to final step (step 7)
              for (var i = 0; i < 6; i++) {
                await tester.tap(find.text('Susunod'));
                await settle(tester);
              }
              expect(find.text('Buksan ang Gabay'), findsOneWidget);

              await tester.tap(find.text('Buksan ang Gabay'));
              await settleRoute(tester);
              expect(find.byType(HowItWorksScreen), findsOneWidget);
            });
  });

  group('replay from another screen', () {
      testWidgets('Guide screen replay tile returns Home, starts the walkthrough, and its '
                  'final step opens the Guide', (tester) async {
                // Already seen once, so the walkthrough must NOT auto-start.
                SharedPreferences.setMockInitialValues(
                  <String, Object>{kOnboardingDoneKey: true},
                );
                await pumpHome(tester);
                expect(find.textContaining('Hakbang'), findsNothing);

                await tester.tapAt(TourTargets.rectOf(TourTargets.guideTab)!.center);
                await settleRoute(tester);
                expect(find.byType(HowItWorksScreen), findsOneWidget);

                // The replay tile in Guide/HowItWorksScreen - uses "Ulitin ang Panimulang Gabay"
                final start = find.text('Ulitin ang Panimulang Gabay');
                await tester.ensureVisible(start);
                await settle(tester);
                await tester.tap(start);
                await settleRoute(tester);

                expect(find.byType(HowItWorksScreen), findsNothing,
                    reason: 'replay must return to Home first');
                expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget,
                    reason: 'replay must actually start the walkthrough');

                // Advance through all 6 steps to reach the final step (step 7)
                for (var i = 0; i < 6; i++) {
                  await tester.tap(find.text('Susunod'));
                  await settle(tester);
                }
                await tester.tap(find.text('Buksan ang Gabay'));
                await settleRoute(tester);
                expect(find.byType(HowItWorksScreen), findsOneWidget);
              });
    });

  group('lifecycle', () {
    testWidgets('closes when another screen is pushed over Home, and stays '
        'replayable afterwards', (tester) async {
      await pumpHome(tester);
      expect(find.textContaining('Hakbang'), findsOneWidget);

      // Something pushes a route on top of Home while the tour is open.
      final nav = Navigator.of(tester.element(find.byType(HomeScreen)));
      nav.push(MaterialPageRoute(builder: (_) => const ScannerScreen()));
      await settleRoute(tester);

      expect(find.byType(ScannerScreen), findsOneWidget);
      expect(find.textContaining('Hakbang'), findsNothing,
          reason: 'the tour must not hover over an unrelated screen');

      // Back on Home, the walkthrough must still be startable -- a stale
      // "active" entry would make every later replay silently do nothing.
      nav.pop();
      await settleRoute(tester);

      final started = startGuidedTour(tester.element(find.byType(HomeScreen)));
                  await settleRoute(tester);
                  expect(find.textContaining('Hakbang 1 ng 7'), findsOneWidget,
                      reason: 'the walkthrough must still be replayable');

                  // Advance to the final step first (6 taps to reach step 7)
                  for (var i = 0; i < 6; i++) {
                    await tester.tap(find.text('Susunod'));
                    await settle(tester);
                  }
                  expect(find.text('Buksan ang Gabay'), findsOneWidget);

                  // Now tap "Tapusin" (Skip) on the final step
                  await tester.tap(find.text('Tapusin'));
                  await settleRoute(tester);
                  expect(await started, isFalse);
          });

    testWidgets('system back closes the walkthrough without marking it done',
        (tester) async {
      await pumpHome(tester);
      expect(find.textContaining('Hakbang'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.textContaining('Hakbang'), findsNothing,
          reason: 'back should dismiss the walkthrough');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(kOnboardingDoneKey), isNot(true),
          reason: 'abandoning via back is not "completed"');
    });
  });
}
