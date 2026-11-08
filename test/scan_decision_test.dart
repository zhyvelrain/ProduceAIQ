import 'package:flutter_test/flutter_test.dart';
import 'package:produceaiq/ml/scan_decision.dart';

List<ScanScore> scores(Map<String, double> m) =>
    [for (final e in m.entries) ScanScore(e.key, e.value)];

void main() {
  test('papaya 52% vs mango 41% -> disambiguate', () {
    final d = decideScan(
      scores({'papaya': 0.52, 'mango': 0.41, 'banana': 0.04, 'other': 0.03}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.disambiguate);
    expect(d.best!.label, 'papaya');
    expect(d.runnerUp!.label, 'mango');
  });

  test('80% confidence -> accept (75% threshold)', () {
    final d = decideScan(
      scores({'mango': 0.80, 'papaya': 0.12, 'other': 0.08}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.accept);
  });

  test('exactly 75% -> accept (at threshold)', () {
    final d = decideScan(
      scores({'mango': 0.75, 'papaya': 0.20, 'other': 0.05}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.accept);
  });

  test('exactly 74% -> try again (below threshold)', () {
    final d = decideScan(
      scores({'mango': 0.74, 'papaya': 0.20, 'other': 0.06}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.tryAgain);
  });

  test('exactly 90% -> accept', () {
    final d = decideScan(
      scores({'mango': 0.90, 'papaya': 0.10}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.accept);
  });

  test('60% with a far second guess -> try again, then unrecognized on attempt 4', () {
    final probs = scores({'mango': 0.60, 'papaya': 0.20, 'other': 0.20});
    expect(decideScan(probs, attemptNumber: 1).outcome, ScanOutcome.tryAgain);
    expect(decideScan(probs, attemptNumber: 4).outcome, ScanOutcome.unrecognized);
  });

  test('gap of 14 points -> disambiguate', () {
    final d = decideScan(
      scores({'sitaw': 0.50, 'ampalaya': 0.36, 'other': 0.14}),
      attemptNumber: 2,
    );
    expect(d.outcome, ScanOutcome.disambiguate);
  });

  test('"other" sitting between two close real classes no longer blocks disambiguation', () {
    final d = decideScan(
      scores({'mango': 0.40, 'other': 0.35, 'papaya': 0.30}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.disambiguate);
    expect(d.best!.label, 'mango');
    expect(d.runnerUp!.label, 'papaya');
  });

  test("'other' on top needs 75% like other categories", () {
    // 'other' must follow the same 75% rule as the real classes. A low
    // confidence 'other' does NOT stop the user -- it returns tryAgain so
    // the scan can be retried.
    final low = decideScan(
      scores({'other': 0.70, 'mango': 0.15, 'papaya': 0.15}),
      attemptNumber: 1,
    );
    expect(low.outcome, ScanOutcome.tryAgain);

    // At 75% 'other' is accepted just like any other class.
    final high = decideScan(
      scores({'other': 0.75, 'mango': 0.15, 'papaya': 0.10}),
      attemptNumber: 1,
    );
    expect(high.outcome, ScanOutcome.accept);
    expect(high.best!.label, 'other');
  });

  test("'other' between two close real classes never disambiguates", () {
    // 'other' is the best guess but below 90% -- it must not trigger
    // disambiguation either. The user needs a clear "not one of our 10"
    // answer or a retry, never a choice between two real classes.
    final d = decideScan(
      scores({'mango': 0.45, 'other': 0.30, 'papaya': 0.25}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.tryAgain);
  });

  test("'other' between two close real classes is not 'otherWins' (can disambiguate)", () {
    final d = decideScan(
      scores({'mango': 0.40, 'other': 0.35, 'papaya': 0.30}),
      attemptNumber: 1,
    );
    expect(d.outcome, ScanOutcome.disambiguate);
    expect(d.best!.label, 'mango');
    expect(d.runnerUp!.label, 'papaya');
    expect(d.otherWins, false);
  });
}
