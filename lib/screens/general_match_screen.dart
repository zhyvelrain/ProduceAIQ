import 'dart:io';
import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../data/submission.dart';
import '../data/submission_service.dart';
import '../theme/app_theme.dart';

/// Shown when ProduceClassifier lands on OTHER and no confident/split match
/// was found -- i.e. the item is genuinely outside the 10 curated classes
/// (e.g. parsley).
///
/// This screen is the entry point of the unrecognized-produce submission
/// workflow (Module 5). It does two things:
///
///   1. Submits the scan to the admin review queue automatically, so the
///      photos and the model's top guesses reach the retraining pipeline
///      without depending on the user noticing a button.
///   2. Tells the user plainly that the item is not one of the ten supported
///      classes.
///
/// It deliberately offers NO nutrition lookup. An earlier version let the
/// user type a name and search the FNRI table for it, but that read as though
/// the app had identified the item when it had not -- the model said "other",
/// and the user was being asked to supply the answer themselves. The
/// submission is the useful outcome here; a manual name search is not.
///
/// The visible "Ipadala para sa Review" button still exists purely as a
/// fallback -- e.g. if the auto-submit couldn't reach Firestore because the
/// device had no connection when this screen opened -- and disables itself
/// once a submission (auto or manual) has actually gone through.
///
/// IMPORTANT: the button is also disabled for the ENTIRE time any submit is
/// in flight (_isSubmitting), not just after one finishes. Without that, a
/// user tapping the button in the brief window while the auto-submit was
/// still running would fire a second, completely independent
/// submissionService.submit() call -- same photos, same guesses -- resulting
/// in two duplicate Firestore docs for one scan. _isSubmitting is what
/// closes that race.
class GeneralMatchScreen extends StatefulWidget {
  final String imagePath;
  final List<String> imagePathHistory;
  final List<String> topGuesses;

  const GeneralMatchScreen({
    super.key,
    required this.imagePath,
    required this.imagePathHistory,
    required this.topGuesses,
  });

  @override
  State<GeneralMatchScreen> createState() => _GeneralMatchScreenState();
}

class _GeneralMatchScreenState extends State<GeneralMatchScreen> {
  bool _alreadySubmittedForReview = false;
  bool _autoSubmitFailed = false;

  // True for the entire duration ANY submit call is in flight -- auto
  // or manual. This is what actually prevents the double-submission
  // bug: without it, _alreadySubmittedForReview stays false for the
  // whole time the auto-submit is running, so the manual button was
  // fully tappable and could fire a second, independent submit before
  // the first one had even finished.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _autoSubmitForReview();
  }

  /// Fires automatically as soon as this screen opens -- no user action
  /// required. This guarantees every unrecognized scan actually reaches
  /// the admin panel, instead of depending on the user noticing and
  /// tapping the manual button below.
  Future<void> _autoSubmitForReview() async {
    setState(() => _isSubmitting = true);
    try {
      await submissionService.submit(
        Submission(
          deviceNotes:
              'Awtomatikong naipadala: hindi lubos na nakilala bilang isa sa '
              '10 pangunahing klase (model best guesses: '
              '${widget.topGuesses.join(", ")})',
          topGuesses: widget.topGuesses,
          submissionType: 'unrecognized',
        ),
        images: widget.imagePathHistory.map((p) => File(p)).toList(),
      );
      if (!mounted) return;
      setState(() => _alreadySubmittedForReview = true);
    } catch (e) {
      // Non-fatal: the manual button below stays enabled as a fallback,
      // e.g. if there was no network connection when this screen opened.
      // ignore: avoid_print
      print('[GeneralMatchScreen] auto-submit failed: $e');
      if (!mounted) return;
      setState(() => _autoSubmitFailed = true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendForReview() async {
    // Blocks both "already succeeded" AND "one is currently running"
    // (whether that in-flight one is the auto-submit or an earlier tap
    // of this same button) -- this second condition is the actual fix
    // for the duplicate-submission bug.
    if (_alreadySubmittedForReview || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await submissionService.submit(
        Submission(
          deviceNotes:
              'User-guessed name: "${widget.topGuesses.join(", ")}" '
              '(model best guesses: ${widget.topGuesses.join(", ")})',
          topGuesses: widget.topGuesses,
          submissionType: 'unrecognized',
        ),
        images: widget.imagePathHistory.map((p) => File(p)).toList(),
      );
      if (!mounted) return;
      setState(() {
        _alreadySubmittedForReview = true;
        _autoSubmitFailed = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Naipadala na sa team para suriin ✓'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi naipadala: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        // Styled Green Pill Badge Title (Matching ScannerScreen)
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
                Icons.help_outline_rounded,
                color: Color(0xFF10B981),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Hindi Kabilang sa 10 Klase',
                style: AppText.display(
                  size: 14,
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (File(widget.imagePath).existsSync())
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(widget.imagePath),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // What the app concluded, stated plainly.
                const _SectionHeader(
                  title: 'Hindi namin nakilala ito',
                  subtitle:
                      'Ang na-scan na larawan ay hindi kabilang sa 10 '
                      'pangunahing prutas at gulay na sinusuportahan ng '
                      'ProduceAIQ. Walang impormasyong nutrisyon, kasariwaan, '
                      'o resipe ang maaaring ipakita dito dahil hindi ito '
                      'nakilala bilang isa sa mga naka-catalog na produkto.',
                ),
                const SizedBox(height: 16),

                // Auto-submit status banner
                if (_alreadySubmittedForReview) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                          : const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_done_rounded,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Awtomatiko nang naipadala ang larawang ito sa team para sa review.',
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_autoSubmitFailed) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3B1212).withValues(alpha: 0.5)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Hindi awtomatikong naipadala (baka walang internet). Pindutin ang buton sa ibaba para subukan ulit.',
                            style: AppText.body(
                              size: 12,
                              weight: FontWeight.w600,
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                OutlinedButton.icon(
                  onPressed: (_alreadySubmittedForReview || _isSubmitting)
                      ? null
                      : _sendForReview,
                  icon: Icon(
                    _alreadySubmittedForReview
                        ? Icons.check_circle_rounded
                        : (_isSubmitting ? Icons.hourglass_top_rounded : Icons.send_rounded),
                  ),
                  label: Text(
                    _alreadySubmittedForReview
                        ? 'Naipadala na'
                        : (_isSubmitting ? 'Ipinapadala...' : 'Ipadala para sa Review'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: const Color(0xFF10B981),
                    side: BorderSide(
                      color: (_alreadySubmittedForReview || _isSubmitting)
                          ? Colors.grey.shade400
                          : const Color(0xFF10B981),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  ),
                  child: Text(
                    'Bumalik sa Home',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                    ),
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

/// In-Body Section Header Module (Matching App Settings/HowItWorks/ScannerScreen standard)
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

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
            Expanded(
              child: Text(
                title,
                style: AppText.display(
                  size: 18,
                  color: MarketPalette.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppText.body(
            size: 12,
            color: MarketPalette.textBody(context),
          ).copyWith(height: 1.3),
        ),
      ],
    );
  }
}

// =============================================================================
// AMBIENT BOTANICAL BACKGROUND WRAPPER
// =============================================================================

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

    return Container(
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
    );
  }
}

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

    final path1 = Path();
    path1.moveTo(size.width * 0.72, 0);
    path1.quadraticBezierTo(
        size.width, size.height * 0.08, size.width, size.height * 0.22);
    path1.quadraticBezierTo(
        size.width * 0.62, size.height * 0.18, size.width * 0.72, 0);
    path1.close();
    canvas.drawPath(path1, fillPaint);
    canvas.drawPath(path1, strokePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.42);
    path2.quadraticBezierTo(
        size.width * 0.38, size.height * 0.46, size.width * 0.28, size.height * 0.60);
    path2.quadraticBezierTo(
        size.width * 0.05, size.height * 0.56, 0, size.height * 0.42);
    path2.close();
    canvas.drawPath(path2, fillPaint);
    canvas.drawPath(path2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
