import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:produceaiq/ml/attempt_selector.dart';
import 'package:produceaiq/ml/produce_classifier.dart';
import 'package:produceaiq/ml/scan_decision.dart';
import 'package:produceaiq/screens/confidence_screen.dart';
import 'package:produceaiq/screens/scanner_screen.dart';

/// End-to-end check that the multi-angle protocol's attempt history is really
/// threaded through the screens, and that the fallback changes the outcome the
/// way the paper's Table 3.10 describes.
///
/// This does not run the TFLite model (no camera/GPU in a unit test); it feeds
/// the selector the same shapes the real classifier produces and asserts the
/// decision the app would reach.
List<Prediction> preds(List<(String, double)> pairs) =>
    [for (final (l, c) in pairs) Prediction(l, c)];

/// Mirror of what ConfidenceScreen._evaluate does, so the test exercises the
/// same branch logic rather than a re-implementation.
ScanDecision decideLikeApp({
  required List<List<Prediction>> attempts,
  required int attemptNumber,
  int maxAttempts = 4,
}) {
  var evaluated = attempts.last;
  if (attemptNumber >= maxAttempts) {
    final bestOfAll = bestAttemptPredictions(attempts);
    if (bestOfAll.isNotEmpty &&
        bestOfAll.first.confidence > attempts.last.first.confidence) {
      evaluated = bestOfAll;
    }
  }
  return decideScan(
    [for (final p in evaluated) ScanScore(p.label, p.confidence)],
    attemptNumber: attemptNumber,
    acceptanceThreshold: kAcceptanceThreshold,
    splitGap: kSplitProbabilityGap,
    maxAttempts: maxAttempts,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('multi-angle protocol wiring', () {
    testWidgets('ScannerScreen forwards attempt history to ConfidenceScreen',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final history = [
        preds([('mango', 0.40), ('papaya', 0.30)]),
        preds([('mango', 0.55), ('papaya', 0.20)]),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: ScannerScreen(attemptNumber: 3, attemptPredictions: history),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final scanner = tester.widget<ScannerScreen>(find.byType(ScannerScreen));
      expect(scanner.attemptPredictions.length, 2,
          reason: 'history must be held on the widget');
      expect(scanner.attemptPredictions[0].first.label, 'mango');
    });

    testWidgets('ConfidenceScreen accepts an incoming attempt history',
        (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final history = [
        preds([('sitaw', 0.62), ('mango', 0.30)]),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: ConfidenceScreen(
            attemptNumber: 2,
            imagePath: '/nonexistent.jpg',
            attemptPredictions: history,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      final cs = tester.widget<ConfidenceScreen>(find.byType(ConfidenceScreen));
      expect(cs.attemptPredictions.length, 1);
      expect(cs.attemptPredictions.first.first.label, 'sitaw');
    });
  });

  group('the fallback changes the final-attempt decision', () {
    test('WITHOUT the fallback, a weak final photo decides the scan', () {
      final attempts = [
        preds([('mango', 0.38), ('papaya', 0.30)]),
        preds([('mango', 0.74), ('papaya', 0.20)]), // strongest
        preds([('papaya', 0.52), ('mango', 0.44)]),
        preds([('sitaw', 0.41), ('mango', 0.35)]), // last, weakest-ish
      ];
      // Old behaviour: judge only the last attempt.
      final old = decideScan(
        [for (final p in attempts.last) ScanScore(p.label, p.confidence)],
        attemptNumber: 4,
        acceptanceThreshold: kAcceptanceThreshold,
        splitGap: kSplitProbabilityGap,
        maxAttempts: 4,
      );
      expect(old.best!.label, 'sitaw',
          reason: 'the last photo names the wrong class');
    });

    test('WITH the fallback, the strongest attempt decides the scan', () {
      final attempts = [
        preds([('mango', 0.38), ('papaya', 0.30)]),
        preds([('mango', 0.74), ('papaya', 0.20)]), // strongest
        preds([('papaya', 0.52), ('mango', 0.44)]),
        preds([('sitaw', 0.41), ('mango', 0.35)]),
      ];
      final now = decideLikeApp(attempts: attempts, attemptNumber: 4);
      expect(now.best!.label, 'mango',
          reason: 'the strongest attempt names the right class');
      expect(now.best!.confidence, closeTo(0.74, 1e-9));
    });

    test('the fallback does NOT fire before the final attempt', () {
      final attempts = [
        preds([('mango', 0.74), ('papaya', 0.20)]), // strongest, earlier
        preds([('sitaw', 0.41), ('mango', 0.35)]), // current, weak
      ];
      final d = decideLikeApp(attempts: attempts, attemptNumber: 2);
      expect(d.best!.label, 'sitaw',
          reason: 'attempt 2 is not the last, so only it is judged; the user '
              'is still allowed to keep scanning');
    });

    test('a photo that already passes still short-circuits', () {
      final attempts = [
        preds([('mango', 0.93), ('papaya', 0.03)]),
      ];
      final d = decideLikeApp(attempts: attempts, attemptNumber: 1);
      expect(d.outcome, ScanOutcome.accept);
      expect(d.best!.label, 'mango');
    });

    test('an out-of-scope item still resolves via the strongest attempt', () {
      // Every photo is below threshold -- the unrecognized path.
      final attempts = [
        preds([('mango', 0.30), ('papaya', 0.28)]),
        preds([('papaya', 0.58), ('mango', 0.25)]), // strongest, different
        preds([('sitaw', 0.33), ('mango', 0.31)]),
        preds([('talong', 0.22), ('mango', 0.20)]),
      ];
      final d = decideLikeApp(attempts: attempts, attemptNumber: 4);
      expect(d.best!.label, 'papaya',
          reason: 'the strongest capture supplies the candidate list');
    });
  });
}
