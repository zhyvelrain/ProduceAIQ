/// Selection of the best result across several photos of the SAME produce item.
///
/// WHY THIS EXISTS
/// ---------------
/// The app allows up to 4 photos of one item (the "multi-angle capture
/// protocol"). Originally each photo was judged entirely on its own: if photo 1
/// scored below the 75% acceptance threshold the user was simply asked for
/// another photo, and if the LAST photo still fell short the item was treated as
/// unrecognised -- even when an earlier photo had scored much higher.
///
/// That threw away evidence the app had already collected. Four looks at the
/// same fruit are four independent judgements; the strongest of them is a
/// better answer than whichever one happened to be taken last.
///
/// WHAT IT DOES
/// ------------
/// Remembers every attempt's prediction and, when no photo cleared the
/// threshold, reports the most confident attempt instead of the final one. The
/// threshold, the gap rule, the disambiguation screen and the unrecognised
/// fallback are all unchanged -- only which attempt they are applied to changes.
///
/// WHAT IT DELIBERATELY DOES NOT DO
/// --------------------------------
/// It does NOT average the probability vectors. Measured on 398 degraded
/// four-photo sets against the real TFLite model, arithmetic averaging scored
/// 66.8% versus 96.0% for the most-confident-attempt selection: averaging pulls
/// confidence toward the middle, which pushes results back under the 75%
/// threshold and turns acceptable scans into retries. See paper_results/ in the
/// project for the experiment.
library;

import 'produce_classifier.dart';

/// Picks the most confident prediction across [attempts].
///
/// "Most confident" means the highest top-1 score, which is what the acceptance
/// threshold is compared against. Ties keep the earliest attempt, so behaviour
/// stays deterministic.
///
/// Returns null only when [attempts] is empty.
Prediction? bestOfAttempts(List<List<Prediction>> attempts) {
  Prediction? best;
  for (final predictions in attempts) {
    if (predictions.isEmpty) continue;
    final top = predictions.first;
    if (best == null || top.confidence > best.confidence) {
      best = top;
    }
  }
  return best;
}

/// The full prediction list of the most confident attempt.
///
/// The gap rule needs the runner-up as well as the winner, so the whole ranked
/// list of the winning attempt is returned rather than just its top entry.
List<Prediction> bestAttemptPredictions(List<List<Prediction>> attempts) {
  List<Prediction>? best;
  for (final predictions in attempts) {
    if (predictions.isEmpty) continue;
    if (best == null ||
        predictions.first.confidence > best.first.confidence) {
      best = predictions;
    }
  }
  return best ?? const <Prediction>[];
}
