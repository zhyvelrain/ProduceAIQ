import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Terms / limitations screen. Static content only, so it is cheap to
/// build (no animations, no controllers, painter isolated in a
/// RepaintBoundary).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const String _generalStatement =
      'Ang ProduceAIQ ay isang tulong at impormasyonal na aplikasyon at hindi '
      'dapat ituring na ganap o pinal na batayan. Ang mga resultang nililikha '
      'ng ProduceAIQ ay gabay lamang sa loob ng itinakdang saklaw ng '
      'aplikasyon. Pakitandaan ang mga limitasyon nito, at beripikahin ang '
      'mahahalagang impormasyon sa angkop na mga mapagkukunan o sa mga '
      'kwalipikadong propesyonal kung kinakailangan.';

  static const List<_Limit> _limits = [
    _Limit(
      icon: Icons.grid_view_rounded,
      color: Color(0xFF16A34A),
      title: 'Saklaw ng Produce',
      body:
          'Limitado ang ProduceAIQ sa 10 napiling klase ng produce: Ampalaya, '
          'Saging, Kangkong, Mangga, Papaya, Pinya, Sitaw, Talbos ng Kamote, '
          'Talong, at Pakwan. Ang ibang prutas o gulay ay hindi saklaw ng '
          'aplikasyon at maaaring lumabas bilang "ISA" sa 10 na napiling produce, o kung wala talagang na iscan na produce, ito ay lalabas bilang "others", na nangangahulagang wala sa 10 na produkto.'
    ),
    _Limit(
      icon: Icons.psychology_alt_rounded,
      color: Color(0xFF10B981),
      title: 'AI Recognition',
      body:
          'Ang pagkilala ay batay sa AI at maaaring magbigay ng maling '
          'resulta. Kung mababa ang confidence ng resulta, maaaring kailanganin '
          'ng panibagong larawan o ng pagpili mula sa dalawang posibleng sagot '
          '(disambiguation).',
    ),
    _Limit(
      icon: Icons.restaurant_menu_rounded,
      color: Color(0xFFF59E0B),
      title: 'Impormasyon sa Nutrition',
      body:
          'Ang impormasyon sa nutrisyon ay para lamang sa sanggunian at '
          'hindi kapalit ng payo ng propesyonal sa nutrisyon o medisina.',
    ),
    _Limit(
      icon: Icons.center_focus_strong_rounded,
      color: Color(0xFF0EA5E9),
      title: 'Mga pangunahing kailangan ng picture o imahe',
      body:
          'Nakadepende ang pagkilala sa kalidad ng larawan, liwanag, kung '
          'gaano kakita ang produkto, layo ng kuha, at iba pang kondisyon ng '
          'kamera.',
    ),
    _Limit(
      icon: Icons.people_alt_rounded,
      color: Color(0xFF8B5CF6),
      title: 'Accessibility at Inilaang mga Gumagamit',
      body:
          'Idinisenyo ang ProduceAIQ para sa mga gumagamit sa loob ng saklaw ng pag-aaral, at hindi ito para sa lahat ng edad, kakayahan, o kondisyon. '
          'Kinakailangan din na ≥7 years old ang taon ng gumagamit upang matiyak ang wastong kakayahang gumamit ng smartphone. '
          'Ang mga gumagamit na hindi kayang patakbuhin ang kinakailangang device nang mag-isa ay maaaring mangailangan ng angkop na tulong mula sa ibang tao. '
          'Ang kasalukuyang bersyon ay pangunahing umaasa sa visual na feedback, touchscreen, at paggamit ng kamera. '
          'Maaaring hindi ito ganap na magamit ng mga user na may total blindness o malubhang kapansanan sa paningin, o may pisikal/motor na kapansanang humahadlang sa malayang paggamit ng touchscreen o kamera. '
          'Hindi rin ito idinisenyo para sa direktang paggamit ng mga sanggol o baby dahil nangangailangan ito ng kakayahang gumamit ng touchscreen at kamera.',
    ),

    _Limit(
      icon: Icons.wifi_rounded,
      color: Color(0xFF14B8A6),
      title: 'Kailangan ng Internet',
      body:
          'Ang ilang parte ng app na ito, tulad ng AI-generated na recipe, ay '
          'nangangailangan ng internet connection.',
    ),
    _Limit(
      icon: Icons.people_alt_rounded,
      color: Color(0xFFEF4444),
      title: 'Mga Updates',
      body:
          'Ang app na ito ay limitado lamang sa kasulukuyang bersyon, upang makapag up ng panibagong bersyon, kinakailangang mag hintay ng panibagong APK file sa Gdrive',
    ),
  ];

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
          color: isDark
              ? MarketPalette.textPrimary(context)
              : const Color(0xFF047857),
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
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 8),
              Text(
                'Mga Tuntunin',
                style: AppText.display(
                  size: 16,
                  color: isDark
                      ? const Color(0xFF34D399)
                      : const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _LeafyBackground(
        isDark: isDark,
        child: SafeArea(
          // ListView.builder: only visible cards are built.
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            itemCount: _limits.length + 3,
            itemBuilder: (context, i) {
              if (i == 0) {
                return const _SectionTitle(
                    'Pangkalahatang Kondisyon sa Paggamit');
              }
              if (i == 1) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 28),
                  child: _InfoCard(
                    icon: Icons.info_outline_rounded,
                    color: Color(0xFF10B981),
                    title: null,
                    body: _generalStatement,
                  ),
                );
              }
              if (i == 2) {
                return const _SectionTitle('Mga Limitasyon at Paalala');
              }
              final l = _limits[i - 3];
              return _InfoCard(
                icon: l.icon,
                color: l.color,
                title: l.title,
                body: l.body,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Limit {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Limit({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
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
              text,
              style: AppText.display(
                size: 18,
                color: MarketPalette.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? MarketPalette.surface(context).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.25)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: AppText.display(
                      size: 15,
                      color: MarketPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  body,
                  style: AppText.body(
                    size: 13,
                    color: MarketPalette.textBody(context),
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Drop this into SettingsScreen's ListView to open the terms screen.
class TermsLinkTile extends StatelessWidget {
  const TermsLinkTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Material(
        color: isDark
            ? MarketPalette.surface(context).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TermsScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mga Tuntunin at Limitasyon',
                    style: AppText.display(
                      size: 15,
                      color: MarketPalette.textPrimary(context),
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: MarketPalette.textBody(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeafyBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _LeafyBackground({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = isDark
        ? const [Color(0xFF091F15), Color(0xFF05170F), Color(0xFF020C07)]
        : const [Color(0xFFEAF5EC), Color(0xFFDBEFE1), Color(0xFFCCE8D4)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LeafPainter(isDark: isDark)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final bool isDark;
  const _LeafPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = isDark
          ? const Color(0xFF34D399).withValues(alpha: 0.14)
          : const Color(0xFF059669).withValues(alpha: 0.06);
    final stroke = Paint()
      ..color = isDark
          ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
          : const Color(0xFF10B981).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final p1 = Path()
      ..moveTo(size.width * 0.72, 0)
      ..quadraticBezierTo(
          size.width, size.height * 0.08, size.width, size.height * 0.22)
      ..quadraticBezierTo(
          size.width * 0.62, size.height * 0.18, size.width * 0.72, 0)
      ..close();
    canvas.drawPath(p1, fill);
    canvas.drawPath(p1, stroke);

    final p2 = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.46,
          size.width * 0.28, size.height * 0.60)
      ..quadraticBezierTo(
          size.width * 0.05, size.height * 0.56, 0, size.height * 0.42)
      ..close();
    canvas.drawPath(p2, fill);
    canvas.drawPath(p2, stroke);
  }

  @override
  bool shouldRepaint(covariant _LeafPainter old) => old.isDark != isDark;
}
