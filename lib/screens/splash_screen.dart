import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _splashImage = 'assets/splash/splash.png';
  static const Duration _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(_splashImage), context);
  }

  /// First run: shows Terms & Conditions dialog, then onboarding.
  /// Subsequent runs: goes straight to Home (which handles onboarding if needed).
  Future<void> _goNext() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    final termsAccepted = await hasAcceptedTerms();
    if (!termsAccepted) {
      // Show Terms & Conditions dialog first
      _showTermsDialog();
    } else {
      _goToHome();
    }
  }

  void _showTermsDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Mga Tuntunin at Kundisyon')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sa pag-download at paggamit ng ProduceAIQ, sumasang-ayon ka sa sumusunod:',
                style: AppText.body(size: 14),
              ),
              const SizedBox(height: 16),
              _buildTermsPoint('Ang app ay para sa layuning impormasyonal lamang at hindi kapalit ng propesyonal na payo.'),
              _buildTermsPoint('Limitado sa 10 klaseng produce: Ampalaya, Saging, Kangkong, Mangga, Papaya, Pinya, Sitaw, Talbos ng Kamote, Talong, Pakwan.'),
              _buildTermsPoint('Ang AI recognition ay maaaring magkamali; kailangan ng malinaw na larawan para sa tamang resulta.'),
              _buildTermsPoint('Kailangan ng internet para sa AI-generated recipes.'),
              _buildTermsPoint('Hindi para sa bata 7 taong gulang pababa; kailangan ng kakayahang gamitin ang touchscreen at kamera.'),
              const SizedBox(height: 16),
              Text(
                'Pwede mong basahin ang buong detalye sa Terms tab pagkatapos.',
                style: AppText.body(size: 13, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // User declined terms - close the app
              SystemNavigator.pop();
            },
            child: Text('Tanggihan', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await markTermsAccepted();
              _goToHome();
            },
            child: const Text('Tanggap', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body(size: 13))),
        ],
      ),
    );
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const HomeScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Image.asset(_splashImage, fit: BoxFit.cover),
      ),
    );
  }
}
