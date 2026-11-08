import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:produceaiq/screens/home_screen.dart';
import 'result_screen.dart';
import 'disambiguation_screen.dart';
import 'general_match_screen.dart';
import '../data/produce_repository.dart';
import '../data/submission.dart';
import '../data/submission_service.dart';
import '../ml/attempt_selector.dart';
import '../ml/produce_classifier.dart';
import '../ml/scan_decision.dart';
import '../ml/freshness_assessor.dart';
import '../ml/scan_preprocess.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

/// Multi-Angle Confidence Progress Screen.
///
/// Styled with full-screen ambient botanical background, green pill header badge,
/// and responsive leafy background painter matching ScannerScreen.
class ConfidenceScreen extends StatefulWidget {
  final int attemptNumber;
  final List<double> history;
  final String imagePath;
  final List<String> imagePathHistory;
  final List<String> remainingQueue;

  /// The full ranked predictions of every earlier attempt, oldest first.
  ///
  /// Carried forward so that when no photo clears the acceptance threshold, the
  /// most confident attempt can be used instead of whichever one happened to be
  /// last. See lib/ml/attempt_selector.dart.
  final List<List<Prediction>> attemptPredictions;

  /// Optional notice to surface during the loading/classifying phase,
  /// e.g. when a gallery upload was truncated to the max allowed images.
  /// Only meant to be passed in once, right after the picker screen, it is
  /// not carried forward on subsequent attempts.
  final String? uploadNotice;

  const ConfidenceScreen({
    super.key,
    this.attemptNumber = 1,
    this.history = const [],
    required this.imagePath,
    this.imagePathHistory = const [],
    this.remainingQueue = const [],
    this.attemptPredictions = const [],
    this.uploadNotice,
  });

  @override
  State<ConfidenceScreen> createState() => _ConfidenceScreenState();
}

class _ConfidenceScreenState extends State<ConfidenceScreen> {
  static const double _acceptanceThreshold = kAcceptanceThreshold;
  static const double _splitProbabilityGap = kSplitProbabilityGap;
  static const int _maxAttempts = kMaxAttempts;

  bool _isClassifying = true;
  String? _errorMessage;
  List<Prediction> _predictions = [];
  late List<double> _history;
  late List<String> _imagePathHistory;

  /// Every attempt's ranked predictions, oldest first, including this one.
  late List<List<Prediction>> _attemptPredictions;

  /// The attempt the displayed result came from, when it was not the latest.
  /// Non-null only after the best-of-attempts fallback has been applied.
  int? _selectedAttemptNumber;

  /// The single shared decode for this scan's photo. Producing runs
  /// classify() and freshnessAssessor off ONE decode+isolate instead of
  /// the old two-three (see scan_preprocess.dart for why that was the
  /// root of the post-shutter freeze).
  ScanPreprocessResult? _preprocessed;

  @override
  void initState() {
    super.initState();
    _runInference();
  }

  Future<void> _runInference() async {
    if (!produceClassifier.isLoaded) {
      setState(() {
        _errorMessage =
            'The AI model is not loaded, so this scan cannot run.\n\n'
            'Last load error: ${produceClassifier.lastLoadError ?? "unknown -- check that loadModel() was called and awaited in main.dart"}';
        _isClassifying = false;
      });
      return;
    }

    try {
      // ONE decode of the photo, shared by produce + freshness below.
      final bytes = await File(widget.imagePath).readAsBytes();
      final preprocessed = await preprocessScanImage(bytes);
      if (!mounted) return;

      final results = await produceClassifier.classifyPreprocessed(preprocessed);
      if (!mounted) return;

      setState(() {
        _predictions = results;
        _attemptPredictions = [...widget.attemptPredictions, results];
        _history = [...widget.history, results.first.confidence];
        _imagePathHistory = [...widget.imagePathHistory, widget.imagePath];
        _isClassifying = false;
        _preprocessed = preprocessed;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Classification failed: $e';
        _isClassifying = false;
      });
    }
  }

  Future<void> _evaluate() async {
    if (_predictions.isEmpty || !mounted) return;

    // On the LAST attempt, if this photo did not clear the threshold either,
    // fall back to the most confident of all the attempts instead of judging
    // only whichever photo happened to be last. Four looks at the same item are
    // four independent judgements, and the strongest of them is the better
    // answer. Earlier attempts are untouched, so the "try again" prompt and the
    // existing short-circuit on success behave exactly as before.
    var evaluated = _predictions;
    final bool isFinalAttempt = widget.attemptNumber >= _maxAttempts;
    if (isFinalAttempt) {
      final bestOfAll = bestAttemptPredictions(_attemptPredictions);
      if (bestOfAll.isNotEmpty &&
          bestOfAll.first.confidence > _predictions.first.confidence) {
        evaluated = bestOfAll;
        _selectedAttemptNumber =
            _attemptPredictions.indexWhere((a) => identical(a, bestOfAll)) + 1;
      }
    }

    // All of the accept / disambiguate / retry logic lives in
    // lib/ml/scan_decision.dart so it can be unit-tested.
    final d = decideScan(
      [for (final p in evaluated) ScanScore(p.label, p.confidence)],
      attemptNumber: widget.attemptNumber,
      acceptanceThreshold: _acceptanceThreshold,
      splitGap: _splitProbabilityGap,
      maxAttempts: _maxAttempts,
    );

    // 'other' means the model could not place the photo in any of the 10
    // curated classes. Per the user's requirement the red "not one of the 10
    // produces" prompt must appear on the HOME page, not on a dedicated Result
    // screen. We return to Home and let HomeScreen render the red prompt.
    if (d.outcome == ScanOutcome.accept && d.best!.label.toLowerCase() == 'other') {
      // The model is confident this is NOT one of the 10 curated classes.
      // The red prompt is shown on Home (by design), but the scan is still
      // forwarded to the admin review queue so genuine out-of-catalog items
      // reach the retraining pipeline. Fire-and-forget: never delay leaving
      // this screen, and never let a submission failure block the prompt.
      unawaited(_submitUnrecognizedSilently(evaluated));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(showOtherRedPrompt: true),
        ),
      );
      return;
    }

    if (d.outcome == ScanOutcome.accept) {
      final best = d.best!;
      // Freshness comes from the photo the accepted result actually came from,
      // which is not necessarily the most recent one after the fallback.
      final sourcePath = _pathForSelectedAttempt();
      FreshnessGrade? grade;
      bool freshnessFromRealModel = false;
      final preprocessed = _preprocessed;
      if (preprocessed != null &&
          _selectedAttemptNumber == null) {
        // Reuses the ONE shared decode -- no second readAsBytes or
        // decode for freshness.
        try {
          final (g, _, isRealModel) =
              await freshnessAssessor.assessPreprocessed(preprocessed);
          grade = g;
          freshnessFromRealModel = isRealModel;
        } catch (_) {
          grade = null;
        }
      } else {
        try {
          final (g, _, isRealModel) =
              await freshnessAssessor.assess(File(sourcePath));
          grade = g;
          freshnessFromRealModel = isRealModel;
        } catch (_) {
          grade = null;
        }
      }
      if (!mounted) return;

      // Record history HERE, at the one point a scan is actually accepted.
      // (ResultScreen used to do this in build(), which duplicated the entry
      // on every rebuild and every open-from-history.) Storing the canonical
      // id and the accepted photo path also makes history entries richer.
      final historyItem = produceRepository.get(best.label);
      if (historyItem != null) {
        await HistoryService.instance.add(
          ScanHistoryItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            produceId: historyItem.id,
            produceName: historyItem.commonName,
            confidence: best.confidence,
            freshnessGrade: grade?.name,
            imagePath: sourcePath,
            timestamp: DateTime.now(),
          ),
        );
      }
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            produceId: best.label,
            confidence: best.confidence,
            freshnessGrade: grade,
            freshnessFromRealModel: freshnessFromRealModel,
          ),
        ),
      );
      return;
    }

    if (d.outcome == ScanOutcome.disambiguate) {
      final best = d.best!;
      final runnerUp = d.runnerUp!;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DisambiguationScreen(
            candidateProduceId: best.label,
            candidateConfidence: best.confidence,
            lookalikeLabel: runnerUp.label,
            lookalikeConfidence: runnerUp.confidence,
            // The photo the shown candidates came from -- after the
            // best-of-attempts fallback that is an earlier attempt, not this
            // one, and the disambiguation screen displays this image.
            imagePath: _pathForSelectedAttempt(),
            imagePathHistory: _imagePathHistory,
            attemptHistory: _history,
          ),
        ),
      );
      return;
    }

    if (d.outcome == ScanOutcome.unrecognized) {
      _handleUnrecognized(evaluated);
    }
    // ScanOutcome.tryAgain: stay on this screen so the user can scan again.
  }

  void _handleUnrecognized(List<Prediction> evaluated) {
      if (!mounted) return;
      // This is the Module 5 entry point: GeneralMatchScreen auto-submits the
      // scan to the admin review queue on open. Before this, the screen was
      // never navigated to, so unrecognized scans never reached an admin.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => GeneralMatchScreen(
            imagePath: _pathForSelectedAttempt(),
            imagePathHistory: _imagePathHistory,
            topGuesses: _topGuesses(evaluated),
          ),
        ),
        (route) => false,
      );
    }

  /// Fire-and-forget submission used when the model confidently lands on
  /// OTHER. The user still gets HomeScreen's red prompt; this only makes
  /// sure the scan is not lost from the admin/retraining queue.
  Future<void> _submitUnrecognizedSilently(List<Prediction> evaluated) async {
    try {
      await submissionService.submit(
        Submission(
          deviceNotes:
              'Awtomatikong naipadala: model was confident this is not one of '
              'the 10 curated classes (best guesses: '
              '${_topGuesses(evaluated).join(", ")})',
          topGuesses: _topGuesses(evaluated),
          submissionType: 'unrecognized',
        ),
        images: _imagePathHistory.map((p) => File(p)).toList(),
      );
    } catch (_) {
      // Non-fatal by design: a failed upload must never block the red prompt.
    }
  }

  /// The model's best non-OTHER guesses, most confident first.
  List<String> _topGuesses(List<Prediction> evaluated) {
    final guesses = evaluated
        .where((p) => p.label.toUpperCase() != 'OTHER')
        .take(3)
        .map((p) => p.label)
        .toList();
    if (guesses.isEmpty && evaluated.isNotEmpty) {
      return [evaluated.first.label];
    }
    return guesses;
  }

  /// The photo file the currently displayed result came from.
  ///
  /// Normally this attempt's own photo. After the best-of-attempts fallback it
  /// is the earlier attempt's photo, so freshness is judged on the same image
  /// the produce label came from.
  String _pathForSelectedAttempt() {
    final n = _selectedAttemptNumber;
    if (n == null) return widget.imagePath;
    final idx = n - 1;
    if (idx >= 0 && idx < _imagePathHistory.length) {
      return _imagePathHistory[idx];
    }
    return widget.imagePath;
  }

  void _scanAgain() {
    if (widget.remainingQueue.isNotEmpty) {
      final nextPath = widget.remainingQueue.first;
      final rest = widget.remainingQueue.skip(1).toList();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfidenceScreen(
            attemptNumber: widget.attemptNumber + 1,
            history: _history,
            imagePath: nextPath,
            imagePathHistory: _imagePathHistory,
            remainingQueue: rest,
            attemptPredictions: _attemptPredictions,
          ),
        ),
      );
      return;
          }

          Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
        }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isClassifying) {
      return Scaffold(
        body: _LeafyBackground(
          isDark: isDark,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.uploadNotice != null) ...[
                      _UploadNoticeCard(message: widget.uploadNotice!),
                      const SizedBox(height: 28),
                    ],
                    const CircularProgressIndicator(
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: isDark
              ? const Color(0xFF091F15).withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.95),
          title: const Text('Error'),
        ),
        body: _LeafyBackground(
          isDark: isDark,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final top1 = _predictions[0];
    final percent = (top1.confidence * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF091F15).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? MarketPalette.textPrimary(context) : const Color(0xFF047857),
        ),
        // Styled Green Pill Badge Header Title
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10B981).withValues(alpha: 0.18)
                : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pagsusuri ng AI',
                style: AppText.display(
                  size: 15,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _LeafyBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In-Body Section Header
                const _SectionHeader(),
                const SizedBox(height: 16),
                // Main Glass/Card Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF091F15).withValues(alpha: 0.85)
                        : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attempt ${widget.attemptNumber} of $_maxAttempts',
                            style: AppText.display(
                              size: 18,
                              color: MarketPalette.textPrimary(context),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '$percent%',
                              style: AppText.display(
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kunan sa ibang anggulo para mas tama',
                        style: AppText.body(
                          size: 12,
                                                    color: MarketPalette.textBody(context),
                                                  ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                                              '${top1.label[0].toUpperCase()}${top1.label.substring(1)}, $percent% confidence',
                                              style: AppText.body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: MarketPalette.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: top1.confidence,
                          minHeight: 10,
                          backgroundColor: isDark
                              ? const Color(0xFF102A1C)
                              : const Color(0xFFD1FAE5),
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(
                        height: 1,
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Attempt history',
                        style: AppText.body(
                          size: 14,
                          weight: FontWeight.bold,
                          color: MarketPalette.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._history.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                                              e.key == _history.length - 1
                                                                  ? Icons.check_circle_rounded
                                                                  : Icons.radio_button_unchecked_rounded,
                                                              size: 16,
                                                              color: e.key == _history.length - 1
                                                                  ? const Color(0xFF10B981)
                                                                  : MarketPalette.textBody(context),
                                                            ),
                              const SizedBox(width: 8),
                              Text(
                                'Attempt ${e.key + 1}: ${(e.value * 100).toStringAsFixed(0)}%',
                                style: AppText.body(
                                  size: 13,
                                  weight: e.key == _history.length - 1
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: MarketPalette.textPrimary(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                                                      child: _InfoChip(
                                                        label: 'Kailangan 75% kumpiyansa',
                                                        value: '${(_acceptanceThreshold * 100).toStringAsFixed(0)}%',
                                                        isDark: isDark,
                                                      ),
                                                    ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoChip(
                              label: 'Limitasyon ng Pagsubok',
                              value: '$_maxAttempts',
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (widget.attemptNumber < _maxAttempts)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: _scanAgain,
                            child: Text(
                                                          widget.remainingQueue.isNotEmpty
                                                              ? 'Subukan ang sumunod\nna larawan →'
                                                              : 'Iposisyon muli ang\nprodukto at i‑scan ulit',
                                                          textAlign: TextAlign.center,
                                                        ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Large notice card shown above the loading spinner for as long as the
/// classification is running, e.g. when a gallery upload was truncated
/// to the max allowed images. Unlike a timed dialog, this stays fully
/// visible for the entire loading phase since it's just part of the tree.
class _UploadNoticeCard extends StatelessWidget {
  final String message;
  const _UploadNoticeCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF102A1C) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.display(
              size: 16,
              color: isDark ? Colors.white : const Color(0xFF047857),
            ).copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

/// In-Body Section Header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Antas ng Kumpirmasyon',
              style: AppText.display(
                size: 18,
                color: MarketPalette.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
                  'Suriin ang kumpiyansa ng AI sa pagtukoy ng iyong produkto.',
                  style: AppText.body(
                    size: 12,
                    color: MarketPalette.textBody(context),
                  ).copyWith(height: 1.3),
                ),
      ],
    );
  }
}

/// Styled Info Chip
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF102A1C).withValues(alpha: 0.5)
            : const Color(0xFFD1FAE5).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                      label,
                      style: AppText.body(
                        size: 11,
                        color: MarketPalette.textBody(context),
                      ),
                    ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w700,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen ambient botanical background wrapper with responsive leaf pattern.
class _LeafyBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _LeafyBackground({
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDark
        ? const [
            Color(0xFF091F15),
            Color(0xFF05170F),
            Color(0xFF020C07),
          ]
        : const [
            Color(0xFFEAF5EC),
            Color(0xFFDBEFE1),
            Color(0xFFCCE8D4),
          ];

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: CustomPaint(
          painter: _LeafPatternPainter(isDark: isDark),
          child: child,
        ),
      ),
    );
  }
}

/// Custom Vector Painter to draw ambient, clearly visible leaves across top, middle, and bottom.
class _LeafPatternPainter extends CustomPainter {
  final bool isDark;

  _LeafPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = isDark
          ? const Color(0xFF34D399).withValues(alpha: 0.14)
          : const Color(0xFF059669).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isDark
          ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
          : const Color(0xFF10B981).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Decorative top-right leaf
    final path1 = Path();
    path1.moveTo(size.width * 0.72, 0);
    path1.quadraticBezierTo(
        size.width, size.height * 0.08, size.width, size.height * 0.22);
    path1.quadraticBezierTo(
        size.width * 0.62, size.height * 0.18, size.width * 0.72, 0);
    path1.close();
    canvas.drawPath(path1, fillPaint);
    canvas.drawPath(path1, strokePaint);

    // Decorative middle-left leaf
    final path2 = Path();
    path2.moveTo(0, size.height * 0.42);
    path2.quadraticBezierTo(
        size.width * 0.38, size.height * 0.46, size.width * 0.28, size.height * 0.60);
    path2.quadraticBezierTo(
        size.width * 0.05, size.height * 0.56, 0, size.height * 0.42);
    path2.close();
    canvas.drawPath(path2, fillPaint);
    canvas.drawPath(path2, strokePaint);

    // Decorative bottom-right leaf
    final path3 = Path();
    path3.moveTo(size.width, size.height * 0.72);
    path3.quadraticBezierTo(
        size.width * 0.62, size.height * 0.82, size.width * 0.75, size.height * 0.95);
    path3.quadraticBezierTo(
        size.width * 0.95, size.height * 0.88, size.width, size.height * 0.72);
    path3.close();
    canvas.drawPath(path3, fillPaint);
    canvas.drawPath(path3, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}