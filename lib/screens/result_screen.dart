import 'package:flutter/material.dart';
import '../data/produce_repository.dart';
import '../ml/freshness_assessor.dart';
import '../theme/app_theme.dart';
import 'recipe_screen.dart';
import 'home_screen.dart';
import '../services/connectivity_service.dart';

class ResultScreen extends StatelessWidget {
  final String produceId;
  final double? confidence;
  final FreshnessGrade? freshnessGrade;
  final bool freshnessFromRealModel;

  const ResultScreen({
    super.key,
    this.produceId = 'mango',
    this.confidence,
    this.freshnessGrade,
    this.freshnessFromRealModel = false,
  });

  @override
    Widget build(BuildContext context) {
      final item = produceRepository.get(produceId);
      final isDark = Theme.of(context).brightness == Brightness.dark;

    // NOTE: history is recorded where a scan is actually accepted (see
    // confidence_screen.dart / disambiguation_screen.dart), NOT here.
    // Doing it in build() meant every rebuild (theme change, dialog,
    // orientation change) and every open-from-history added a duplicate
    // entry for the same scan.

    // 'other' means the item was not within the 10 curated classes.
    // This is now handled by HomeScreen's full-screen overlay when
    // ConfidenceScreen pushes HomeScreen(showOtherRedPrompt: true).
    // Compare case-insensitively because the model's labels are uppercase
    // ('OTHER') while the check in scan_decision.dart uses lowercase.
    final isOther = produceId.toLowerCase() == 'other';

    if (item == null) {
      if (isOther) {
        // Should not reach here - handled by HomeScreen overlay.
        // Fallback: go back to Home with the overlay.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(showOtherRedPrompt: true),
            ),
          );
        });
        return const SizedBox.shrink();
      }

      // Unknown item - not in the catalog at all.
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
                  Icons.eco_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pagkilala sa Produkto',
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
                  child: Center(
                    child: Text(
                      'Walang nakitang data para sa "$produceId"',
                      style: AppText.body(size: 16, color: MarketPalette.textBody(context)),
                    ),
                  ),
                ),
      );
    }

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
                Icons.eco_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pagkilala sa Produkto',
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              // In-Body Section Header
              const _SectionHeader(),
              const SizedBox(height: 16),

              // Produce Botanical Header Card
              _ProduceHeaderCard(
                item: item,
                confidence: confidence,
                freshnessGrade: freshnessGrade,
                freshnessFromRealModel: freshnessFromRealModel,
              ),

              // Spoilage Warning Alert (if Rotten)
              if (freshnessGrade == FreshnessGrade.rotten) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mukhang panis na ang produktong ito. Para sa kaligtasan sa pagkain, '
                          'inirerekomenda naming itapon ito kaysa kainin.',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Produce History Section
              if (item.history.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Pinagmulan at Kasaysayan',
                  icon: Icons.auto_stories_rounded,
                  child: Text(
                    item.history,
                    style: AppText.body(
                      size: 14,
                      color: MarketPalette.textPrimary(context),
                    ).copyWith(height: 1.5),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Name in Other Languages
              _SectionCard(
                title: 'Pangalan sa Iba’t Ibang Wika',
                icon: Icons.translate_rounded,
                child: _InfoGrid(
                  entries: item.translations.entries
                      .map((e) => MapEntry(_capitalize(e.key), e.value))
                      .toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Nutrition & Shelf Life
              _SectionCard(
                title: 'Nutrisyon at Tagal ng Pag-iimbak',
                icon: Icons.pie_chart_outline_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoGrid(
                      entries: item.nutrition.entries
                          .map((e) => MapEntry(_capitalize(e.key), e.value.toString()))
                          .toList(),
                    ),
                    if (item.shelfLife.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tagal ng Pag-iimbak: ',
                              style: AppText.body(
                                size: 13,
                                weight: FontWeight.w700,
                                color: MarketPalette.textPrimary(context),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.shelfLife,
                                style: AppText.body(
                                  size: 13,
                                  color: MarketPalette.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Recipe CTA Button
              _RecipeActionButton(
                produceId: produceId,
                freshnessGrade: freshnessGrade,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).replaceAll('_', ' ')}';
}

/// In-Body Section Header Module
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
              'Resulta ng Pagsusuri',
              style: AppText.display(
                size: 18,
                color: MarketPalette.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
                  'Tingnan ang detalye at kasariwaan ng iyong produkto.',
                  style: AppText.body(
                    size: 12,
                    color: MarketPalette.textBody(context),
                  ).copyWith(height: 1.3),
                ),
      ],
    );
  }
}

/// Leafy Main Produce Overview Card
class _ProduceHeaderCard extends StatelessWidget {
  final dynamic item;
  final double? confidence;
  final FreshnessGrade? freshnessGrade;
  final bool freshnessFromRealModel;

  const _ProduceHeaderCard({
    required this.item,
    this.confidence,
    this.freshnessGrade,
    required this.freshnessFromRealModel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF091F15).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botanical Gradient Banner Top Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Leaf Watermark Overlay
                Positioned(
                  right: -15,
                  bottom: -20,
                  child: Icon(
                    Icons.energy_savings_leaf_rounded,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.commonName,
                            style: AppText.display(
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.scientificName,
                            style: AppText.body(
                              size: 14,
                              color: const Color(0xFFA7F3D0),
                            ).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                    if (confidence != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFFA7F3D0),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(confidence! * 100).toStringAsFixed(0)}%',
                              style: AppText.body(
                                size: 12,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Freshness Level Bottom Section
          if (freshnessGrade != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.spa_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                                      'Antas ng Kasariwaan:',
                                      style: AppText.body(
                                        size: 13,
                                        weight: FontWeight.w600,
                                        color: MarketPalette.textBody(context),
                                      ),
                                    ),
                  const SizedBox(width: 10),
                  _FreshnessBadge(
                    grade: freshnessGrade!,
                    fromRealModel: freshnessFromRealModel,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Generic Card Container for Sections with Botanical Accent
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
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
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w800,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                ).copyWith(letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Badge representing Freshness Grade
class _FreshnessBadge extends StatelessWidget {
  final FreshnessGrade grade;
  final bool fromRealModel;

  const _FreshnessBadge({
    required this.grade,
    this.fromRealModel = false,
  });

  Color get _color {
    switch (grade) {
      case FreshnessGrade.unripe:
        return AppColors.gradeUnripe;
      case FreshnessGrade.ripe:
        return AppColors.gradeRipe;
      case FreshnessGrade.overripe:
        return AppColors.gradeOverripe;
      case FreshnessGrade.rotten:
        return AppColors.gradeRotten;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _color,
              width: 1.2,
            ),
          ),
          child: Text(
            grade.label,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              color: _color,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
                  message: fromRealModel
                      ? 'Galing sa sinanay na modelo para sa kasariwaan..'
                      : 'Hula batay sa kulay at mantsa, hindi mula sa sinanay na modelo.',
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: MarketPalette.textBody(context),
                  ),
                ),
      ],
    );
  }
}

/// Two-column grid that dynamically fills the full width of the card
class _InfoGrid extends StatelessWidget {
  final List<MapEntry<String, String>> entries;

  const _InfoGrid({
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: entries.map((e) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
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
                                          e.key.toUpperCase(),
                                          style: AppText.body(
                                            size: 10,
                                            weight: FontWeight.w600,
                                            color: MarketPalette.textBody(context),
                                          ),
                                        ),
                    const SizedBox(height: 2),
                    Text(
                      e.value,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w700,
                        color: MarketPalette.textPrimary(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Prominent Botanical Action Button to navigate to recipes
class _RecipeActionButton extends StatelessWidget {
  final String produceId;
  final FreshnessGrade? freshnessGrade;

  const _RecipeActionButton({
    required this.produceId,
    required this.freshnessGrade,
  });

  @override
  Widget build(BuildContext context) {
    final isRotten = freshnessGrade == FreshnessGrade.rotten;
    final connectivity = ConnectivityService.instance;
    final isOnline = connectivity.isOnline;

    if (isRotten) {
      // Deliberately NOT a button. Rotten produce is unsafe to eat, so there
      // is no recipe path at all -- not even a "not recommended" override.
      // The red spoilage warning elsewhere on this screen tells the user to
      // discard the item; this just makes the absence of recipes explicit
      // instead of leaving a blank gap.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF3B1212)
              : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.block_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Walang recipe para sa sirang produkto — hindi ito ligtas kainin.',
                style: AppText.body(
                  size: 13,
                  weight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF991B1B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!isOnline) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: MarketPalette.textMuted(context),
            side: BorderSide(
              color: MarketPalette.divider(context),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: null,
          icon: Icon(
            Icons.wifi_off_rounded,
            color: MarketPalette.textMuted(context),
            size: 22,
          ),
          label: Text(
            'Kailangan ang internet para sa AI recipes',
            style: AppText.button(size: 15).copyWith(
              color: MarketPalette.textMuted(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecipeScreen(
                produceId: produceId,
                freshnessGrade: freshnessGrade,
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'TINGNAN ANG RESIPE NG AI',
              style: AppText.button(size: 15).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ambient Botanical Leaf Background Wrapper
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