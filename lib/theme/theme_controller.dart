import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark/system theme preference.
///
/// A plain [ValueNotifier] rather than a state-management package,
/// since this is the only piece of genuinely global, cross-screen
/// state in the app -- MaterialApp listens to it directly via
/// ValueListenableBuilder in main.dart, and SettingsScreen writes to
/// it when the user picks a different mode.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _prefsKey = 'theme_mode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier(
    ThemeMode.system,
  );

  /// Loads the saved preference, if any, before the app's first frame.
  /// Called once from main() -- if this fails or nothing was saved
  /// yet, mode stays at its default (ThemeMode.system).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(
        _prefsKey,
      );
      switch (saved) {
        case 'light':
          mode.value = ThemeMode.light;
          break;
        case 'dark':
          mode.value = ThemeMode.dark;
          break;
        case 'system':
        default:
          mode.value = ThemeMode.system;
      }
    } catch (
      _
    ) {
      // Non-fatal: worst case the app just opens in system-default
      // mode instead of whatever was previously chosen.
    }
  }

  Future<void> setMode(
    ThemeMode newMode,
  ) async {
    mode.value = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        newMode.name,
      );
    } catch (
      _
    ) {
      // Non-fatal: the toggle still works for this session even if
      // it fails to persist for next launch.
    }
  }
}

final themeController = ThemeController.instance;
