import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ml/produce_classifier.dart';
import 'ml/freshness_classifier.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/theme_cross_fade.dart';
import 'screens/splash_screen.dart';
import 'services/connectivity_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Locked to portrait on purpose. The whole UI is portrait-designed (bottom
  // bar, cards, scanner), and in landscape the camera frame collapses to a
  // ~2.6:1 letterbox strip (measured: 393x817 portrait vs 873x337 landscape on
  // a 1080x2400 phone). Produce recognition depends on the item filling the
  // frame, so a thin strip makes framing unreliable. See the "Oryentasyon"
  // card in Settings for the user-facing explanation.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // FIX: these used to run one after another (Firebase -> theme -> model 1
  // -> model 2) before the first frame, so the app sat on a blank/splash
  // screen for seconds. They don't depend on each other, so run them
  // in parallel. Each model load is wrapped so one failing never blocks
  // startup.
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    themeController.load(),
    produceClassifier.loadModel().catchError((e) {
      debugPrint('ProduceClassifier failed to load: $e');
    }),
    freshnessClassifier.loadModel().catchError((e) {
      debugPrint('FreshnessClassifier not loaded (expected until trained): $e');
    }),
  ]);

  // FIX: On a fresh install (no onboarding completion flag) HomeScreen starts
  // the walkthrough automatically after its first frame. On an already-seen
  // install the flag is left alone so the tour is not re-shown.
  // await clearOnboardingCache();

  runApp(const ProduceAIQApp());
}

class ProduceAIQApp extends StatelessWidget {
  const ProduceAIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'ProduceAIQ',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        themeAnimationDuration: Duration.zero,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => _ConnectivityOverlay(child: ThemeCrossFade(child: child!)),
        home: const SplashScreen(),
      ),
    );
  }
}

/// Overlay that shows a quick toast when connectivity changes
class _ConnectivityOverlay extends StatefulWidget {
  final Widget child;
  const _ConnectivityOverlay({required this.child});

  @override
  State<_ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<_ConnectivityOverlay> {
  late StreamSubscription<String> _sub;
  bool _isOnline = true;
  bool _first = true;

  @override
  void initState() {
    super.initState();
    final service = ConnectivityService.instance;
    _isOnline = service.isOnline;
    _sub = service.onStatusChanged.listen((status) {
      final online = status == 'online';
      if (!_first && online != _isOnline) {
        _showToast(online);
      }
      _isOnline = online;
      _first = false;
    });
  }

  void _showToast(bool online) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              online ? 'Online na kayo' : 'Offline na kayo',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: online ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}