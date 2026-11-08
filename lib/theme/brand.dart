import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Brand pieces and small shared widgets for ProduceAIQ.
///
/// The app's screens used to each hard-code the same pill badge, section
/// header, and background gradient, which is why the green tones drifted apart
/// between screens (AppColors.limeAccent in the theme vs. #10B981 in the
/// widgets). Everything now resolves through these so a screen cannot silently
/// disagree with another one.

/// The one brand green, resolved for the current brightness.
///
/// Screens previously mixed `#10B981` (a hand-picked emerald) with
/// `MarketPalette.accentGreen` (the lime accent from the theme). The emerald
/// reads better on both light and dark surfaces, so it is now the single
/// source of truth -- the accent stays available for the Material theme's seed
/// color only.
class Brand {
  Brand._();

  /// The emerald used for badges, highlights, and primary actions.
  static const emerald = Color(0xFF10B981);

  /// Darker end of the emerald gradient, for buttons and header banners.
  static const emeraldDeep = Color(0xFF047857);

  /// Lightest tint, for filled chips and soft status banners.
  static const emeraldSoft = Color(0xFFD1FAE5);

  /// Slightly deeper tint, for success banners that need more presence.
  static const emeraldWash = Color(0xFFA7F3D0);

  /// The very light surface tint behind cards and gradients in light mode.
  static const leafLight = Color(0xFFEAF5EC);

  /// Mid stop of the light background gradient.
  static const leafLightMid = Color(0xFFDBEFE1);

  /// Deepest stop of the light background gradient.
  static const leafLightDeep = Color(0xFFCCE8D4);

  /// Dark background gradient stops, matching the light ones in depth.
  static const forestDeep = Color(0xFF091F15);
  static const forestMid = Color(0xFF05170F);
  static const forestInk = Color(0xFF020C07);

  /// Text color that reads on the emerald gradient itself.
  static const onEmerald = Colors.white;

  /// Emerald with [alpha] applied, for borders and soft glows.
  static Color emeraldAt(double alpha) =>
      emerald.withValues(alpha: alpha);
}

/// Rounded card with the app's standard surface treatment: a soft surface,
/// an emerald border, and a gentle emerald-tinted shadow.
class BrandCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const BrandCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 18,
    this.color,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ??
            (isDark
                ? MarketPalette.surface(context).withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.94)),
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: Brand.emeraldAt(isDark ? 0.35 : 0.3),
              width: 1.4,
            ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Brand.emeraldAt(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: child,
    );
  }
}

/// The small rounded badge used in every screen's AppBar title.
///
/// Shows a leaf glyph plus [label], which is how the app's screens are
/// identified at a glance.
class BrandBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final double size;

  const BrandBadge({
    super.key,
    required this.label,
    this.icon = Icons.eco_rounded,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Brand.emeraldAt(0.18)
            : Brand.emeraldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.emeraldAt(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Brand.emerald, size: size + 4),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.display(
                size: size,
                color: isDark ? const Color(0xFF34D399) : Brand.emeraldDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with the thin emerald rule on the left.
class BrandSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double size;

  const BrandSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.size = 20,
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
              height: size + 2,
              decoration: BoxDecoration(
                color: Brand.emerald,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppText.display(
                  size: size,
                  color: MarketPalette.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: AppText.body(
              size: 13,
              color: MarketPalette.textMuted(context),
            ).copyWith(height: 1.4),
          ),
        ],
      ],
    );
  }
}

/// The app's signature background: a leafy gradient with two faint botanical
/// shapes drifting behind the content.
///
/// Shared so every screen gets the same depth instead of each drawing its own
/// (slightly different) copy.
class BrandBackground extends StatelessWidget {
  final Widget child;

  const BrandBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    final colors = isDark
        ? const [Brand.forestDeep, Brand.forestMid, Brand.forestInk]
        : const [Brand.leafLight, Brand.leafLightMid, Brand.leafLightDeep];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
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
          : Brand.emeraldAt(0.06)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isDark
          ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
          : Brand.emeraldAt(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Top-right leaf.
    final topRight = Path()
      ..moveTo(size.width * 0.72, 0)
      ..quadraticBezierTo(
          size.width, size.height * 0.08, size.width, size.height * 0.22)
      ..quadraticBezierTo(
          size.width * 0.62, size.height * 0.18, size.width * 0.72, 0)
      ..close();
    canvas.drawPath(topRight, fillPaint);
    canvas.drawPath(topRight, strokePaint);

    // Bottom-left leaf.
    final bottomLeft = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(
          size.width * 0.38, size.height * 0.46, size.width * 0.28, size.height * 0.60)
      ..quadraticBezierTo(
          size.width * 0.05, size.height * 0.56, 0, size.height * 0.42)
      ..close();
    canvas.drawPath(bottomLeft, fillPaint);
    canvas.drawPath(bottomLeft, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _LeafPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Small rounded chip used for labels like "fruit" / "vegetable".
class BrandChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const BrandChip({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Brand.emeraldAt(0.18) : Brand.emeraldSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Brand.emeraldAt(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Brand.emerald),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.body(
              size: 11,
              weight: FontWeight.w700,
              color: isDark ? const Color(0xFF6EE7B7) : Brand.emeraldDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// A stat tile: a big number or value over a small caption.
///
/// Used on Home so the app shows what it knows up front instead of a screen of
/// explanatory text.
class BrandStatTile extends StatelessWidget {
  final String value;
  final String caption;
  final IconData icon;
  final Color? textColor;

  const BrandStatTile({
    super.key,
    required this.value,
    required this.caption,
    required this.icon,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Brand.emeraldAt(0.12)
            : Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Brand.emeraldAt(0.28)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Brand.emerald),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppText.display(
                size: 18,
                color: textColor ?? MarketPalette.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              size: 10.5,
              color: MarketPalette.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable row leading somewhere, with a leading icon and trailing chevron.
class BrandNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const BrandNavTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? MarketPalette.surface(context).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Brand.emeraldAt(isDark ? 0.25 : 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Brand.emeraldAt(isDark ? 0.16 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: Brand.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.body(
                        size: 14,
                        weight: FontWeight.w600,
                        color: MarketPalette.textPrimary(context),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppText.body(
                          size: 11.5,
                          color: MarketPalette.textMuted(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Brand.emeraldAt(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The AppBar the app's secondary screens share: a leafy gradient behind a
/// centred [BrandBadge].
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final PreferredSizeWidget? bottom;

  const BrandAppBar({
    super.key,
    required this.title,
    this.icon = Icons.eco_rounded,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final isDark = MarketPalette.isDark(context);
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark
          ? Brand.forestDeep.withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      centerTitle: true,
      iconTheme: IconThemeData(
        color: isDark ? MarketPalette.textPrimary(context) : Brand.emeraldDeep,
      ),
      title: BrandBadge(label: title, icon: icon),
      bottom: bottom,
    );
  }
}
