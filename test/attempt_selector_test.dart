import 'package:flutter_test/flutter_test.dart';

import 'package:produceaiq/ml/attempt_selector.dart';
import 'package:produceaiq/ml/produce_classifier.dart';

/// Helper: a ranked prediction list from (label, confidence) pairs.
List<Prediction> preds(List<(String, double)> pairs) => [
      for (final (label, conf) in pairs) Prediction(label, conf),
    ];

void main() {
  group('bestAttemptPredictions', () {
    test('returns the highest-confidence attempt', () {
      final attempts = [
        preds([('mango', 0.40), ('papaya', 0.30)]),
        preds([('papaya', 0.71), ('mango', 0.20)]),
        preds([('mango', 0.55), ('papaya', 0.40)]),
      ];
      final best = bestAttemptPredictions(attempts);
      expect(best.first.label, 'papaya');
      expect(best.first.confidence, 0.71);
    });

    test('returns the whole ranked list, not just the top entry', () {
      // The gap rule needs the runner-up, so the full list must survive.
      final attempts = [
        preds([('mango', 0.30), ('papaya', 0.29), ('sitaw', 0.10)]),
        preds([('papaya', 0.80), ('mango', 0.15)]),
      ];
      final best = bestAttemptPredictions(attempts);
      expect(best.length, 2);
      expect(best[1].label, 'mango');
    });

    test('is empty when there are no attempts', () {
      expect(bestAttemptPredictions(const []), isEmpty);
    });

    test('ignores empty attempts', () {
      final attempts = [
        <Prediction>[],
        preds([('mango', 0.50)]),
      ];
      expect(bestAttemptPredictions(attempts).first.label, 'mango');
    });

    test('keeps the earliest attempt on a tie, so behaviour is deterministic',
        () {
      final attempts = [
        preds([('mango', 0.60)]),
        preds([('papaya', 0.60)]),
      ];
      expect(bestAttemptPredictions(attempts).first.label, 'mango');
    });

    test('a later attempt must strictly beat the best to win', () {
      final attempts = [
        preds([('mango', 0.90)]),
        preds([('papaya', 0.89)]),
      ];
      expect(bestAttemptPredictions(attempts).first.label, 'mango');
    });
  });

  group('bestOfAttempts', () {
    test('returns the single most confident prediction', () {
      final attempts = [
        preds([('mango', 0.40)]),
        preds([('papaya', 0.88)]),
      ];
      final best = bestOfAttempts(attempts);
      expect(best, isNotNull);
      expect(best!.label, 'papaya');
    });

    test('is null when nothing was classified', () {
      expect(bestOfAttempts(const []), isNull);
    });
  });

  group('integration: the fallback the app relies on', () {
    test('four weak photos resolve to the strongest one', () {
      // Mirrors the real scenario: no photo clears the 0.75 threshold, so
      // today's app would judge only the LAST photo (0.41) and give up. The
      // selector must surface attempt 2 instead.
      final attempts = [
        preds([('mango', 0.38), ('papaya', 0.30)]),
        preds([('mango', 0.74), ('papaya', 0.20)]),
        preds([('papaya', 0.52), ('mango', 0.44)]),
        preds([('mango', 0.41), ('sitaw', 0.35)]),
      ];
      final best = bestAttemptPredictions(attempts);
      expect(best.first.label, 'mango');
      expect(best.first.confidence, 0.74);
      expect(best.first.confidence, greaterThan(attempts.last.first.confidence),
          reason: 'the fallback must beat judging only the final photo');
    });

    test('does not change which class a clear win reports', () {
      // When a photo already clears the threshold the app short-circuits and
      // never consults this code, so the selector must not "improve" a result
      // that was already accepted.
      final attempts = [
        preds([('mango', 0.95), ('papaya', 0.02)]),
      ];
      expect(bestAttemptPredictions(attempts).first.label, 'mango');
    });
  });
}
