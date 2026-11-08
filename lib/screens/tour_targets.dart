import 'package:flutter/material.dart';

/// Stable, named handles for the controls the first-run walkthrough points at.
///
/// Widget keys are the Flutter equivalent of a web `data-tour="..."` attribute:
/// a tour step asks for a target *by name* and gets whatever widget currently
/// carries that key, instead of matching on fragile widget types, text, or
/// hard-coded pixel offsets.
///
/// A target that is not currently mounted (hidden panel, different layout,
/// smaller screen) simply has no render box -- see [rectOf] -- and callers
/// treat that as "skip this step" rather than an error.
class TourTargets {
  TourTargets._();

  /// The "Scan Produce" card that holds the main call to action.
  static final GlobalKey scanCard = GlobalKey(debugLabel: 'tour.scanCard');

  /// The big "SIMULAN ANG PAG-SCAN" button inside that card.
  static final GlobalKey scanButton = GlobalKey(debugLabel: 'tour.scanButton');

  /// The four bottom navigation bar entries.
  static final GlobalKey scanTab = GlobalKey(debugLabel: 'tour.scanTab');
  static final GlobalKey termsTab = GlobalKey(debugLabel: 'tour.termsTab');
  static final GlobalKey guideTab = GlobalKey(debugLabel: 'tour.guideTab');
  static final GlobalKey settingsTab = GlobalKey(debugLabel: 'tour.settingsTab');

  /// Global-space bounds of [key]'s widget, or null when it is not on screen.
  ///
  /// Returns null -- never throws -- when the key is unmounted, its render
  /// object is not a [RenderBox], or it has not been laid out yet, so a tour
  /// step pointing at an absent control degrades into a skip.
  static Rect? rectOf(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;
    final object = context.findRenderObject();
    if (object is! RenderBox) return null;
    if (!object.hasSize) return null;
    final size = object.size;
    if (size.isEmpty) return null;
    final topLeft = object.localToGlobal(Offset.zero);
    if (!topLeft.dx.isFinite || !topLeft.dy.isFinite) return null;
    return topLeft & size;
  }
}
