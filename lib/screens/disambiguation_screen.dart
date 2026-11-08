import 'dart:io';
import 'package:flutter/material.dart';
import 'result_screen.dart';
import 'home_screen.dart';
import 'scanner_screen.dart';
import '../data/submission.dart';
import '../data/submission_service.dart';
import '../data/produce_repository.dart';
import '../ml/freshness_assessor.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../theme/brand.dart';

/// Photo path of the last confirmed item, used to block duplicate
/// confirmations when the user navigates back to the same scan session.
String? _lastSubmittedPhoto;

/// Produce Disambiguation Screen.
/// Pinapapili ang user kapag magkadikit ang hula ng AI sa dalawang magkamukhang pananim.
class DisambiguationScreen extends StatelessWidget {
  final String candidateProduceId;
  final double? candidateConfidence;
  final String lookalikeLabel;
  final double? lookalikeConfidence;
  final String? imagePath;

  /// Optional bundled asset to show instead of a file (used by the dev preview).
  final String? imageAsset;

  final List<double> attemptHistory;
  final List<String> imagePathHistory;

  const DisambiguationScreen({
    super.key,
    this.candidateProduceId = 'ampalaya',
    this.candidateConfidence,
    this.lookalikeLabel = 'a similar-looking vegetable',
    this.lookalikeConfidence,
    this.imagePath,
    this.imageAsset,
    this.attemptHistory = const [],
    this.imagePathHistory = const [],
  });

  String _label(String id) => id.isEmpty
      ? id
      : '${id[0].toUpperCase()}${id.substring(1).replaceAll('_', ' ')}';

  int get _currentAttempt => attemptHistory.length;

  bool get _canContinueScanning => _currentAttempt < 4;

  @override
  Widget build(BuildContext context) {
    final labelA = _label(candidateProduceId);
    final labelB = _label(lookalikeLabel);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Soft organic background (Soft Sage/Warm Cream - hindi masakit sa mata)
    final backgroundColor = isDark
        ? MarketPalette.background(context)
        : const Color(0xFFEFF2EC);

    final cardBg = isDark
        ? MarketPalette.surface(context)
        : const Color(0xFFFAFAF8);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? MarketPalette.surface(context) : const Color(0xFFE3E9DF),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: MarketPalette.textPrimary(context),
        ),
        title: Text(
          'Alin Dito ang Tamang Item?',
          style: AppText.display(
            size: 18,
            color: MarketPalette.textPrimary(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanned Photo Thumbnail Preview Header
            if (imageAsset != null || imagePath != null) ...[
              _ImagePreviewHeader(imagePath: imagePath, imageAsset: imageAsset),
              const SizedBox(height: 16),
            ],

            // Explanation Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? MarketPalette.divider(context)
                      : const Color(0xFFD3DCD0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.center_focus_strong_rounded,
                          size: 18,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Maaaring $labelA o $labelB ito',
                          style: AppText.display(
                            size: 17,
                            color: MarketPalette.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pumili sa dalawang pinakamalapit na hula ng AI upang maibigay ang tamang impormasyon, freshness grade, at resipe.',
                    style: AppText.body(
                      size: 13,
                      color: MarketPalette.textBody(context),
                    ).copyWith(height: 1.4),
                  ),
                ],
              ),
            ),

            // Attempt History Card
            if (attemptHistory.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? MarketPalette.surface(context) : const Color(0xFFE6EFE3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? MarketPalette.divider(context)
                        : const Color(0xFFCCD7C8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Subok ${attemptHistory.length} sa 4 • Lahat ng %: ${attemptHistory.map((h) => '${(h * 100).toStringAsFixed(0)}%').join(' → ')}',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: MarketPalette.textBody(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Two Candidate Panels Side by Side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CandidatePanel(
                    label: labelA,
                    confidence: candidateConfidence,
                    isStrong: true,
                    onConfirm: () => _confirm(
                      context,
                      candidateProduceId,
                      candidateConfidence,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CandidatePanel(
                    label: labelB,
                    confidence: lookalikeConfidence,
                    isStrong: false,
                    onConfirm: () => _confirm(
                      context,
                      lookalikeLabel,
                      lookalikeConfidence,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Comparison Sheet Button (Soft Green Tint)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF064E3B)
                    : const Color(0xFFD1E7DD),
                foregroundColor: const Color(0xFF047857),
                elevation: 0,
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF059669)
                      : const Color(0xFFA3D6C1),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _showComparison(
                context,
                candidateProduceId,
                lookalikeLabel,
              ),
              icon: const Icon(Icons.compare_arrows_rounded, size: 20, color: Color(0xFF047857)),
              label: Text(
                'Ipakita ang Pagkakaiba',
                style: AppText.body(
                  size: 15,
                  weight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF047857),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // "Patuloyin ang Pagsascan" button for attempts 1-3
            if (_canContinueScanning) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF1A1A2E).withValues(alpha: 0.5)
                        : const Color(0xFFE8F5E9),
                    side: BorderSide(
                      color: isDark
                          ? Brand.emerald.withValues(alpha: 0.5)
                          : Brand.emerald,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _continueScanning(context),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: isDark ? Brand.emerald : const Color(0xFF047857),
                  ),
                  label: Text(
                    'Patuloyin ang Pagsascan (Subok ${_currentAttempt + 1} sa 4)',
                    style: AppText.body(
                      size: 15,
                      weight: FontWeight.w700,
                      color: isDark ? Brand.emerald : const Color(0xFF047857),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Framed "Hindi Ako Sigurado" Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: cardBg,
                side: BorderSide(
                  color: isDark
                      ? Colors.white24
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _handleUnsureSubmission(context),
              icon: Icon(
                Icons.help_outline_rounded,
                size: 18,
                color: MarketPalette.textBody(context),
              ),
              label: Text(
                'Hindi Ako Sigurado',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w600,
                  color: MarketPalette.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
// Action method when user selects "Hindi Ako Sigurado"
  Future<void> _handleUnsureSubmission(BuildContext context) async {
    try {
      await submissionService.submit(
        Submission(
          deviceNotes: 'User selected "I\'m Not Sure" during disambiguation',
          topGuesses: [
            candidateProduceId,
            lookalikeLabel,
          ],
          submissionType: 'disambiguation_unresolved',
        ),
        images: imagePathHistory.map((p) => File(p)).toList(),
      );
    } catch (e) {
      // Previously this was unhandled: offline or a rules rejection made the
      // button appear to do nothing (or threw an uncaught async error). Stay
      // on the screen so the user can retry.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hindi naipadala: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Naipadala na sa team para suriin ✓'),
        backgroundColor: Color(0xFF059669),
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  // Continue scanning - go back to scanner for another attempt
  void _continueScanning(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerScreen(
          attemptNumber: _currentAttempt + 1,
          history: attemptHistory,
          imagePathHistory: imagePathHistory,
          attemptPredictions: const [], // Will be rebuilt in ConfidenceScreen
        ),
      ),
    );
  }

  // Bottom Sheet displaying distinguishing features
  void _showComparison(
    BuildContext context,
    String idA,
    String idB,
  ) {
    final itemA = produceRepository.get(idA);
    final itemB = produceRepository.get(idB);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MarketPalette.surface(context) : const Color(0xFFF7F9F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.lightbulb_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mga Katangiang Nagpapakita ng Pagkakaiba',
                    style: AppText.display(
                      size: 16,
                      color: MarketPalette.textPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ComparisonColumn(
                    title: itemA?.commonName ?? _label(idA),
                    tips: itemA?.visualIdTips ?? 'Walang available na gabay sa pagkakaiba.',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ComparisonColumn(
                    title: itemB?.commonName ?? _label(idB),
                    tips: itemB?.visualIdTips ?? 'Walang available na gabay sa pagkakaiba.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Confirmation method routing to ResultScreen
  void _confirm(
    BuildContext context,
    String produceId,
    double? confidence,
  ) async {
    // Only submit once per scan session - block duplicate confirmations
    // This happens when user navigates back and confirms the same item
    // again. We track via imagePath to detect the same photo.
    if (imagePath != null &&
        _lastSubmittedPhoto != null &&
        imagePath == _lastSubmittedPhoto) {
      // Same photo already confirmed - just navigate to result, don't resubmit
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            produceId: produceId,
            confidence: confidence,
            freshnessGrade: null,
            freshnessFromRealModel: false,
          ),
        ),
      );
      return;
    }
    
    FreshnessGrade? grade;
    bool freshnessFromRealModel = false;
    if (imagePath != null) {
      try {
        final (g, _, isRealModel) = await freshnessAssessor.assess(
          File(imagePath!),
        );
        grade = g;
        freshnessFromRealModel = isRealModel;
      } catch (_) {
        grade = null;
      }
    }
    if (!context.mounted) return;

    // Mark this photo as submitted
    _lastSubmittedPhoto = imagePath;

    // Record history at the point of confirmation -- not in
    // ResultScreen.build(), which duplicated entries on every rebuild.
    final historyItem = produceRepository.get(produceId);
    if (historyItem != null) {
      await HistoryService.instance.add(
        ScanHistoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          produceId: historyItem.id,
          produceName: historyItem.commonName,
          confidence: confidence,
          freshnessGrade: grade?.name,
          imagePath: imagePath,
          timestamp: DateTime.now(),
        ),
      );
    }
    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          produceId: produceId,
          confidence: confidence,
          freshnessGrade: grade,
          freshnessFromRealModel: freshnessFromRealModel,
        ),
      ),
    );
  }
}
/// Top Scanned Image Preview Thumbnail Card
class _ImagePreviewHeader extends StatelessWidget {
  final String? imagePath;
  final String? imageAsset;

  const _ImagePreviewHeader({this.imagePath, this.imageAsset});

  static const double _size = 72;

  Widget _thumbnail() {
    final fallback = Container(
      width: _size,
      height: _size,
      color: const Color(0xFF10B981).withValues(alpha: 0.12),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF059669),
      ),
    );
    if (imageAsset != null) {
      return Image.asset(
        imageAsset!,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return Image.file(
      File(imagePath!),
      width: _size,
      height: _size,
      fit: BoxFit.cover,
      // Decode at thumbnail size instead of the full 12MP camera photo.
      cacheWidth: 288,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? MarketPalette.surface(context) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? MarketPalette.divider(context) : const Color(0xFFDDE3D8),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _thumbnail(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'IYONG NA-SCAN',
                    style: AppText.body(
                      size: 9,
                      weight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suriin ang larawan laban sa mga pagpipilian sa ibaba',
                  style: AppText.body(
                    size: 12,
                    color: MarketPalette.textBody(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Candidate Panel Card Widget with Organic Accent Colors
class _CandidatePanel extends StatelessWidget {
  final String label;
  final double? confidence;
  final VoidCallback onConfirm;
  final bool isStrong;

  const _CandidatePanel({
    required this.label,
    required this.confidence,
    required this.onConfirm,
    this.isStrong = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Emerald Green for Primary, Harvest Amber Orange for Secondary
    final accentColor = isStrong
        ? const Color(0xFF059669)
        : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706));

    final cardBg = isDark ? MarketPalette.surface(context) : Colors.white;

    // 'Others' category: the item was not within our 10 curated classes.
    // Uses a red prompt (square, not circle) to highlight that this is
    // an unrecognized item, and a filled background so the bottom of
    // the panel is not plain white.
    final isOthers = label == 'Others' || label == 'other';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOthers
            ? const Color(0xFFFEF2F2) // red-tinted background, not plain white
            : cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOthers
              ? const Color(0xFFDC2626) // red border
              : accentColor.withValues(alpha: isStrong ? 0.9 : 0.6),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isOthers
                    ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                    : accentColor.withValues(alpha: 0.12),
                // Square prompt (no rounded corners) so it stands out
                // as a highlighted box rather than a pill/circle.
                borderRadius: BorderRadius.zero,
              ),
              child: Text(
                isOthers
                    ? 'LESBONA ANG TANONG: HAWA SA 10 KATEGORIYA'
                    : (isStrong ? 'PANGUNAHING HULA' : 'OPSYON B'),
                style: AppText.body(
                  size: 9,
                  weight: FontWeight.w700,
                  color: isOthers
                      ? const Color(0xFFDC2626)
                      : accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppText.body(
              size: 15,
              weight: FontWeight.w700,
              color: isOthers
                  ? const Color(0xFFB91C1C) // darker red for text
                  : MarketPalette.textPrimary(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            confidence != null
                ? '${(confidence! * 100).toStringAsFixed(0)}% kasiguraduhan'
                : '',
            style: AppText.body(
              size: 12,
              weight: FontWeight.w700,
              color: isOthers
                  ? const Color(0xFFDC2626) // red for confidence
                  : accentColor,
            ),
          ),
          const SizedBox(height: 16),
          if (isStrong)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onConfirm,
              child: Text(
                'Kumpirmahin',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          else
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.08),
                foregroundColor: accentColor,
                side: BorderSide(
                  color: accentColor,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onConfirm,
              child: Text(
                'Kumpirmahin',
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Feature Comparison Column Widget inside Bottom Sheet
class _ComparisonColumn extends StatelessWidget {
  final String title;
  final String tips;

  const _ComparisonColumn({
    required this.title,
    required this.tips,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? MarketPalette.background(context)
            : const Color(0xFFEDF2EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? MarketPalette.divider(context)
              : const Color(0xFFE2E8DF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.body(
              size: 14,
              weight: FontWeight.w700,
              color: MarketPalette.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tips,
            style: AppText.body(
              size: 12,
              color: MarketPalette.textBody(context),
            ).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}