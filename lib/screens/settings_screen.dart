import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/brand.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandAppBar(
        title: 'Settings',
      ),
      body: BrandBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeController.mode,
                builder: (context, currentMode, _) => _ThemeSection(currentMode: currentMode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Mukha at Tema" section: live preview + Light / Dark / System options.
class _ThemeSection extends StatelessWidget {
  final ThemeMode currentMode;

  const _ThemeSection({required this.currentMode});

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
              'Kulay at Tema',
              style: AppText.display(
                size: 20,
                color: MarketPalette.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
                  'Pumili ng angkop na kulay ng ProduceAIQ para sa iyong mata at telepono.',
                  style: AppText.body(
                    size: 13,
                    color: MarketPalette.textBody(context),
                  ).copyWith(height: 1.4),
                ),
        const SizedBox(height: 20),

        _LiveThemePreview(currentMode: currentMode),

        const SizedBox(height: 24),

        Text(
                  'MGA PAGPIPILIAN NG KULAY AT TEMA',
                  style: AppText.body(
                    size: 11,
                    weight: FontWeight.w700,
                    color: MarketPalette.textBody(context),
                  ),
                ),
        const SizedBox(height: 12),

        _ThemeOption(
          title: 'Maliwanag (Light)',
          subtitle: 'Sariwa at malinaw na kulay ng palengke.',
          icon: Icons.light_mode_rounded,
          accentColor: const Color(0xFFF59E0B),
          selected: currentMode == ThemeMode.light,
          onTap: () => themeController.setMode(ThemeMode.light),
        ),
        _ThemeOption(
          title: 'Madilim (Dark)',
          subtitle: 'Bawas silaw sa mata at matipid sa baterya.',
          icon: Icons.dark_mode_rounded,
          accentColor: const Color(0xFF6366F1),
          selected: currentMode == ThemeMode.dark,
          onTap: () => themeController.setMode(ThemeMode.dark),
        ),
      ],
    );
      }
    }

    // =============================================================================
    // EXISTING WIDGETS (unchanged except where noted)
    // =============================================================================

    /// Custom Leaf Pattern Painter strictly matching HowItWorksScreen.

/// Interactive Live Theme Preview widget showing how scanned produce cards look
class _LiveThemePreview extends StatelessWidget {
  final ThemeMode currentMode;

  const _LiveThemePreview({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    // FIX: MediaQuery.of(context) subscribes to every MediaQuery change
    // (keyboard, padding, ...). platformBrightnessOf only subscribes to
    // the brightness aspect.
    final systemIsDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isPreviewDark =
        currentMode == ThemeMode.dark ||
        (currentMode == ThemeMode.system && systemIsDark);

    final cardBg = isPreviewDark
        ? MarketPalette.surface(context).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.92);
    final cardBorder = isPreviewDark
        ? const Color(0xFF10B981).withValues(alpha: 0.25)
        : const Color(0xFFE2E8F0);
    final textColor = isPreviewDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isPreviewDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isPreviewDark ? 0.2 : 0.04),
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
              Row(
                children: [
                  Icon(
                    Icons.remove_red_eye_rounded,
                    size: 16,
                    color: subTextColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'SAMPLE',
                    style: AppText.body(
                      size: 10,
                      weight: FontWeight.w700,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '94% AI Confidence',
                  style: AppText.body(
                    size: 10,
                    weight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🥭', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manggang Carabao',
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Nasuri gamit ang ProduceAIQ Scanner',
                      style: AppText.body(size: 11, color: subTextColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.eco, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Sariwa / Ripe',
                      style: AppText.body(
                        size: 11,
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
    );
  }
}

/// Theme option selection tile with state feedback
class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? MarketPalette.surface(context).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.92);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? accentColor
              : (isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.25)
                    : const Color(0xFFE2E8F0)),
          width: selected ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (selected)
            BoxShadow(
              color: accentColor.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor
                        : accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            title,
                            style: AppText.body(
                              size: 15,
                              weight: FontWeight.w700,
                              color: MarketPalette.textPrimary(context),
                            ),
                          ),
                          if (selected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Gamit Ngayon',
                                style: AppText.body(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: accentColor,
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
                                              ).copyWith(height: 1.35),
                                            ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? accentColor
                          : (isDark ? Colors.white38 : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
