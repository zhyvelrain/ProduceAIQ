import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'how_it_works_screen.dart';
import 'tour_targets.dart';

/// SharedPreferences flag marking the first-run walkthrough as completed.
///
/// Deliberately kept under its original key name so an already-installed build
/// keeps its "already seen" state and does not re-show the walkthrough after
/// this update.
const String kOnboardingDoneKey = 'onboarding_done_v1';

/// SharedPreferences flag marking Terms & Conditions as accepted.
const String kTermsAcceptedKey = 'terms_accepted_v1';

/// SharedPreferences flag marking the scanner onboarding dialog as seen.
const String kScannerOnboardingSeenKey = 'scanner_onboarding_seen_v1';

/// True once the walkthrough has been finished or skipped at least once.
///
/// A storage failure reports `false` -- i.e. "not yet seen" -- so the
/// walkthrough still appears on a fresh install even if the preferences store
/// cannot be read. Reporting `true` here would silently swallow the first-run
/// walkthrough, which is exactly the behaviour it exists to guarantee; the
/// worst case of reporting `false` is the walkthrough showing one extra time.
Future<bool> hasCompletedTour() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingDoneKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Checks if user has accepted Terms & Conditions.
Future<bool> hasAcceptedTerms() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kTermsAcceptedKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Records that the walkthrough has been seen. Failures are non-fatal: the
/// walkthrough simply appears again on the next launch.
Future<void> markTourCompleted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDoneKey, true);
  } catch (_) {
    // Ignored on purpose -- see the doc comment.
  }
}

/// Records that Terms & Conditions have been accepted.
Future<void> markTermsAccepted() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kTermsAcceptedKey, true);
  } catch (_) {
    // Ignored on purpose.
  }
}

/// Checks if user has seen the scanner onboarding dialog.
Future<bool> hasSeenScannerOnboarding() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kScannerOnboardingSeenKey) ?? false;
  } catch (_) {
    return false;
  }
}

/// Records that the scanner onboarding dialog has been seen.
Future<void> markScannerOnboardingSeen() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kScannerOnboardingSeenKey, true);
  } catch (_) {
    // Ignored on purpose.
  }
}


Future<void> clearOnboardingCache() async {
  /// Clears the onboarding completion flag from shared_preferences.
  ///
  /// Call this when the user wants to reset their on-boarding state (e.g.
  /// fresh install, manual reset, or clearing app data). This ensures the
  /// first-run walkthrough appears on the next launch.
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kOnboardingDoneKey);
    await prefs.remove(kScannerOnboardingSeenKey);
  } catch (_) {
    // If we cannot access shared_preferences, the flag is effectively gone.
  }
}

/// Clears only the scanner onboarding flag (for testing).
Future<void> clearScannerOnboardingCache() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kScannerOnboardingSeenKey);
  } catch (_) {}
}

/// Starts the walkthrough on Home the first time it is called after a fresh
/// install, if it has not already been completed. Idempotent: safe to call any
/// number of times (from the Guide or Settings) with no effect once the tour
/// has run.
///
/// [_autoStartInitiated] is reset when the app is restarted, so a genuinely
/// fresh install (no `onboarding_done_v1` key) re-shows the tour while a
/// re-install/update that already records the flag skips it.
bool _autoStartInitiated = false;

/// Starts the first-run walkthrough on Home if this is a fresh install.
///
/// Call this from HomeScreen's initState (after the first frame) so the
/// tour's targets have real bounds. It is a no-op on every launch after the
/// first: if the user already completed the tour the flag stays set and the
/// walkthrough is not re-shown.
Future<void> startOnboardingTour(BuildContext context) async {
  if (_autoStartInitiated) return;
  if (tourIsActive.value) return;
  final completed = await hasCompletedTour();
  if (completed) return;

  // The context comes from HomeScreen's post-frame callback; it is valid for
  // this frame. Guard against the unlikely case where the widget was disposed
  // between the post-frame scheduling and this point by checking if we can
  // still resolve an Overlay from it.
  // ignore: use_build_context_synchronously
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  // Try to start the guided tour. If targets aren't ready yet, startGuidedTour
  // queues the request and returns false. We only mark auto-start as initiated
  // if the tour actually begins (openGuide returned), so the queued retry in
  // HomeScreen's delayed callback can still run.
  // ignore: use_build_context_synchronously
  final openGuide = await startGuidedTour(context);
  if (openGuide) {
    _autoStartInitiated = true;
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
      );
    }
  }
  // If !openGuide, the tour was queued (_tourRequested = true). Do NOT set
  // _autoStartInitiated -- let HomeScreen's delayed callback retry.
}

/// The overlay entry currently hosting the walkthrough, if any.
OverlayEntry? _activeTourEntry;

/// Closes the walkthrough currently on screen, if any, without marking it
/// completed.
///
/// Needed because the walkthrough lives in a root [OverlayEntry]: such an entry
/// has no [ModalRoute] ancestor, so a [PopScope] inside it never registers and
/// the system back button cannot be handled from within the walkthrough itself.
/// [HomeScreen] -- which *is* inside a route -- calls this from its own
/// [PopScope] instead.
void dismissActiveTour() {
  _activeTourAbandon?.call();
}

VoidCallback? _activeTourAbandon;

/// True while a walkthrough is on screen. HomeScreen listens to this so it can
/// take over the system back button for as long as the walkthrough is up.
final ValueNotifier<bool> tourIsActive = ValueNotifier<bool>(false);

/// Set when something asked for the walkthrough while Home was still on screen
/// but its controls were not laid out yet (i.e. during the splash's route
/// transition).
///
/// The walkthrough cannot start until at least one of its targets has real
/// bounds. Starting it earlier makes its very first post-frame check find no
/// target and finish immediately, so the first-run walkthrough silently never
/// appeared. Queuing instead lets Home run it on the first frame Home is
/// actually settled, which is exactly the case this guards.
bool _tourRequested = false;

/// Home's own [BuildContext], published by [HomeScreen] while it is mounted.
///
/// This is deliberately *not* `Navigator.of(context).context`: the Navigator's
/// context sits above the app's [Overlay] in the widget tree, so
/// `Overlay.maybeOf` finds nothing there and the walkthrough could never start
/// when launched from Settings or the Guide. Home's own context is inside the
/// Overlay, so it works.
BuildContext? _homeContext;

/// Called by [HomeScreen] when it mounts/unmounts so the walkthrough can be
/// replayed from other screens.
void registerHomeContext(BuildContext? context) {
  _homeContext = context;
}

/// True when at least one control the walkthrough can point at is on screen
/// with real bounds.
///
/// The walkthrough reads a target's rect on its first post-frame callback; if
/// every target is still unlaid-out it finishes immediately instead of showing
/// anything, so this is what decides whether starting now is safe at all.
bool hasAnyTourTarget() {
  for (final step in _tourSteps) {
    final target = step.target;
    if (target != null && TourTargets.rectOf(target) != null) return true;
  }
  return false;
}

/// True when a walkthrough was requested before Home's controls were laid out
/// and is still waiting to be started.
bool get isTourQueued => _tourRequested;

/// Drops a queued walkthrough request without starting it.
void clearTourRequest() => _tourRequested = false;

/// Resets the auto-start guard so the walkthrough can run again.
///
/// Only used in tests; production code never calls this because the guard
/// is naturally reset on process restart.
void resetAutoStartForTesting() {
  _autoStartInitiated = false;
}

/// Starts the inline, interactive walkthrough on top of the screen that is
/// currently showing.
///
/// The walkthrough is an [Overlay] entry rather than a pushed route, so it can
/// point its arrow at the real control on the real screen instead of describing
/// it on a separate page.
///
/// Returns `true` when the user asked for the Guide module from the final step,
/// so the caller can push `HowItWorksScreen`. Returns `false` for every other
/// exit (finish, skip, or a walkthrough that could not start).
Future<bool> startGuidedTour(BuildContext context) async {
  // Never stack two walkthroughs on top of each other. A recorded entry that is
  // no longer mounted belongs to a torn-down overlay (its screen was disposed
  // while the walkthrough was open), so it is stale and must not block a new
  // run -- otherwise reopening the walkthrough would silently stop working.
  final active = _activeTourEntry;
  if (active != null) {
    if (active.mounted) return false;
    _activeTourEntry = null;
  }

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return false;

  // The walkthrough is drawn over this route's controls, so it can only run
  // while that route is the one on top. Starting it while another route is
  // still above Home would strand the overlay over the wrong screen.
  final hostRoute = ModalRoute.of(context);

  // Home's controls must already have real bounds: the walkthrough reads a
  // target's rect on its first post-frame callback, and a target with no rect
  // makes the whole walkthrough finish instantly (see _resolveSteps). Right
  // after a pushReplacement -- e.g. the splash handing over to Home -- the
  // transition is still animating and the targets are not laid out yet, which
  // is exactly when the first-run walkthrough used to vanish.
  //
  // Queue it instead of dropping it: Home drains this on its next settled frame
  // and starts the walkthrough then.
  if (!hasAnyTourTarget()) {
    _tourRequested = true;
    return false;
  }

  _tourRequested = false;

  final completer = Completer<bool>();
  late final OverlayEntry entry;

  void finish(bool openGuide) {
    if (_activeTourEntry == entry) _activeTourEntry = null;
    _activeTourAbandon = null;
    tourIsActive.value = false;
    if (entry.mounted) entry.remove();
    if (!completer.isCompleted) completer.complete(openGuide);
  }

  // Let HomeScreen close the walkthrough on the system back button, and let it
  // know a walkthrough is up so it can intercept back while it is.
  _activeTourAbandon = () {
    if (entry.mounted) entry.remove();
    if (!completer.isCompleted) completer.complete(false);
    if (_activeTourEntry == entry) _activeTourEntry = null;
    _activeTourAbandon = null;
    tourIsActive.value = false;
  };
  tourIsActive.value = true;

  entry = OverlayEntry(
    builder: (_) => _GuidedTour(onFinished: finish, hostRoute: hostRoute),
  );
  _activeTourEntry = entry;
  overlay.insert(entry);

  return completer.future;
}

/// Re-runs the walkthrough from somewhere other than Home -- the Guide's
/// "Ulitin" card, or Settings.
///
/// The walkthrough points its arrows at Home's controls, so it can only run
/// while Home is the visible screen. This returns to Home first, then starts the
/// walkthrough once Home's controls are actually laid out again.
///
/// Returns `true` when the user asked for the Guide from the final step.
Future<bool> replayTourFromElsewhere(BuildContext callerContext) async {
  final navigator = Navigator.of(callerContext);
  final homeContext = _homeContext;
  if (homeContext == null || !homeContext.mounted) return false;

  // Leave whatever screen we were on (Settings, the Guide) so Home is visible.
  // Popping is animated, so wait for the transition to finish and for Home's
  // controls to be laid out again before asking for their bounds.
  if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      for (var attempt = 0; attempt < 60; attempt++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!homeContext.mounted) return false;
        if (TourTargets.rectOf(TourTargets.scanTab) != null) break;
      }
    }

  if (!homeContext.mounted) return false;
  return startGuidedTour(homeContext);
}

// =============================================================================
// STEP DEFINITIONS
// =============================================================================

/// One stop in the walkthrough.
///
/// [target] is a named key from [TourTargets] -- the Flutter equivalent of a web
/// `data-tour="..."` attribute. A step whose target is not currently on screen
/// is skipped rather than shown pointing at nothing.
///
/// A step with no target renders as a centred card with no arrow.
class _TourStep {
  final GlobalKey? target;
  final String title;
  final String body;

  /// When true this is the closing step, which links out to the Guide module.
  final bool isFinal;

  const _TourStep({
    this.target,
    required this.title,
    required this.body,
    this.isFinal = false,
  });
}

/// The walkthrough's content.
///
/// Shows each module on the home screen: Scan, Terms, Guide, Settings.
/// The detailed explanations stay in the Guide module.
final List<_TourStep> _tourSteps = <_TourStep>[
  _TourStep(
    target: TourTargets.scanCard,
    title: 'Maligayang pagdating sa ProduceAIQ',
    body: 'Dito mo sisimulan ang lahat. Pindutin ang "Mag-scan" para kilalanin ang prutas/gulay, '
        'tingnan ang kasariwaan, at makakuha ng resipe.',
  ),
  _TourStep(
    target: TourTargets.scanButton,
    title: 'Simula \u2014 Mag-scan Button',
    body: 'Ang malaking berdeng button ang pindutin para buksan ang camera at simulan ang pag-scan '
        'ng produce. Ito ang pangunahing aksyon ng app.',
  ),
  _TourStep(
    target: TourTargets.scanTab,
    title: 'Simula \u2014 Pagsisimula ng Scan',
    body: 'Ang "Simula" tab ang iyong pangunahing entry point. Pindutin ang malaking berdeng button '
        'para buksan ang camera at simulan ang pag-scan ng produce.',
  ),
  _TourStep(
    target: TourTargets.termsTab,
    title: 'Mga Tuntunin \u2014 Terms & Conditions',
    body: 'Dito matatagpuan ang Terms of Service, Privacy Policy, at mga limitasyon ng app. '
        'Basahin ito bago magsimula.',
  ),
  _TourStep(
    target: TourTargets.guideTab,
    title: 'Gabay \u2014 Buong Walkthrough',
    body: 'Ang "Gabay" tab ang naglalaman ng detalyadong explanation ng lahat ng feature: '
        'confidence system, freshness grading, nutrition, recipes, at offline mode.',
  ),
  _TourStep(
    target: TourTargets.settingsTab,
    title: 'Settings \u2014 Account at Theme',
    body: 'Dito mo pwedeng baguhin ang theme (Light/Dark/System) at ulitin ang panimulang gabay. '
        'Ang settings ay naka-focus sa personal preference lamang.',
  ),
  _TourStep(
    title: 'Handa ka na',
    body: 'Para sa buong gabay (confidence %, freshness, nutrition, resipe, offline scan), '
        'pindutin ang "Buksan ang Gabay" sa baba.',
    isFinal: true,
  ),
];

// =============================================================================
// WALKTHROUGH WIDGET
// =============================================================================

class _GuidedTour extends StatefulWidget {
  /// Called exactly once when the walkthrough ends. `openGuide` is true when
  /// the user asked for the Guide from the final step.
  final void Function(bool openGuide) onFinished;

  /// The route the walkthrough is drawn over (Home's). Used to notice when
  /// something else is pushed on top, so the walkthrough can close instead of
  /// floating over the wrong screen. Null disables that check.
  final ModalRoute<dynamic>? hostRoute;

  const _GuidedTour({required this.onFinished, this.hostRoute});

  @override
  State<_GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends State<_GuidedTour>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  /// The steps that can actually run: any step whose target is not mounted
  /// (hidden panel, different layout, very small screen) is dropped, so the
  /// "Hakbang X ng N" counter matches what the user will really see.
  ///
  /// Resolved in a post-frame callback rather than in [initState] so the host
  /// screen has definitely been laid out and its targets have real bounds.
  List<_TourStep> _resolved = const <_TourStep>[];

  bool _ready = false;
  int _index = 0;
  Rect? _rect;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSteps());
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _resolveSteps() {
    if (!mounted || _dismissed) return;

    final available = _tourSteps
        .where((s) => s.target == null || TourTargets.rectOf(s.target!) != null)
        .toList(growable: false);

    if (available.isEmpty) {
      // Nothing is laid out yet. During a route transition the targets mount
      // before they have bounds, so give it a few frames rather than finishing
      // immediately -- otherwise the whole walkthrough can vanish before it is
      // ever shown.
      if (_resolveAttempts++ < 20) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _resolveSteps());
        return;
      }
      // Nothing ever became pointable. Abandon (not finish): _finish would
      // record the walkthrough as completed, and since the user never saw a
      // single step, the first-run walkthrough would be lost for good.
      _abandon();
      return;
    }

    setState(() {
      _resolved = available;
      _index = 0;
      _rect = _rectFor(available[0]);
      _ready = true;
    });
    _watchLayout();
  }

  int _resolveAttempts = 0;

  Rect? _rectFor(_TourStep step) =>
      step.target == null ? null : TourTargets.rectOf(step.target!);

  /// True while the screen the walkthrough belongs to is still the one on top.
  ///
  /// When another route is pushed over Home (a notification tap, a deep link,
  /// resuming onto another screen) the dimmed overlay would otherwise keep
  /// floating above the *wrong* screen and its "active" flag would block every
  /// later replay.
  ///
  /// Deliberately only checks for a route *pushed on top* of the host, and never
  /// requires `isCurrent` to be true outright: a route mid-transition can report
  /// `isCurrent == false` for a few frames even though it is the screen being
  /// shown, and treating that as "someone else took over" would abandon a
  /// perfectly good walkthrough.
  bool get _homeIsVisible {
    final route = widget.hostRoute;
    if (route == null) return true; // Route unknown: don't second-guess.
    return route.isCurrent;
  }

  /// Re-reads the current target's bounds after every frame, forever, until the
  /// walkthrough is dismissed.
  ///
  /// Window resizes and orientation changes already rebuild this widget (it
  /// depends on [MediaQuery]); this additionally catches layout shifts such as
  /// scrolling, which do not change [MediaQuery].
  ///
  /// Exactly one chain of post-frame callbacks is kept alive: it re-arms itself
  /// and always reads the *current* step, so switching steps needs no extra
  /// arming and cannot spawn duplicate chains. `setState` is only called when
  /// the bounds actually moved, so it settles instead of rebuilding every frame.
  void _watchLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _dismissed || !_ready) return;

      if (!_homeIsVisible) {
        // Another screen is on top now -- close quietly instead of hovering
        // over it. Not marked completed, so it can still be replayed.
        _abandon();
        return;
      }

      final step = _resolved[_index];
      final next = _rectFor(step);

      if (step.target != null && next == null) {
        // The control went away mid-walkthrough -- skip forward, never crash.
        _goTo(_index + 1);
        return;
      }
      if (next != _rect) {
        setState(() => _rect = next);
      }
      _watchLayout();
    });
  }

  /// Moves to [index], skipping any step whose target is unavailable.
  void _goTo(int index) {
    var i = index;
    while (i < _resolved.length) {
      final step = _resolved[i];
      if (step.target == null || TourTargets.rectOf(step.target!) != null) break;
      i++;
    }
    if (i >= _resolved.length) {
      _finish(false);
      return;
    }
    _settleOn(i);
  }

  /// Moves back to the previous step whose target is still available.
  void _back() {
    var i = _index - 1;
    while (i >= 0) {
      final step = _resolved[i];
      if (step.target == null || TourTargets.rectOf(step.target!) != null) break;
      i--;
    }
    if (i < 0) return;
    _settleOn(i);
  }

  void _settleOn(int index) {
    if (_dismissed || !_ready) return;
    final step = _resolved[index];
    // No need to re-arm the layout watcher: the single running chain always
    // reads the current step and picks the new bounds up on the next frame.
    setState(() {
      _index = index;
      _rect = _rectFor(step);
    });
  }

  void _next() {
    if (_index >= _resolved.length - 1) {
      _finish(false);
      return;
    }
    _goTo(_index + 1);
  }

  void _finish(bool openGuide) {
    if (_dismissed) return;
    _dismissed = true;
    // Fire and forget: the walkthrough closes immediately either way.
    unawaited(markTourCompleted());
    widget.onFinished(openGuide);
  }

  /// Closes the walkthrough without marking it completed.
  ///
  /// Used when the walkthrough is no longer on Home (another route was pushed
  /// over it) or when the user presses back: the tour simply disappears and
  /// stays available to replay, rather than leaving a dimmed overlay floating
  /// over an unrelated screen and blocking every later replay.
  void _abandon() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onFinished(false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _resolved.isEmpty) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final step = _resolved[_index];
    final layout = _rect == null
        ? null
        : _TourLayout.compute(
            screen: media.size,
            safe: media.padding,
            target: _rect!,
          );

    final card = _TourCard(
      step: step,
      index: _index,
      total: _resolved.length,
      maxHeight: layout?.cardMaxHeight ??
          math.max(160, media.size.height - media.padding.vertical - 64),
      onNext: _next,
      onBack: _index > 0 ? _back : null,
      onFinish: _finish,
    );

    // No PopScope here on purpose: this widget lives in a root OverlayEntry,
    // which has no ModalRoute ancestor, so a PopScope would never register.
    // HomeScreen owns the back button instead -- see [dismissActiveTour].
    return _buildOverlay(context, media, step, layout, card);
  }

  Widget _buildOverlay(
    BuildContext context,
    MediaQueryData media,
    _TourStep step,
    _TourLayout? layout,
    Widget card,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 1. Dim everything, cut a hole around the target, and swallow taps
          //    outside the highlight so the user cannot wander off mid-tour.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _TourDimPainter(highlight: _rect),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // 2. Highlight ring around the target.
          if (_rect != null)
            Positioned.fromRect(
              rect: _rect!.inflate(4),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
            ),

          // 3. Transparent catcher over the target, so pressing the real control
                    //    advances the walkthrough. Sits above the dimmer but below the
                    //    arrow and card, which never overlap the target.
                    if (_rect != null && step.target != null && step.isFinal == false)
                      Positioned.fromRect(
                        rect: _rect!,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _next,
                          child: const SizedBox.expand(),
                        ),
                      ),

          // 4. Pulsing arrow pointing at the target.
          if (layout != null && layout.arrowRect != null)
            Positioned.fromRect(
              rect: layout.arrowRect!,
              child: IgnorePointer(
                child: _PulsingArrow(
                  animation: _pulse,
                  direction: layout.arrowDirection!,
                ),
              ),
            ),

          // 5. Explanation card, on whichever side has room.
          if (layout == null)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20 + media.padding.vertical,
                ),
                child: Center(child: card),
              ),
            )
          else
            Positioned(
              left: layout.cardLeft,
              top: layout.cardTop,
              bottom: layout.cardBottom,
              width: layout.cardWidth,
              child: card,
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// PLACEMENT
// =============================================================================

enum _Side { below, above, right, left }

/// Direction the arrow points, i.e. toward the target.
enum _ArrowDirection { up, down, left, right }

/// Where the arrow and the card go for the current target.
///
/// The card is anchored by `top` when it sits below the target and by `bottom`
/// when it sits above it, so the card's intrinsic height never has to be known
/// in advance. [cardMaxHeight] bounds it either way, which is what keeps the
/// card on screen even if its text is longer than expected.
class _TourLayout {
  final Rect? arrowRect;
  final _ArrowDirection? arrowDirection;
  final double cardLeft;
  final double cardWidth;
  final double? cardTop;
  final double? cardBottom;
  final double cardMaxHeight;

  const _TourLayout({
    required this.arrowRect,
    required this.arrowDirection,
    required this.cardLeft,
    required this.cardWidth,
    required this.cardTop,
    required this.cardBottom,
    required this.cardMaxHeight,
  });

  static const double _gap = 14;
  static const double _arrowSize = 32;
  static const double _margin = 16;
  static const double _maxCardWidth = 340;

  /// Rough card height, used only to decide whether a side has *comfortable*
  /// room. The card's real height is intrinsic.
  static const double _estCardHeight = 210;

  /// A side with less room than this is not used at all; the card is centred
  /// instead, which is always on screen.
  static const double _minUsableRoom = 140;

  /// Returns null when no side has usable room, meaning "centre the card".
  static _TourLayout? compute({
    required Size screen,
    required EdgeInsets safe,
    required Rect target,
  }) {
    final safeLeft = safe.left + _margin;
    final safeRight = screen.width - safe.right - _margin;
    final safeTop = safe.top + _margin;
    final safeBottom = screen.height - safe.bottom - _margin;

    final cardWidth = math.min(screen.width - _margin * 2, _maxCardWidth);
    final roomBelow = safeBottom - target.bottom;
    final roomAbove = target.top - safeTop;
    final roomRight = safeRight - target.right;
    final roomLeft = target.left - safeLeft;

    final verticalNeed = _estCardHeight + _gap + _arrowSize;
    final horizontalNeed = cardWidth + _gap + _arrowSize;

    _Side? side;
    if (roomBelow >= verticalNeed) {
      side = _Side.below;
    } else if (roomAbove >= verticalNeed) {
      side = _Side.above;
    } else if (roomRight >= horizontalNeed) {
      side = _Side.right;
    } else if (roomLeft >= horizontalNeed) {
      side = _Side.left;
    }

    if (side == null) {
      // Nothing is comfortable: take the roomiest side if it can hold a usable
      // card, otherwise give up and let the caller centre it.
      final roomiest = <_Side, double>{
        _Side.below: roomBelow,
        _Side.above: roomAbove,
        _Side.right: roomRight,
        _Side.left: roomLeft,
      }.entries.reduce((a, b) => b.value > a.value ? b : a);
      if (roomiest.value < _minUsableRoom) return null;
      side = roomiest.key;
    }

    switch (side) {
      case _Side.below:
      case _Side.above:
        final below = side == _Side.below;
        final left = _clampLeft(
          value: target.center.dx - cardWidth / 2,
          width: cardWidth,
          safeLeft: safeLeft,
          safeRight: safeRight,
        );

        // Arrow sits in the gap between target and card, aligned with the
        // target but kept inside the card's width so it reads as pointing at
        // the card's subject.
        final minX = left + _arrowSize / 2 + 6;
        final maxX = math.max(minX, left + cardWidth - _arrowSize / 2 - 6);
        final arrowCenterX = target.center.dx.clamp(minX, maxX);
        final arrowCenterY = below
            ? target.bottom + _gap / 2 + _arrowSize / 2
            : target.top - _gap / 2 - _arrowSize / 2;

        final top = below ? target.bottom + _gap + _arrowSize : null;
        final bottom =
            below ? null : screen.height - (target.top - _gap - _arrowSize);

        final maxHeight = below
            ? safeBottom - (top ?? 0)
            : (target.top - _gap - _arrowSize) - safeTop;
        if (maxHeight < _minUsableRoom) return null;

        return _TourLayout(
          arrowRect: Rect.fromCenter(
            center: Offset(arrowCenterX, arrowCenterY),
            width: _arrowSize,
            height: _arrowSize,
          ),
          arrowDirection: below ? _ArrowDirection.up : _ArrowDirection.down,
          cardLeft: left,
          cardWidth: cardWidth,
          cardTop: top,
          cardBottom: bottom,
          cardMaxHeight: maxHeight,
        );

      case _Side.right:
      case _Side.left:
        final toRight = side == _Side.right;
        final cardLeft = toRight
            ? target.right + _gap + _arrowSize
            : target.left - _gap - _arrowSize - cardWidth;
        final availableWidth = toRight
            ? safeRight - cardLeft
            : (target.left - _gap - _arrowSize) - safeLeft;
        final width = math.min(cardWidth, availableWidth);
        if (width < _minUsableRoom) return null;

        final top = (target.center.dy - _estCardHeight / 2)
            .clamp(safeTop, math.max(safeTop, safeBottom - _estCardHeight))
            .toDouble();
        final maxHeight = safeBottom - top;
        if (maxHeight < _minUsableRoom) return null;

        final minY = top + _arrowSize / 2 + 6;
        final maxY = math.max(minY, top + _estCardHeight - _arrowSize / 2 - 6);

        return _TourLayout(
          arrowRect: Rect.fromCenter(
            center: Offset(
              toRight
                  ? target.right + _gap / 2 + _arrowSize / 2
                  : target.left - _gap / 2 - _arrowSize / 2,
              target.center.dy.clamp(minY, maxY),
            ),
            width: _arrowSize,
            height: _arrowSize,
          ),
          arrowDirection:
              toRight ? _ArrowDirection.left : _ArrowDirection.right,
          cardLeft: math.max(safeLeft, cardLeft),
          cardWidth: width,
          cardTop: top,
          cardBottom: null,
          cardMaxHeight: maxHeight,
        );
    }
  }

  /// Keeps a horizontal span inside the safe area.
  static double _clampLeft({
    required double value,
    required double width,
    required double safeLeft,
    required double safeRight,
  }) {
    final maxLeft = math.max(safeLeft, safeRight - width);
    return value.clamp(safeLeft, maxLeft).toDouble();
  }
}

// =============================================================================
// PIECES
// =============================================================================

/// Dims the whole screen except a rounded cut-out around [highlight].
class _TourDimPainter extends CustomPainter {
  final Rect? highlight;

  const _TourDimPainter({required this.highlight});

  static final Paint _dim = Paint()
    ..color = Colors.black.withValues(alpha: 0.72);

  @override
  void paint(Canvas canvas, Size size) {
    final screen = Offset.zero & size;
    final rect = highlight;
    if (rect == null) {
      canvas.drawRect(screen, _dim);
      return;
    }
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(18)),
      );
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(screen), hole),
      _dim,
    );
  }

  @override
  bool shouldRepaint(covariant _TourDimPainter oldDelegate) =>
      oldDelegate.highlight != highlight;
}

/// Arrow that bounces gently toward its target so it draws the eye.
class _PulsingArrow extends StatelessWidget {
  final Animation<double> animation;
  final _ArrowDirection direction;

  const _PulsingArrow({required this.animation, required this.direction});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final shift = 5.0 * t;
        final offset = switch (direction) {
          _ArrowDirection.up => Offset(0, -shift),
          _ArrowDirection.down => Offset(0, shift),
          _ArrowDirection.left => Offset(-shift, 0),
          _ArrowDirection.right => Offset(shift, 0),
        };
        return Transform.translate(
          offset: offset,
          child: Transform.scale(scale: 1.0 + 0.08 * t, child: child),
        );
      },
      child: CustomPaint(
        painter: _ArrowPainter(direction: direction),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws a solid arrow head with a short shaft, rotated to point at the target.
class _ArrowPainter extends CustomPainter {
  final _ArrowDirection direction;

  const _ArrowPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(switch (direction) {
      _ArrowDirection.up => 0.0,
      _ArrowDirection.right => math.pi / 2,
      _ArrowDirection.down => math.pi,
      _ArrowDirection.left => -math.pi / 2,
    });
    canvas.translate(-w / 2, -h / 2);

    // An arrow pointing up in the local box; the rotation above aims it.
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w * 0.95, h * 0.60)
      ..lineTo(w * 0.64, h * 0.60)
      ..lineTo(w * 0.64, h)
      ..lineTo(w * 0.36, h)
      ..lineTo(w * 0.36, h * 0.60)
      ..lineTo(w * 0.05, h * 0.60)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.direction != direction;
}

/// The explanation card: progress, title, body, and the step controls.
class _TourCard extends StatelessWidget {
  final _TourStep step;
  final int index;
  final int total;
  final double maxHeight;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final void Function(bool openGuide) onFinish;

  const _TourCard({
    required this.step,
    required this.index,
    required this.total,
    required this.maxHeight,
    required this.onNext,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const green = Color(0xFF10B981);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          color: isDark
              ? MarketPalette.surface(context).withValues(alpha: 0.98)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: green.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: green.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Flexible so the progress chip shrinks instead of overflowing
                // the card on narrow screens or with wide fallback fonts.
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hakbang ${index + 1} ng $total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 11,
                        weight: FontWeight.w700,
                        color: green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => onFinish(false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    step.isFinal ? 'Tapusin' : 'Laktawan',
                    style: AppText.body(
                      size: 12,
                      color: MarketPalette.textBody(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: AppText.display(
                        size: 18,
                        color: MarketPalette.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                                        Text(
                                          step.body,
                                          style: AppText.body(
                                            size: 13,
                                            color: MarketPalette.textBody(context),
                                          ).copyWith(height: 1.5),
                                        ),
                                        if (step.target != null && step.isFinal == false) ...[
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              const Icon(Icons.touch_app_rounded,
                                                  size: 15, color: green),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'I-tap ang naka-highlight na control para '
                                                  'magpatuloy.',
                                                  style: AppText.body(size: 11, color: green),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                if (onBack != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Bumalik',
                        style: AppText.button(size: 13, color: green),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: step.isFinal ? () => onFinish(true) : onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      step.isFinal ? 'Buksan ang Gabay' : 'Susunod',
                      style: AppText.button(size: 13, color: Colors.white),
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
