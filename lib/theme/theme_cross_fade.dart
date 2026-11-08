import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'theme_controller.dart';

/// Smooth light/dark switching.
///
/// Instead of letting MaterialApp animate (and rebuild the whole tree on every
/// frame of) the ThemeData change, the theme switches instantly and a
/// screenshot of the OLD look is faded out on top. Fading a bitmap is nearly
/// free, so it stays smooth no matter how heavy the screen is.
///
/// Usage in main.dart:
///   MaterialApp(
///     themeAnimationDuration: Duration.zero,
///     builder: (context, child) => ThemeCrossFade(child: child!),
///     ...
///   )
///
/// Requires Flutter 3.10+ (toImageSync, MediaQuery.devicePixelRatioOf).
class ThemeCrossFade extends StatefulWidget {
  final Widget child;
  const ThemeCrossFade({super.key, required this.child});

  @override
  State<ThemeCrossFade> createState() => _ThemeCrossFadeState();
}

class _ThemeCrossFadeState extends State<ThemeCrossFade>
    with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  ui.Image? _snapshot;

  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _setSnapshot(null);
    });

  @override
  void initState() {
    super.initState();
    themeController.mode.addListener(_captureOldFrame);
  }

  // Runs synchronously when the mode changes -- i.e. BEFORE the next frame
  // builds the new theme -- so this captures the old look.
  void _captureOldFrame() {
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null || !boundary.attached) return;
    try {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      _setSnapshot(boundary.toImageSync(pixelRatio: dpr));
      _fade.forward(from: 0);
    } catch (_) {
      // If capture isn't possible, the theme simply switches instantly.
    }
  }

  void _setSnapshot(ui.Image? next) {
    final old = _snapshot;
    setState(() => _snapshot = next);
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
  }

  @override
  void dispose() {
    themeController.mode.removeListener(_captureOldFrame);
    _fade.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundaryKey, child: widget.child),
        if (_snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: ReverseAnimation(_fade),
                child: RawImage(image: _snapshot, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }
}
