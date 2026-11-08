import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared visual identity for ProduceAIQ.
///
/// Redesigned to match the actual UI mockups in the thesis paper
/// (Figures 3.3-3.7): a dark, tech/scanner-style interface with a
/// lime-green accent, rather than the earlier "market stall ticket
/// stub" theme. The paper's mobile-app mockups are all dark; the
/// Admin Panel mockup (Figure 3.7) is light -- both now share the
/// same lime-green brand accent instead of two unrelated palettes.
class AppColors {
  AppColors._();

  // ---- Dark (primary -- matches the paper's mobile-app mockups) ----
  static const nightBg = Color(0xFF0D0D0D);
  static const nightSurface = Color(0xFF1A1A1A);
  static const nightSurfaceAlt = Color(0xFF242424);
  static const nightDivider = Color(0xFF333333);
  static const nightTextPrimary = Color(0xFFF5F5F5);
  static const nightTextMuted = Color(0xFFA3A3A3);
  static const nightTextBody = Color(0xFFE0E0E0);

  // ---- Light (secondary -- same accent, light surfaces) ----
  static const dayBg = Color(0xFFF7F8F6);
  static const daySurface = Color(0xFFFFFFFF);
  static const daySurfaceAlt = Color(0xFFEFF2ED);
  static const dayDivider = Color(0xFFDDE2D8);
  static const dayTextPrimary = Color(0xFF16181B);
  static const dayTextMuted = Color(0xFF6B7268);
  static const dayTextBody = Color(0xFF3A3D36);

  // ---- Shared brand accent (the paper's neon/lime green) ----
  static const limeAccent = Color(0xFFA3E635);
  static const limeAccentDim = Color(0xFF6B9E22);

  // ---- Freshness grade colors (unchanged meaning, tuned to read
  // clearly on both dark and light surfaces) ----
  static const gradeUnripe = Color(0xFF60A5FA);
  static const gradeRipe = limeAccent;
  static const gradeOverripe = Color(0xFFF5B93D);
  static const gradeRotten = Color(0xFFEF5350);
}

/// Resolves the correct color for the current [Brightness] so shared
/// widgets and screens don't each need their own light/dark branching.
class MarketPalette {
  MarketPalette._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      isDark(context) ? AppColors.nightBg : AppColors.dayBg;

  static Color surface(BuildContext context) =>
      isDark(context) ? AppColors.nightSurface : AppColors.daySurface;

  static Color surfaceAlt(BuildContext context) =>
      isDark(context) ? AppColors.nightSurfaceAlt : AppColors.daySurfaceAlt;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? AppColors.nightTextPrimary : AppColors.dayTextPrimary;

  static Color textMuted(BuildContext context) =>
      isDark(context) ? AppColors.nightTextMuted : AppColors.dayTextMuted;

  /// Body text color - more readable than textMuted for farmers in both themes.
  /// Dark: light gray (#E0E0E0), Light: dark gray-green (#3A3D36)
  static Color textBody(BuildContext context) =>
      isDark(context) ? AppColors.nightTextBody : AppColors.dayTextBody;

  /// The one brand accent, same lime-green in both modes -- this is
  /// what used to be "accentGreen" pointing at two different greens;
  /// now it's genuinely one consistent brand color everywhere.
  static Color accentGreen(BuildContext context) => AppColors.limeAccent;

  static Color divider(BuildContext context) =>
      isDark(context) ? AppColors.nightDivider : AppColors.dayDivider;
}

/// Builds the app's ThemeData for a given brightness. Both share the
/// same shape/typography choices from AppText; only colors differ.
class AppTheme {
  AppTheme._();

  // Cached: ThemeData + ColorScheme.fromSeed are expensive to build, and
  // MaterialApp used to rebuild BOTH of them every time the theme mode
  // changed. They only ever need to be built once.
  static ThemeData? _light;
  static ThemeData? _dark;

  static ThemeData light() => _light ??= _build(
    brightness: Brightness.light,
    background: AppColors.dayBg,
    surface: AppColors.daySurface,
    onSurface: AppColors.dayTextPrimary,
    divider: AppColors.dayDivider,
  );

  static ThemeData dark() => _dark ??= _build(
    brightness: Brightness.dark,
    background: AppColors.nightBg,
    surface: AppColors.nightSurface,
    onSurface: AppColors.nightTextPrimary,
    divider: AppColors.nightDivider,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color divider,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.limeAccent,
        brightness: brightness,
        primary: AppColors.limeAccent,
        surface: surface,
        onSurface: onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
      ),
      cardColor: surface,
      dividerColor: divider,
    );
  }
}

class AppText {
  AppText._();

  static TextStyle display({double size = 28, Color? color, FontWeight? weight}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w700,
        color: color ?? AppColors.dayTextPrimary,
        height: 1.05,
      );

  static TextStyle body({double size = 14, Color? color, FontWeight? weight}) =>
      GoogleFonts.workSans(
        fontSize: size,
        fontWeight: weight ?? FontWeight.w400,
        color: color ?? AppColors.dayTextPrimary,
        height: 1.4,
      );

  static TextStyle button({double size = 15, Color? color}) => GoogleFonts.workSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.black,
        letterSpacing: 0.2,
      );
}

/// A dashed divider line. Kept from the earlier design -- still a
/// useful plain visual separator, no longer tied to a "ticket stub"
/// motif specifically.
class PerforationDivider extends StatelessWidget {
  final Color? color;
  const PerforationDivider({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? MarketPalette.divider(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const gap = 5.0;
        final count = (constraints.maxWidth / (dashWidth + gap)).floor();
        return SizedBox(
          height: 1,
          child: Row(
            children: List.generate(
              count,
              (_) => Padding(
                padding: const EdgeInsets.only(right: gap),
                child: Container(width: dashWidth, height: 1, color: resolvedColor),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// L-shaped viewfinder corner brackets drawn over the camera preview.
/// Default color updated to the new lime-green brand accent (was
/// mango-orange under the old market-stall theme).
class ViewfinderCorners extends StatelessWidget {
  final Color color;
  final double length;
  final double thickness;

  const ViewfinderCorners({
    super.key,
    this.color = AppColors.limeAccent,
    this.length = 28,
    this.thickness = 4,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerPainter(color: color, length: length, thickness: thickness),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double length;
  final double thickness;
  _CornerPainter({required this.color, required this.length, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, paint);
      canvas.drawLine(origin, origin + dy, paint);
    }

    const inset = 14.0;
    corner(const Offset(inset, inset), Offset(length, 0), Offset(0, length));
    corner(Offset(size.width - inset, inset), Offset(-length, 0), Offset(0, length));
    corner(Offset(inset, size.height - inset), Offset(length, 0), Offset(0, -length));
    corner(
      Offset(size.width - inset, size.height - inset),
      Offset(-length, 0),
      Offset(0, -length),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}