import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the "DEBUG" ribbon.
///
/// That red ribbon is not a widget in the tree -- it is painted by
/// `CheckedModeBanner`, which `WidgetsApp` inserts only when
/// `debugShowCheckedModeBanner` is true (its default). `flutter test` forces
/// the banner off globally (`WidgetsApp.debugAllowBannerOverride = false`), so
/// a widget test can never observe it either way. Asserting on the real
/// `MaterialApp` construction in lib/main.dart is the only reliable check.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lib/main.dart turns the debug banner off', () {
    final source = File('lib/main.dart').readAsStringSync();

    expect(
      source.contains('debugShowCheckedModeBanner: false'),
      isTrue,
      reason:
          'The red DEBUG ribbon is painted top-right in every debug build '
          'unless MaterialApp sets debugShowCheckedModeBanner: false. '
          'Restore that line if it is ever removed.',
    );
  });

  test('the flag is passed to MaterialApp, not just declared', () {
    final source = File('lib/main.dart').readAsStringSync();

    // Must be an argument to MaterialApp, i.e. appear inside the same
    // constructor call that builds the app.
    final materialApp = RegExp(
      r'MaterialApp\((?:[^()]|\([^()]*\))*?debugShowCheckedModeBanner:\s*false',
      multiLine: true,
      dotAll: true,
    );
    expect(materialApp.hasMatch(source), isTrue,
        reason: 'the flag must be an argument of the MaterialApp constructor');
  });
}
