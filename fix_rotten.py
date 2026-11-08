#!/usr/bin/env python3
# -*- coding: utf-8 -*-

with open('lib/screens/result_screen.dart', 'r') as f:
    content = f.read()

# 1. Remove the "See recipes anyway" button for rotten produce
# Replace it with a simple "Scan Again" prompt

old_button = """      if (isRotten) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: MarketPalette.textBody(context),
            side: BorderSide(
              color: MarketPalette.divider(context),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
          icon: const Icon(Icons.restaurant_menu_rounded),
          label: Text(
                      'See recipes anyway (not recommended)',
                      style: AppText.button(size: 14).copyWith(
                        color: MarketPalette.textBody(context),
                      ),
                    ),
        ),
      );
    }
"""

new_button = """      if (isRotten) {
      // Rotten produce: remove the recipe button entirely.
      // Only show a "Scan Again" prompt -- no recipe screen, no redundant navigation.
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
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Panis na ang Produkto',
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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3B1212) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xEF4444),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFC2626),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mukhang panis na ang produktong ito. Para sa kaligtasan sa pagkain, inirerekomenda naming itapon ito kaysa kainin.',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: isDark ? const Color(0xFC8A8A) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
                  title: 'Pangalan sa Iba\'t Ibang Wika',
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

                // ONLY: Scan Again button - no recipe button for rotten produce
                const SizedBox(height: 28),
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScannerScreen(
                            attemptNumber: 1,
                            history: [],
                            imagePathHistory: [],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.replay_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'I-scan Muli',
                          style: AppText.button(size: 15).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
"""

if old_button in content:
    content = content.replace(old_button, new_button)
    print("✓ Removed recipe button for rotten produce")
else:
    print("✗ Could not find rotten button pattern")

with open('lib/screens/result_screen.dart', 'w') as f:
    f.write(content)

print("Done")
