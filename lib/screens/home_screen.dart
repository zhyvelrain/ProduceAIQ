import 'package:flutter/material.dart';
import 'package:produceaiq/screens/onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../theme/brand.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'how_it_works_screen.dart';
import 'terms_screen.dart';
import 'tour_targets.dart';
import '../services/connectivity_service.dart';

class HomeScreen extends StatefulWidget {
  final bool showOtherRedPrompt;

  const HomeScreen({super.key, this.showOtherRedPrompt = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ConnectivityService _connectivity = ConnectivityService();
  bool _showOtherPrompt = false;

  @override
  void initState() {
    super.initState();
    _showOtherPrompt = widget.showOtherRedPrompt;
    // Register this screen's context so the walkthrough can be replayed
    // from Settings or the Guide.
    registerHomeContext(context);
    // Start the first-run walkthrough on a fresh install. It is a no-op on
    // every launch after the first because hasCompletedTour() then returns
    // true and _autoStartInitiated guards against a second run in the same
    // process. The async call is scheduled for the first frame so the
    // walkthrough's targets (GlobalKeys on this screen) have real bounds
    // when they are resolved.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startOnboardingTour(context);
      // If a walkthrough was queued while the splash transition was animating,
      // Home's controls are now settled so we can start it now.
      // We check after the splash transition completes (500ms) because the first
      // call to startOnboardingTour may have set the queue flag, but the targets
      // still won't have bounds until the transition completes.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && isTourQueued) {
          startOnboardingTour(context);
        }
      });
      // Show the "other" prompt dialog once if the flag was passed.
      if (_showOtherPrompt) {
        _showOtherPromptDialog();
      }
    });
    // Listen to connectivity changes so the offline indicator updates
    // live as the device comes online or goes offline.
    _connectivity.onStatusChanged.listen((status) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    registerHomeContext(null);
    super.dispose();
  }

  void _showOtherPromptDialog() {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => _OtherRedPromptDialog(
            onDismiss: () {
              Navigator.of(dialogContext).pop();
              setState(() => _showOtherPrompt = false);
            },
            onScanAgain: () {
                                      Navigator.of(dialogContext).pop();
                                      setState(() => _showOtherPrompt = false);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const ScannerScreen()),
                                      );
                                    },
          ),
        );
      }

      @override
            Widget build(BuildContext context) {
              // While the walkthrough is on screen it owns the back button: back should
              // close the walkthrough, not leave Home. The walkthrough itself cannot do
              // this -- it lives in a root OverlayEntry with no ModalRoute ancestor, so a
              // PopScope there would never register.
              return ValueListenableBuilder<bool>(
                valueListenable: tourIsActive,
                builder: (context, tourUp, _) => PopScope(
                  canPop: !tourUp,
                  onPopInvokedWithResult: (didPop, _) {
                    if (!didPop && tourUp) dismissActiveTour();
                  },
                  child: _buildScaffold(context),
                ),
              );
            }

            Widget _buildScaffold(BuildContext context) {
                          return Scaffold(
                            bottomNavigationBar: const _BottomBar(),
                            body: BrandBackground(
                              child: SafeArea(
                                child: Column(
                                  children: [
                                    // Top appbar with logo and compact connectivity indicator
                                    _CompactAppBar(),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            // Hero scan card -- the one action the app exists for.
                                            _ScanCard(key: TourTargets.scanCard),
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
                        }

                        // =============================================================================
                        // COMPACT APP BAR (logo + connectivity indicator)
                        // =============================================================================

                        class _CompactAppBar extends StatelessWidget {
                          const _CompactAppBar();

                          @override
                          Widget build(BuildContext context) {
                            final isDark = MarketPalette.isDark(context);
                            return StreamBuilder<String>(
                              stream: ConnectivityService().onStatusChanged,
                              initialData: 'unknown',
                              builder: (context, snapshot) {
                                final isOnline = snapshot.data == 'online';
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? MarketPalette.surface(context).withValues(alpha: 0.95)
                                        : Colors.white.withValues(alpha: 0.95),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? MarketPalette.divider(context)
                                            : Brand.emeraldAt(0.15),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Logo
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Brand.emerald, Brand.emeraldDeep],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Brand.emeraldAt(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      // App name and tagline
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              text: TextSpan(
                                                style: AppText.display(
                                                  size: 20,
                                                  color: MarketPalette.textPrimary(context),
                                                ),
                                                children: const [
                                                  TextSpan(text: 'Produce'),
                                                  TextSpan(
                                                    text: 'AIQ',
                                                    style: TextStyle(
                                                      color: Color(0xFFF59E0B),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                                                                          'Prutas at gulay, agad nakikilala',
                                                                                          style: AppText.body(
                                                                                            size: 12,
                                                                                            color: MarketPalette.textBody(context),
                                                                                          ),
                                                                                        ),
                                          ],
                                        ),
                                      ),
                                      // Compact connectivity indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? (isDark ? Brand.emeraldAt(0.15) : Brand.emeraldSoft)
                                              : (isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red[50]),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isOnline
                                                ? Brand.emeraldAt(0.3)
                                                : Colors.red.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                                              size: 12,
                                              color: isOnline ? Brand.emerald : Colors.red,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOnline ? 'Online' : 'Offline',
                                              style: AppText.body(
                                                size: 11,
                                                weight: FontWeight.w600,
                                                color: isOnline
                                                    ? (isDark ? const Color(0xFF6EE7B7) : Brand.emeraldDeep)
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }
                        }

                        // =============================================================================
                        // SCAN CARD
// =============================================================================

/// The hero card: what the app does, and the one button that starts it.
class _ScanCard extends StatelessWidget {
  const _ScanCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Brand.emerald, Brand.emeraldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Scan Produce',
                  style: AppText.display(
                    size: 22,
                    color: MarketPalette.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
                      'Kumuha ng litrato, o mag-upload ng hanggang apat (4) na larawan '
                      'ng prutas o gulay upang malaman ang kasariwaan at resipe.',
                      style: AppText.body(
                        size: 13.5,
                        color: MarketPalette.textBody(context),
                      ).copyWith(height: 1.45),
                    ),
          const SizedBox(height: 18),

          // Big Prominent Action Button
          Material(
                      key: TourTargets.scanButton,
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => const ScannerScreen()),
                                                ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Brand.emerald, Brand.emeraldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Brand.emeraldAt(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    // Flexible so the label shrinks instead of overflowing the
                    // row. Without it, a large system text scale (or the wider
                    // fallback font google_fonts uses when it cannot reach the
                    // network) pushes this row past the button and paints the
                    // yellow/black overflow stripe.
                    Flexible(
                      child: Text(
                        'SIMULAN ANG PAG-SCAN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: AppText.button(size: 17).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  }

  /// Dialog shown when the model returns "other" (not one of the 10 curated classes).
/// It presents a prominent red card with the explanation and two actions:
/// - "SCAN AGAIN" goes to ScannerScreen
/// - "OK" dismisses and stays on Home to scan again via the main Scan card
class _OtherRedPromptDialog extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onScanAgain;

  const _OtherRedPromptDialog({
    required this.onDismiss,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFDC2626),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 8),
              spreadRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large cancel icon in a circle
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel_rounded,
                size: 52,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 18),
            // Main title
            Text(
              'Hindi Namin Nakilala Ito',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            // Description
            Text(
              'Ang larawang ito ay hindi isa sa aming 10 katutubong kategorya:\n'
              'Saging, Mangga, Papaya, Pinya, Pakwan, Ampalaya, Kangkong, '
              'Sitaw, Talong, at Talbos ng Kamote.\n\n'
              'Kaya hindi maipapakita ang impormasyon tungkol sa nutrisyon, '
              'kasariwaan, at reseta.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.red[200] : const Color(0xFF7F1D1D),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(
                        color: Color(0xFFDC2626),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onDismiss,
                    child: Text(
                      'OK',
                      style: AppText.button(size: 16).copyWith(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.5),
                    ),
                    onPressed: onScanAgain,
                    child: Text(
                      'I-SCAN ULIT',
                      style: AppText.button(size: 16).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  }

  // =============================================================================
  // BOTTOM BAR
  // =============================================================================

  /// Persistent 4-item Bottom Navigation Bar (Tagalog labels)
  class _BottomBar extends StatelessWidget {
    const _BottomBar();

    @override
    Widget build(BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? MarketPalette.surface(context).withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? MarketPalette.divider(context)
                    : Brand.emeraldAt(0.2),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
                          // 1. Simula (Scan)
                          Expanded(
                            child: _BottomBarItem(
                              key: TourTargets.scanTab,
                              icon: Icons.qr_code_scanner_rounded,
                              label: 'Simula',
                              active: true,
                              onTap: () {},
                            ),
                          ),

                          // 2. Mga Tuntunin (Terms)
                                                                              Expanded(
                                                                                child: _BottomBarItem(
                                                                                  key: TourTargets.termsTab,
                                                                                  icon: Icons.description_rounded,
                                                                                  label: 'Tuntunin',
                                                                                  active: false,
                                                                                  onTap: () => Navigator.push(
                                                                                    context,
                                                                                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                                                                                  ),
                                                                                ),
                                                                              ),

                                                    // 3. Gabay (Guide)
                                                    Expanded(
                                                      child: _BottomBarItem(
                                                        key: TourTargets.guideTab,
                                                        icon: Icons.menu_book_rounded,
                                                        label: 'Gabay',
                                                        active: false,
                                                        onTap: () => Navigator.push(
                                                          context,
                                                          MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                                                        ),
                                                      ),
                                                    ),

                          // 4. Settings
                          Expanded(
                            child: _BottomBarItem(
                              key: TourTargets.settingsTab,
                              icon: Icons.settings_rounded,
                              label: 'Settings',
                              active: false,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ),
                        ],
          ),
        ),
      );
    }
  }

  class _BottomBarItem extends StatelessWidget {
    final IconData icon;
    final String label;
    final bool active;
    final VoidCallback onTap;

    const _BottomBarItem({
      super.key,
      required this.icon,
      required this.label,
      required this.active,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final activeColor = Brand.emerald;
      final inactiveColor = MarketPalette.textMuted(context);

      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          // Reduced from 24: three of these plus their labels overflow the bar at
          // large system text scales, which paints the overflow stripe.
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? activeColor : inactiveColor, size: 26),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 12,
                  weight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }