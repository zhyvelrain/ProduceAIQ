import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'confidence_screen.dart';
import 'onboarding_screen.dart';
import '../ml/produce_classifier.dart';
import '../theme/app_theme.dart';
import '../theme/brand.dart';

/// Camera integration for the Produce Scanner Interface (Fig. 3.3).
/// Two entry points: live camera capture, or uploading up to 4
/// existing photos at once (fed through the same attempt cycle).
class ScannerScreen extends StatefulWidget {
  final int attemptNumber;
  final List<double> history;
  final List<String> imagePathHistory;

  /// Remaining images queued from gallery upload to be processed sequentially.
  final List<String> remainingQueue;

  /// Every earlier attempt's ranked predictions, carried through so the
  /// best-of-attempts fallback can consider them. See
  /// lib/ml/attempt_selector.dart.
  final List<List<Prediction>> attemptPredictions;

  const ScannerScreen({
    super.key,
    this.attemptNumber = 1,
    this.history = const [],
    this.imagePathHistory = const [],
    this.remainingQueue = const [],
    this.attemptPredictions = const [],
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxUpload = 4;

  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  String? _errorMessage;
  bool _isCapturing = false;
  bool _isPicking = false;
  bool _cameraReady = false;
  final ImagePicker _imagePicker = ImagePicker();

  late final AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Walang mahanap na camera sa device na ito.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      final initFuture = _controller!.initialize();
      setState(() {
        _initializeControllerFuture = initFuture;
      });

      await initFuture;
      if (!mounted) return;
      setState(() => _cameraReady = true);

      // Show scanner onboarding dialog on first visit (after camera is ready)
      final seen = await hasSeenScannerOnboarding();
      if (!seen) {
        _showScannerOnboarding();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Camera error: $e');
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_isCapturing || _isPicking) return;

    setState(() => _isCapturing = true);
    try {
      final photo = await _controller!.takePicture();
      if (!mounted) return;
      _goToConfidenceScreen(photo.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paghuli ng larawan ay nabigo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  /// Shows the one-time scanner onboarding dialog (first time user visits scanner)
  /// Explains how to position produce and lets user choose to go back to Home or proceed.
  Future<void> _showScannerOnboarding() async {
    final seen = await hasSeenScannerOnboarding();
    if (seen || !mounted) return;

    await markScannerOnboardingSeen();

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A2E)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Brand.emerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Brand.emerald,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Paano Mag-scan',
              style: AppText.display(
                size: 20,
                color: MarketPalette.textPrimary(context),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ang scanner ay gumagamit ng AI na nasa loob ng app — pwede gamitin offline. Sundin ang gabay para sa mas tumpak na resulta:',
                style: AppText.body(
                  size: 14,
                  color: MarketPalette.textBody(context),
                ),
              ),
              const SizedBox(height: 16),
              _buildScannerTip(
                icon: Icons.center_focus_strong_rounded,
                text:
                    'Ilagay ang produce sa loob ng frame. I-center gamit ang crosshair sa gitna.',
              ),
              _buildScannerTip(
                icon: Icons.photo_size_select_large_rounded,
                text:
                    'Lapitin ang kamera hanggang punan ng produce ang frame. Mas malinaw ang larawan, mas tumpak ang AI.',
              ),
              _buildScannerTip(
                icon: Icons.flash_on_rounded,
                text:
                    "Tiyaking malinaw ang larawan at sapat ang liwanag. Iba't ibang angulo kada attempt.",
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Brand.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Brand.emerald.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Brand.emerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Max 4 larawan per scan session. Kailangan ng internet para sa recipes.',
                        style: AppText.body(
                          size: 12,
                          color: MarketPalette.textBody(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Go back to Home
            },
            child: Text(
              'Bumalik sa Home',
              style: AppText.body(
                size: 14,
                weight: FontWeight.w600,
                color: MarketPalette.textMuted(context),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Brand.emerald,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Simulan ang Pagsascan',
              style: AppText.button(size: 15).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTip({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Brand.emerald, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body(size: 13))),
        ],
      ),
    );
  }

  Future<void> _pickMultipleFromGallery() async {
    if (_isCapturing || _isPicking) return;

    setState(() => _isPicking = true);
    try {
      final picked = await _imagePicker.pickMultiImage();
      if (!mounted || picked.isEmpty) return;

      // Calculate remaining slots: max 4 total per scan session
      final alreadyQueued = widget.remainingQueue.length + widget.imagePathHistory.length;
      final remainingSlots = _maxUpload - alreadyQueued;

      if (remainingSlots <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mabusog na ang slot para sa pag-scan. Simulan na ang proseso.')),
        );
        return;
      }

      final paths = picked.map((x) => x.path).take(remainingSlots).toList();
      final String? uploadNotice = picked.length > remainingSlots
          ? 'Ang unang $remainingSlots na napiling larawan lamang ang gagamitin (natitira $remainingSlots slot sa 4).'
          : null;

      final firstPath = paths.first;
      final remainingQueue = paths.skip(1).toList();
      _goToConfidenceScreen(
        firstPath,
        remainingQueue: remainingQueue,
        uploadNotice: uploadNotice,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  void _goToConfidenceScreen(
    String imagePath, {
    List<String> remainingQueue = const [],
    String? uploadNotice,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfidenceScreen(
          attemptNumber: widget.attemptNumber,
          history: widget.history,
          imagePath: imagePath,
          imagePathHistory: widget.imagePathHistory,
          remainingQueue: remainingQueue,
          attemptPredictions: widget.attemptPredictions,
          uploadNotice: uploadNotice,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

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
          color: isDark ? MarketPalette.textPrimary(context) : const Color(0xFF047857),
        ),
        // Styled Green Pill Badge Title
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
                Icons.camera_alt_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.attemptNumber == 1
                    ? 'Scanner ng Produce'
                    : 'Scanner, Subok ${widget.attemptNumber}',
                style: AppText.display(
                  size: 15,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _LeafyBackground(
        isDark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Section Header Module
                _SectionHeader(attemptNumber: widget.attemptNumber),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildBody(isDark),
                ),
                const SizedBox(height: 12),
                _buildActionRow(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(bool isDark) {
    final canScan = !_isCapturing && !_isPicking && _cameraReady;
    final canUpload = !_isCapturing && !_isPicking;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Upload Button
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: isDark ? const Color(0xFF102A1C) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: canUpload ? _pickMultipleFromGallery : null,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _isPicking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF10B981),
                          ),
                        )
                      : Icon(
                          Icons.photo_library_rounded,
                          color: canUpload
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade400,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'I-upload',
              style: AppText.body(
                size: 10,
                weight: FontWeight.w600,
                color: MarketPalette.textBody(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(width: 36),
        // Scan Button (Primary Action - Matching Emerald Green Theme)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: canScan
                  ? const Color(0xFF10B981)
                  : const Color(0xFF10B981).withValues(alpha: 0.35),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: canScan ? _capturePhoto : null,
                child: Container(
                  width: 76,
                  height: 76,
                  alignment: Alignment.center,
                  child: _isCapturing
                      ? const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'I-scan',
              style: AppText.body(
                size: 10,
                weight: FontWeight.w700,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(bool isDark) {
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            color: MarketPalette.textPrimary(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_initializeControllerFuture == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF10B981),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraPreview(_controller!),
                    const ViewfinderCorners(),
                    if (!_isCapturing)
                      _ScanLineOverlay(
                        animation: _scanLineController,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DistanceIndicator(),
          ],
        );
      },
    );
  }
}

/// In-Body Section Header Module (Matching App Settings/HowItWorks standard)
class _SectionHeader extends StatelessWidget {
  final int attemptNumber;
  const _SectionHeader({required this.attemptNumber});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          attemptNumber == 1
              ? 'Kumuha ng Larawan'
              : 'Subok $attemptNumber',
          style: AppText.display(
            size: 16,
            color: MarketPalette.textPrimary(context),
          ),
        ),
      ],
    );
  }
}

/// Sweeping Scan Line Overlay with Matched Green Theme
class _ScanLineOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _ScanLineOverlay({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final y = -0.9 + animation.value * 1.8;
          return Align(
            alignment: Alignment(0, y),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0),
                      const Color(0xFF10B981),
                      const Color(0xFF10B981).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// AMBIENT BOTANICAL BACKGROUND WRAPPER
// =============================================================================

class _LeafyBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _LeafyBackground({
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = isDark
        ? const [
            Color(0xFF091F15),
            Color(0xFF05170F),
            Color(0xFF020C07),
          ]
        : const [
            Color(0xFFEAF5EC),
            Color(0xFFDBEFE1),
            Color(0xFFCCE8D4),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: CustomPaint(
        painter: _LeafPatternPainter(isDark: isDark),
        child: child,
      ),
    );
  }
}

class _LeafPatternPainter extends CustomPainter {
  final bool isDark;

  _LeafPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = isDark
          ? const Color(0xFF34D399).withValues(alpha: 0.14)
          : const Color(0xFF059669).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isDark
          ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
          : const Color(0xFF10B981).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path1 = Path();
    path1.moveTo(size.width * 0.72, 0);
    path1.quadraticBezierTo(
        size.width, size.height * 0.08, size.width, size.height * 0.22);
    path1.quadraticBezierTo(
        size.width * 0.62, size.height * 0.18, size.width * 0.72, 0);
    path1.close();
    canvas.drawPath(path1, fillPaint);
    canvas.drawPath(path1, strokePaint);

    final path2 = Path();
    path2.moveTo(0, size.height * 0.42);
    path2.quadraticBezierTo(
        size.width * 0.38, size.height * 0.46, size.width * 0.28, size.height * 0.60);
    path2.quadraticBezierTo(
        size.width * 0.05, size.height * 0.56, 0, size.height * 0.42);
    path2.close();
    canvas.drawPath(path2, fillPaint);
    canvas.drawPath(path2, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Distance indicator - helps user understand proper camera distance
/// Since CNN works on pixels not meters, this gives visual feedback on framing
class _DistanceIndicator extends StatelessWidget {
  const _DistanceIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.8),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.center_focus_strong_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ilagay ang produce sa loob ng frame. Lapitin ang kamera para malinaw.',
                  style: AppText.body(
                    size: 12,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}