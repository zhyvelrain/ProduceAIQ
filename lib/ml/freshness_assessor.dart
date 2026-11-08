import 'dart:io';
import 'dart:typed_data';
import 'freshness_classifier.dart';
import 'freshness_types.dart';
import 'scan_preprocess.dart'
    show ScanPreprocessResult, preprocessScanImage;

// Re-exported so existing `import '../ml/freshness_assessor.dart';`
// lines in result_screen.dart, recipe_screen.dart, confidence_screen.dart,
// and disambiguation_screen.dart keep getting FreshnessGrade without
// needing to change what they import from.
export 'freshness_types.dart';

/// -----------------------------------------------------------------------
/// STATUS: this file now supports TWO modes, and is honest on-screen
/// about which one produced a given result (see result_screen.dart's
/// _FreshnessBadge tooltip):
///
/// 1. REAL trained model (freshnessClassifier, in freshness_classifier.dart)
///    -- used automatically once assets/produce_freshness_model.tflite
///    exists and loads successfully. This is a genuine second CNN,
///    trained the same way as the species classifier (see
///    train_freshness_model.py), on a pooled Unripe/Ripe/Overripe/
///    Rotten dataset (dataset_freshness/ -- pooled across all produce types
///    rather than per-species, see that folder's README.txt for why).
///
/// 2. HEURISTIC fallback (this file's _computeFreshnessHeuristic) -- a
///    deterministic color/blemish rule, NOT a trained model. Used
///    automatically whenever the trained model isn't available (no
///    freshness dataset has been collected/trained yet, or the asset
///    load fails for any reason). This is what's active by default
///    today, since dataset_freshness/ starts empty.
///
/// Both are wired through the same assess() method below so neither
/// confidence_screen.dart nor disambiguation_screen.dart need to know
/// or care which one actually ran -- but the returned grade always
/// carries which source produced it, so the UI can disclose that
/// honestly rather than implying every result came from a trained
/// model.
///
/// DEBUG LOGGING: assess() below prints which path ran on every call
/// (visible in the `flutter run` terminal) -- this is a temporary
/// diagnostic aid, not permanent instrumentation. Once you've
/// confirmed the real model is loading and being used correctly, feel
/// free to remove the three `print(...)` calls below.
/// -----------------------------------------------------------------------

/// The actual pixel-analysis work, as a pure function over an
/// already-decoded sample so it can be unit-tested and -- importantly --
/// run on a sample that was produced by the SHARED decode in
/// scan_preprocess.dart, instead of decoding the photo a second time.
///
/// Takes the 96x96 freshnessSample Float32List (raw 0-255, HWC) that
/// scan_preprocess.dart already built from the one shared decode, so
/// this path costs zero additional image decoding.
(
  FreshnessGrade,
  double,
) _gradeFromSample(Float32List sample) {
  const size = 96; // matches scan_preprocess.dart's kFreshnessSampleSize

  int darkOrBrownPixels = 0;
  int totalPixels = 0;
  double saturationSum = 0;

  // sample is flat HWC: index (y * size + x) * 3 + channel.
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final idx = (y * size + x) * 3;
      final r = sample[idx];
      final g = sample[idx + 1];
      final b = sample[idx + 2];

      // Skip near-white/near-black background pixels (produce is
      // usually photographed against a plain background per the
      // Scanner screen's framing guide overlay).
      final luminance =
          0.299 * r +
          0.587 * g +
          0.114 * b;
      final isBackground =
          luminance >
              235 ||
          (r <
                  15 &&
              g <
                  15 &&
              b <
                  15);
      if (isBackground) continue;

      totalPixels++;

      // "Dark/brown spot" signal: low luminance combined with a
      // brown-ish channel ordering (R > G > B), which is a common
      // visual signature of bruising, browning, or decay across most
      // fruits and vegetables. Used here as a proxy for "rotten".
      final isDarkSpot =
          luminance <
          70;
      final isBrownish =
          r >
              g &&
          g >=
              b &&
          (r -
                  b) >
              15 &&
          luminance <
              140;
      if (isDarkSpot ||
          isBrownish) {
        darkOrBrownPixels++;
      }

      final maxC = [
        r,
        g,
        b,
      ].reduce(
        (
          a,
          v,
        ) => a > v
            ? a
            : v,
      );
      final minC = [
        r,
        g,
        b,
      ].reduce(
        (
          a,
          v,
        ) => a < v
            ? a
            : v,
      );
      final saturation = maxC ==
              0
          ? 0.0
          : (maxC -
                    minC) /
                maxC;
      saturationSum +=
          saturation;
    }
  }

  if (totalPixels ==
      0) {
    // Degenerate image (e.g. solid color capture); default to the
    // middle grade rather than crashing the scan flow.
    return (
      FreshnessGrade.ripe,
      0.5,
    );
  }

  final blemishRatio =
      darkOrBrownPixels /
      totalPixels;
  final avgSaturation =
      saturationSum /
      totalPixels;

  // Thresholds tuned conservatively (favor under- rather than
  // over-flagging spoilage) since this heuristic has not been
  // validated against ground-truth freshness labels.
  //
  // IMPORTANT LIMITATION, stated plainly: this heuristic has only two
  // real signals (blemish ratio, average saturation) to approximate
  // FOUR categories with meaningfully different real-world
  // consequences -- Overripe means "still fine to cook with," Rotten
  // means "throw it away." Color/blemish analysis alone cannot
  // reliably tell those two apart (mold vs. heavy bruising can look
  // similar in a color histogram) -- this heuristic's Rotten output
  // should be treated with real skepticism as a food-safety signal,
  // not a certified reading. The whole point of training the real
  // classifier (freshness_classifier.dart) is to replace this rough
  // approximation with a model that's actually learned the visual
  // difference from labeled examples of both.
  FreshnessGrade grade;
  if (blemishRatio >
      0.30) {
    grade = FreshnessGrade.rotten;
  } else if (blemishRatio >
      0.15) {
    grade = FreshnessGrade.overripe;
  } else if (avgSaturation <
      0.28) {
    grade = FreshnessGrade.unripe;
  } else {
    grade = FreshnessGrade.ripe;
  }

  return (
    grade,
    blemishRatio,
  );
}

class FreshnessAssessor {
  /// Returns a grade plus a raw signal (0.0-1.0) so the UI can show
  /// its reasoning instead of a black-box label, AND whether a real
  /// trained model or the heuristic fallback produced it.
  ///
  /// Tries freshnessClassifier (real trained model) first; falls back
  /// to the color/blemish heuristic if that model isn't loaded (e.g.
  /// no freshness dataset has been trained yet -- the default state
  /// of this project until dataset_freshness/ is populated and
  /// train_freshness_model.py has been run).
  Future<
    (
      FreshnessGrade,
      double,
      bool,
    )
  >
  assessPreprocessed(
    ScanPreprocessResult preprocessed,
  ) async {
    if (freshnessClassifier.isLoaded) {
      try {
        final (
          grade,
          confidence,
        ) = await freshnessClassifier.classifyPreprocessed(
          preprocessed,
        );
        return (
          grade,
          confidence,
          true,
        );
      } catch (_) {
        // Fall through to the heuristic rather than failing the whole
        // scan over a freshness-specific error.
      }
    }

    final (
      grade,
      signal,
    ) = _gradeFromSample(preprocessed.freshnessSample);
    return (
      grade,
      signal,
      false,
    );
  }

  Future<
    (
      FreshnessGrade,
      double,
      bool,
    )
  >
  assess(
    File imageFile,
  ) async {
    final bytes = await imageFile.readAsBytes();
    final preprocessed = await preprocessScanImage(bytes);
    return assessPreprocessed(preprocessed);
  }
}

final freshnessAssessor = FreshnessAssessor();