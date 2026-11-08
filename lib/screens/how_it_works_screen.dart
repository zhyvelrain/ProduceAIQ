import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/brand.dart';
import '../data/produce_repository.dart';
import '../data/produce_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'onboarding_screen.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

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
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Paano Gumagana',
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
      body: BrandBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              BrandSectionHeader(
                title: 'Gabay sa Pag-scan',
                subtitle:
                    'Unawain kung paano sinusuri ng ProduceAIQ ang iyong mga prutas at gulay.',
                size: 20,
              ),

              const SizedBox(height: 20),

              _ReplayIntroCard(),

              const SizedBox(height: 16),

              _ExpandableGuideCard(
                icon: Icons.play_circle_outline_rounded,
                iconColor: Color(0xFF14B8A6),
                title: 'Panoorin: Walkthrough sa Pag-scan',
                body:
                    'Maikling video na nagpapakita kung paano mag-scan mula simula hanggang matapos, kasama kung ano ang mangyayari kapag hindi sigurado ang app sa nakita nitong produce.',
                interactivePreview: _VideoWalkthroughDemo(),
                initiallyExpanded: true,
                isOutdated: true,
                outdatedNote:
                    'Hindi na updated ang video na ito — may mga bahagi na pwedeng magkaiba sa kasalukuyang app.',
              ),

              _ExpandableGuideCard(
                icon: Icons.ondemand_video_rounded,
                iconColor: Color.fromARGB(255, 6, 121, 160),
                title: 'Panoorin sa YouTube',
                body: 'https://youtu.be/lr3XtK8Hp6E',
                linkUrl: 'https://youtu.be/lr3XtK8Hp6E',
                interactivePreview: SizedBox.shrink(),
                isOutdated: true,
                outdatedNote:
                    'Luma na ang YouTube video na ito — ilang steps ay pwedeng hindi na tumugma sa app.',
              ),

              _ExpandableGuideCard(
                icon: Icons.percent_rounded,
                iconColor: Color(0xFF10B981),
                title: 'Ano ang ibig sabihin ng confidence %',
                body:
                    'Kapag nag-scan o nag-upload ka ng larawan, sinusuri ito ng AI model ng ProduceAIQ at kinakalkula kung gaano ito kasigurado sa uri ng prutas o gulay. Ang numerong iyon (halimbawa: "87% confidence") ay ang sariling antas ng kasiguraduhan ng AI batay sa lahat ng natutunan nito sa paghahambing-hambing.\n\nMGA IMPORMASYON SA KUMPIYANSA SA PRODUKTO(CONFIDENCE LEVEL SA PRODUCE):\n- Kapag umabot sa 90% pataas, awtomatikong tinatanggap ang resulta bilang tama.\n- Kapag mas mababa sa 90% at malaki ang agwat sa susunod na pinakamalapit na hula, hihilingin ng sistema na ulitin ang pag-scan o pumili ng ibang larawan.\n- Kapag mababa sa 75% ang confidence PERO magkalapit ang unang dalawang pinakamataas na hula (mas mababa sa 15 puntos ang agwat), agad na ipapakita ang dalawang posibleng sagot para makapili ka, sa ANUMANG subok ito puwedeng mangyari, hindi lang pagkatapos ng 4 na attempt.\n- Kapag pagkatapos ng 4 na subok ay mababa pa rin ang kumpiyansa at wala namang malapit na pangalawang hula, itinuturing na hindi makilala ang produkto at ipinapasa sa retraining log para sa AI.',

                interactivePreview: _ConfidenceGaugeDemo(),
              ),

              _ExpandableGuideCard(
                icon: Icons.grid_view_rounded,
                iconColor: Color(0xFF16A34A),
                title: 'Anong mga produce ang kaya nitong makilala?',
                body:
                    'Kaya ng ProduceAIQ na makilala ang 11 klase ng sariwang produce: Ampalaya, Saging, Kangkong, Mangga, Papaya, Pinya, Sitaw, Talbos ng Kamote, Talong, at Pakwan. Kung wala sa listahan ang na-scan mo, lalabas itong "others", ito ay normal lamang sapagkat hindi ito nakapasok sa tamang porsiyento ng ibang produce.',
                interactivePreview: _SupportedProduceGrid(),
              ),

              _ExpandableGuideCard(
                icon: Icons.center_focus_strong_rounded,
                iconColor: Color(0xFF0EA5E9),
                title: 'Paano makakakuha ng pinaka-accurate na scan?',
                body:
                    'Isang produce lang sa frame, walang ibang gulay o prutas na kasama. I-fill ang frame ng item, hindi masyadong malayo, hindi rin sobrang lapit na nagbo-blur. Kung pwede, mag-scan sa maliwanag na lugar at iwasan ang malalim na anino. Steady lang ang kamay habang kumukuha para hindi malabo ang litrato.',
                interactivePreview: _ScanningTipsDemo(),
              ),

              _ExpandableGuideCard(
                icon: Icons.help_center_rounded,
                iconColor: Color(0xFFEF4444),
                title: 'Bakit lumalabas na "others"?',
                body:
                    'Nangyayari ito kapag hindi kabilang sa 11 supported types ang na-scan, o kapag masyadong malabo, madilim, o malayo ang litrato para makilala nang maayos. Subukan ulit nang mas malapit at mas maliwanag, isang item lang sa frame. Kung parehong item pa rin at lagi pa ring "unrecognized," baka wala talaga itong support sa loob ng 11 categories.',
                interactivePreview: SizedBox.shrink(),
              ),

              _ExpandableGuideCard(
                icon: Icons.replay_rounded,
                iconColor: Color(0xFF0284C7),
                title: 'Bakit PAREHONG % ang lalabas sa PAREHONG larawan',
                body:
                    'Ang AI ay gumagawa ng eksaktong kalkulasyon batay sa mga pixel ng larawan. Hindi tulad ng tao na may napapansing iba-iba sa bawat tingin, ang AI ay walang pag-aalinlangan; kapag inulit mo ang eksaktong larawan, parehong resulta rin ang lalabas. Kung gusto mo ng IBANG resulta, kailangan mo ng IBANG kuha ng larawan (ibang anggulo, liwanag, o mismong panibagong item).',
                interactivePreview: _ExactMatchDemo(),
              ),
              _ExpandableGuideCard(
                icon: Icons.filter_4_rounded,
                iconColor: Color(0xFF8B5CF6),
                title: 'Bakit nakakakuha ka ng hanggang 4 na subok',
                body:
                    'Kung hindi sapat ang sigurado ng AI sa unang larawan, pinapayagan ka ng ProduceAIQ na sumubok ulit hanggang 4 na beses. Ang mas malinaw na anggulo o liwanag ay nakatutulong nang malaki sa pagsusuri. Kapag umabot sa 90% pataas ang confidence sa isang subok, agad na iyon ang tatanggapin. Kung wala ni isa sa lahat ng subok ang umabot sa 90%, ang pinakamataas na confidence sa lahat ng subok ang siyang gagamitin, hindi lang ang huling larawan. Hindi pinagsasama o ini-average ang mga larawan.',
                interactivePreview: _AttemptsTrackerDemo(),
              ),
              _ExpandableGuideCard(
                icon: Icons.compare_arrows_rounded,
                iconColor: Color(0xFFF59E0B),
                title: 'Ano ang ibig sabihin ng "Alin dito ang tamang item?"',
                body:
                    'Minsan, may dalawang uri ng prutas o gulay na sobrang magkamukha kaya magkalapit ang porsyento ng AI (hal. 48% laban sa 41%) sa halip na may isang malinaw na panalo. Sa halip na magbakasakali at magkamali, ipapakita ng ProduceAIQ ang dalawang pinakamalapit na hula upang ikaw mismo ang makapili at makakumpirma ng tama. Kung ikaw mismo ay nag-aalinlangan sa pagpili, maaaring piliin ang opsiyon na "Ipakita ang Pagkakaiba" o "Hindi ako Sigurado".',
                interactivePreview: _DisambiguationDemo(),
              ),

              _ExpandableGuideCard(
                icon: Icons.thumb_down_alt_outlined,
                iconColor: Color(0xFFDB2777),
                title: 'Ano ang gagawin ko kung mali ang nakilala ng app?',
                body:
                    'Kapag lumabas ang disambiguation prompt, piliin lang ang tamang produce sa mga choices na ibinigay. Kung tama pala ang unang guess pero gusto mo pang i-verify, i-retry ang scan gamit ang mas malinaw na litrato. Ang bawat correction mo ay tumutulong para mas gumaling pa ang app sa susunod, dahil napupunta ito sa retraining log.',
                interactivePreview: SizedBox.shrink(),
              ),

              _ExpandableGuideCard(
                icon: Icons.eco_rounded,
                iconColor: Color(0xFF059669),
                title: 'Tungkol sa Freshness badge',
                body:
                    'Ang status na Unripe(Hilaw), Ripe(Hinog), Overripe(Sobrang Hinog), o Rotten(Bulok) ay nagmumula sa AI model o sa pagsusuri ng kulay at balat bilang fallback. I-tap at pakidiinan ang pindo sa maliit na icon na may (?) sa tabi ng badge upang makita kung paano ito nakuha. Magkaiba ang Sobrang Hinog at Bulok: ang Sobrang Hinog ay puwede pa ring iluto (ipapakita ang mga angkop na resipe), habang ang Bulok naman ay hindi na ligtas kainin kaya itatago ang resipe at magpapakita ng babala na itapon na ito.',
                interactivePreview: _FreshnessSelectorDemo(),
              ),

              _ExpandableGuideCard(
                icon: Icons.local_dining_rounded,
                iconColor: Color(0xFFCA8A04),
                title: 'Saan galing ang nutrition info, gaano ito ka-accurate?',
                body:
                    'Direkta itong hango mula sa Philippine Food Composition Table (FNRI), hindi generic o foreign na database, kaya angkop ito sa mga lokal na variety ng produce na ibinebenta dito sa Pilipinas. Tandaan lang na estimate pa rin ito batay sa average values ng FNRI, kaya maaaring bahagyang magbago depende sa laki, tagal ng imbak, at kondisyon ng partikular na piraso.',
                interactivePreview: SizedBox.shrink(),
              ),

              _ExpandableGuideCard(
                icon: Icons.wifi_off_rounded,
                iconColor: Color(0xFF64748B),
                title: 'Gumagana ba ito offline?',
                body:
                    'Ang pag-scan at pag-classify ng produce ay tumatakbo diretso sa phone mo gamit ang on-device na model, kaya gumagana ito kahit walang internet. Gayunpaman, kinakailangan parin ng internet connection para sa Ai-recipe Suggestions.',
                interactivePreview: SizedBox.shrink(),
              ),

              _ExpandableGuideCard(
                icon: Icons.school_rounded,
                iconColor: Color(0xFFEC4899),
                title: 'Mababang confidence? Hindi ibig sabihing sira ang app',
                body:
                    'Ang AI ay sinanay gamit ang mga totoong larawan na malinaw at nakikita. Kung ito ay malabo, madilim, o binago ang kulay ng imahe, maaaring bumaba ang porsyento ng AI. Ang mababang confidence sa kakaibang larawan ay tapat na pahiwatig ng AI na hindi ito sigurado, at hindi ibig sabihing may sira ang app.',
                interactivePreview: _ScanningTipsDemo(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplayIntroCard extends StatelessWidget {
  const _ReplayIntroCard();

  void _replay(BuildContext context) async {
    await replayTourFromElsewhere(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _replay(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10B981).withValues(alpha: 0.14)
                : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.slideshow_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ulitin ang Panimulang Gabay',
                      style: AppText.body(
                        size: 15,
                        weight: FontWeight.w700,
                        color: MarketPalette.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Balikan ang maikling gabay para sa mga bagong user.',
                      style: AppText.body(
                        size: 12,
                        color: MarketPalette.textBody(context),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF10B981),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableGuideCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget interactivePreview;
  final bool initiallyExpanded;
  final String? linkUrl;
  final bool isOutdated;
  final String? outdatedNote;

  const _ExpandableGuideCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.interactivePreview,
    this.initiallyExpanded = false,
    this.linkUrl,
    this.isOutdated = false,
    this.outdatedNote,
  });

  @override
  State<_ExpandableGuideCard> createState() => _ExpandableGuideCardState();
}

class _ExpandableGuideCardState extends State<_ExpandableGuideCard> {
  late bool _isExpanded;
  late bool _hasExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _hasExpanded = _isExpanded;
  }

  Future<void> _openLink(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Hindi mabuksan ang link.')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Hindi mabuksan ang link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? MarketPalette.surface(context).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isExpanded
              ? widget.iconColor.withValues(alpha: 0.5)
              : (isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFE5E7EB)),
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (widget.isOutdated) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark
                  ? const Color(0xFF78350F)
                  : const Color(0xFFFEF3C7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isDark
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFB45309),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.outdatedNote ??
                          'Hindi na updated ang gabay na ito.',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                  _hasExpanded = true;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w700,
                          color: MarketPalette.textPrimary(context),
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: widget.iconColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: !_hasExpanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(height: 1, thickness: 0.8),
                        const SizedBox(height: 14),

                        widget.interactivePreview,

                        const SizedBox(height: 14),

                        widget.linkUrl == null
                            ? Text(
                                widget.body,
                                style: AppText.body(
                                  size: 13,
                                  color: MarketPalette.textBody(context),
                                ).copyWith(height: 1.55),
                              )
                            : InkWell(
                                onTap: () => _openLink(widget.linkUrl!),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          widget.body,
                                          style: AppText.body(
                                            size: 13,
                                            color: const Color(0xFF10B981),
                                            weight: FontWeight.w600,
                                          ).copyWith(
                                            decoration: TextDecoration.underline,
                                            height: 1.55,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ConfidenceGaugeDemo extends StatefulWidget {
  const _ConfidenceGaugeDemo();

  @override
  State<_ConfidenceGaugeDemo> createState() => _ConfidenceGaugeDemoState();
}

class _ConfidenceGaugeDemoState extends State<_ConfidenceGaugeDemo> {
  double _confidence = 0.67;

  Widget _buildThresholdRow(
    BuildContext context,
    String text,
    bool active,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: active ? color : (Theme.of(context).brightness == Brightness.dark
                ? Colors.white38
                : Colors.black38),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppText.body(
                size: 11,
                weight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? MarketPalette.textPrimary(context)
                    : MarketPalette.textBody(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF170C2A) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'I-drag ang slider upang makita ang threshold behavior:',
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w600,
                  color: MarketPalette.textPrimary(context),
                ),
              ),
              Text(
                '${(_confidence * 100).round()}% confidence',
                style: AppText.body(
                  size: 11,
                  color: const Color(0xFF8B5CF6),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF8B5CF6),
              inactiveTrackColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              thumbColor: const Color(0xFF8B5CF6),
              overlayColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: _confidence,
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: (v) => setState(() => _confidence = v),
            ),
          ),
          const SizedBox(height: 12),
          _buildThresholdRow(
            context,
            '>= 90%: Awtomatikong tanggap',
            _confidence >= 0.90,
            const Color(0xFF10B981),
          ),
          _buildThresholdRow(
            context,
            '75-89%: Disambiguation kung malapit ang 2nd guess (<15 pts)',
            _confidence >= 0.75 && _confidence < 0.90,
            const Color(0xFF16A34A),
          ),
          _buildThresholdRow(
            context,
            '< 75%: Hihilingin ulit ang scan (max 4 subok)',
            _confidence < 0.75,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
    }
  }

class _ExactMatchDemo extends StatelessWidget {
  const _ExactMatchDemo();

  Widget _buildSide(BuildContext context, String title, String result, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.body(
              size: 11,
              weight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              color: MarketPalette.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A2E) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSide(
                  context,
                  'Unang Scan',
                  '76% confidence\nMANGO',
                  const Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFF8B5CF6),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSide(
                  context,
                  'Parehong Larawan (Ulit)',
                  '76% confidence\nMANGO',
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded,
                    color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kung gusto mo ng ibang resulta, kailangan mo ng IBANG kuha (ibang anggulo, liwanag, o ibang item).',
                    style: AppText.body(
                      size: 11,
                      color: const Color(0xFF8B5CF6),
                      weight: FontWeight.w600,
                    ),
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

class _AttemptsTrackerDemo extends StatefulWidget {
  const _AttemptsTrackerDemo();

  @override
  State<_AttemptsTrackerDemo> createState() => _AttemptsTrackerDemoState();
}

class _AttemptsTrackerDemoState extends State<_AttemptsTrackerDemo> {
  int _currentAttempt = 2;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF170C2A) : const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'I-tap para subukan ang slots:',
                style: AppText.body(
                  size: 11,
                  weight: FontWeight.w600,
                  color: MarketPalette.textPrimary(context),
                ),
              ),
              Text(
                'Subok: $_currentAttempt / 4',
                style: AppText.body(
                  size: 11,
                  color: const Color(0xFF8B5CF6),
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              final isDone = index < _currentAttempt;
              return InkWell(
                onTap: () => setState(() => _currentAttempt = index + 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.18)
                        : (isDark ? const Color(0xFF2D1B4E) : const Color(0xFFF0E9FF)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      width: isDone ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDone ? Icons.check_rounded : Icons.close_rounded,
                        color: isDone
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Subok ${index + 1}',
                        style: AppText.body(
                          size: 9,
                          weight: FontWeight.w600,
                          color: isDone
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          if (_currentAttempt == 4)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Huling subok - pinakamataas na confidence ang gagamitin',
                    style: AppText.body(
                      size: 10,
                      color: const Color(0xFFF59E0B),
                      weight: FontWeight.w600,
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

class _DisambiguationDemo extends StatefulWidget {
  const _DisambiguationDemo();

  @override
  State<_DisambiguationDemo> createState() => _DisambiguationDemoState();
}

class _DisambiguationDemoState extends State<_DisambiguationDemo> {
  int _selectedIndex = -1;

  final List<Map<String, dynamic>> _options = [
    {'label': 'MANGO', 'confidence': 48, 'color': Color(0xFFF59E0B)},
    {'label': 'PAPAYA', 'confidence': 41, 'color': Color(0xFF10B981)},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D1A0F) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'AI nag-alinlangan: dalawa ang malapit na hula',
            style: AppText.body(
              size: 11,
              weight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _options.map((opt) {
              final idx = _options.indexOf(opt);
              final isSelected = _selectedIndex == idx;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = idx),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? opt['color'].withValues(alpha: 0.2)
                          : (isDark ? const Color(0xFF3D2A0F) : const Color(0xFFFFF3D1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? opt['color'] : opt['color'].withValues(alpha: 0.4),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          opt['label'],
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: MarketPalette.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${opt['confidence']}% confidence',
                          style: AppText.body(
                            size: 12,
                            weight: FontWeight.w700,
                            color: opt['color'],
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(height: 6),
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF10B981), size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility_rounded, size: 16),
                  label: const Text('Ipakita ang Pagkakaiba'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.help_outline_rounded, size: 16),
                  label: const Text('Hindi ako Sigurado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFF64748B)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    }
  }

class _FreshnessSelectorDemo extends StatefulWidget {
  const _FreshnessSelectorDemo();

  @override
  State<_FreshnessSelectorDemo> createState() => _FreshnessSelectorDemoState();
}

class _FreshnessSelectorDemoState extends State<_FreshnessSelectorDemo> {
  int _selectedIndex = 1;

  final List<Map<String, dynamic>> _statuses = [
    {
      'label': 'Hilaw',
      'color': const Color(0xFF10B981),
      'desc': 'Puwede pang iimbak.',
    },
    {
      'label': 'Hinog',
      'color': const Color(0xFF059669),
      'desc': 'Pinakamainam kainin ngayon.',
    },
    {
      'label': 'Sobrang Hinog',
      'color': const Color(0xFFF59E0B),
      'desc': 'Maganda para sa resipe/luto.',
    },
    {
      'label': 'Bulok',
      'color': const Color(0xFFEF4444),
      'desc': 'Hindi na ligtas, itapon na.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = _statuses[_selectedIndex];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF061A12) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_statuses.length, (idx) {
                final item = _statuses[idx];
                final isSelected = idx == _selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      item['label'],
                      style: AppText.body(
                        size: 11,
                        weight: FontWeight.w700,
                        color: isSelected ? Colors.white : item['color'],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: item['color'],
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: item['color']),
                    onSelected: (_) => setState(() => _selectedIndex = idx),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: current['color'].withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: current['color'].withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: current['color'].withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.circle_rounded,
                      color: current['color'], size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current['label'],
                        style: AppText.body(
                          size: 15,
                          weight: FontWeight.w800,
                          color: current['color'],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        current['desc'],
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
          ),
        ],
      ),
    );
    }
  }



class _VideoWalkthroughDemo extends StatefulWidget {
  const _VideoWalkthroughDemo();

  @override
  State<_VideoWalkthroughDemo> createState() => _VideoWalkthroughDemoState();
}

class _VideoWalkthroughDemoState extends State<_VideoWalkthroughDemo> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/how_it_works.mp4')
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    _controller.setLooping(true);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }
}

class _ScanningTipsDemo extends StatelessWidget {
  const _ScanningTipsDemo();

  Widget _buildCheckRow(
    BuildContext context,
    IconData icon,
    String label,
    bool isGood,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          isGood ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppText.body(
              size: 11,
              weight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF831843),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF220815) : const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          _buildCheckRow(
            context,
            Icons.wb_sunny_rounded,
            'Malinaw at may sapat na liwanag',
            true,
          ),
          const SizedBox(height: 6),
          _buildCheckRow(
            context,
            Icons.blur_off_rounded,
            'Iwasan ang malabo o matinding galaw',
            false,
          ),
        ],
      ),
    );
    }
  }

class _SupportedProduceGrid extends StatelessWidget {
  const _SupportedProduceGrid();

  void _showNutritionBottomSheet(
    BuildContext context,
    ProduceItem item,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF091F15) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Brand.emerald, Brand.emeraldDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.commonName,
                            style: AppText.display(
                              size: 20,
                              color: MarketPalette.textPrimary(context),
                            ),
                          ),
                          Text(
                            item.scientificName,
                            style: AppText.body(
                              size: 12,
                              color: MarketPalette.textBody(context),
                            ).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Text(
                      'NUTRISYON (per 100g)',
                      style: AppText.body(
                        size: 12,
                        weight: FontWeight.w800,
                        color: MarketPalette.textBody(context),
                      ).copyWith(letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 12),
                    ...item.nutrition.entries.map((e) {
                      final label = _formatNutritionLabel(e.key);
                      final value = e.value.toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF102A1C).withValues(alpha: 0.5)
                              : const Color(0xFFD1FAE5).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: AppText.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: MarketPalette.textPrimary(context),
                                ),
                              ),
                            ),
                            Text(
                              value,
                              style: AppText.body(
                                size: 15,
                                weight: FontWeight.w700,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    if (item.shelfLife.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Shelf life: ${item.shelfLife}',
                                style: AppText.body(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: MarketPalette.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (item.recipes.isNotEmpty) ...[
                      Text(
                        'MGA RESIPE',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w800,
                          color: MarketPalette.textBody(context),
                        ).copyWith(letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      ...item.recipes.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.restaurant_rounded,
                                size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r,
                                style: AppText.body(
                                  size: 13,
                                  color: MarketPalette.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    if (item.overripeRecipes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'PARA SA OVERRIPE (Sobrang Hinog)',
                        style: AppText.body(
                          size: 12,
                          weight: FontWeight.w800,
                          color: const Color(0xFFF59E0B),
                        ).copyWith(letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      ...item.overripeRecipes.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department_rounded,
                                size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r,
                                style: AppText.body(
                                  size: 13,
                                  color: MarketPalette.textPrimary(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFCA8A04).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFFCA8A04),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pinagmulan: Philippine Food Composition Table (FNRI/DOST)',
                            style: AppText.body(
                              size: 11,
                              color: const Color(0xFFCA8A04),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatNutritionLabel(String key) {
    switch (key) {
      case 'calories_kcal':
        return 'Kalori (kcal)';
      case 'carbs_g':
        return 'Carbohydrates (g)';
      case 'vitamin_c_mg':
        return 'Vitamin C (mg)';
      case 'vitamin_a_mcg':
        return 'Vitamin A (mcg RAE)';
      case 'iron_mg':
        return 'Iron (mg)';
      case 'fiber_g':
        return 'Fiber (g)';
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allProduce = produceRepository.getAllProduce();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF061A12) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.3),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: allProduce
            .map(
              (item) {
                return ActionChip(
                  label: Text(
                    item.commonName,
                    style: AppText.body(
                      size: 11,
                      weight: FontWeight.w600,
                      color: MarketPalette.textPrimary(context),
                    ),
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF16A34A).withValues(alpha: 0.18)
                      : const Color(0xFFDCFCE7),
                  side: BorderSide(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () => _showNutritionBottomSheet(context, item, isDark),
                );
              },
            )
            .toList(),
      ),
    );
  }
}
