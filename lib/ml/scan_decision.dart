/// Pure decision logic for what to do after a scan.
///
/// No Flutter / TFLite imports on purpose, so it can be unit-tested with
/// `flutter test` on any computer (see test/scan_decision_test.dart).
library;

enum ScanOutcome {
  /// Confident enough -> go straight to the result.
  accept,

  /// Below the acceptance threshold and the two best real produce classes
  /// are close together -> show the "Alin dito ang tamang item?" screen.
  disambiguate,

  /// Not resolved yet and attempts remain -> let the user scan again.
  tryAgain,

  /// Not resolved after the last attempt -> "unrecognized" flow.
  unrecognized,
}

class ScanScore {
  final String label;
  final double confidence;
  const ScanScore(this.label, this.confidence);
}

class ScanDecision {
  final ScanOutcome outcome;
  final ScanScore? best;
  final ScanScore? runnerUp;
  final double? gap;
  final bool otherWins;

  const ScanDecision(
    this.outcome, {
    this.best,
    this.runnerUp,
    this.gap,
    this.otherWins = false,
  });
}

const double kAcceptanceThreshold = 0.75;
const double kSplitProbabilityGap = 0.15;
const int kMaxAttempts = 4;

ScanDecision decideScan(
  List<ScanScore> predictions, {
  required int attemptNumber,
  double acceptanceThreshold = kAcceptanceThreshold,
  double splitGap = kSplitProbabilityGap,
  int maxAttempts = kMaxAttempts,
}) {
  if (predictions.isEmpty) {
    return const ScanDecision(ScanOutcome.tryAgain);
  }

  final sorted = [...predictions]
    ..sort((a, b) => b.confidence.compareTo(a.confidence));

  // 'other' means "not one of our 10 curated classes". It is never offered
  // as a candidate, so rank only the real produce classes.
  final otherWins = sorted.first.label == 'other';
  final real = sorted.where((p) => p.label != 'other').toList();

  // When 'other' (the model's best guess for "not one of the 10 produces")
  // is on top, accept it and route to the red "not in our catalog" screen.
  // It follows the same acceptance threshold as the other categories
  // (kAcceptanceThreshold, currently 75%), so a low-confidence 'other' keeps
  // the normal retry path.
  final best = otherWins ? sorted.first : (real.isNotEmpty ? real[0] : null);
  final runnerUp =
      otherWins ? null : (real.length > 1 ? real[1] : null);
  final gap = (best != null && runnerUp != null)
      ? best.confidence - runnerUp.confidence
      : null;

  ScanOutcome outcome;
  // Any top guess that clears the acceptance threshold is accepted -- 'other'
  // (not one of the 10 curated classes) stops the user the same as a real
  // class that is above the threshold.
  if (sorted.first.confidence >= acceptanceThreshold) {
    outcome = ScanOutcome.accept;
  } else if (!otherWins && gap != null && gap < splitGap) {
    // Two real classes are close but neither reached the threshold --
    // disambiguate between them. 'other' never disambiguates: when it is the
    // best guess the user needs a clear "not one of our 10" answer, not
    // another choice.
    outcome = ScanOutcome.disambiguate;
  } else if (attemptNumber >= maxAttempts) {
    outcome = ScanOutcome.unrecognized;
  } else {
    outcome = ScanOutcome.tryAgain;
  }

  return ScanDecision(
    outcome,
    best: best,
    runnerUp: runnerUp,
    gap: gap,
    otherWins: otherWins,
  );
}