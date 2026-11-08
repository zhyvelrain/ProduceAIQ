import 'dart:io';
import 'package:flutter/material.dart';
import 'package:produceaiq/services/history_service.dart';
import 'package:produceaiq/theme/app_theme.dart';
import 'package:produceaiq/theme/brand.dart';
import 'result_screen.dart';
import 'package:produceaiq/data/produce_repository.dart';
import 'package:produceaiq/ml/freshness_assessor.dart';

/// Full History Screen showing past scans with thumbnails, dates, results.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<ScanHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryService.instance.load();
  }

  Future<void> _refresh() async {
    setState(() {
      _historyFuture = HistoryService.instance.load();
    });
    await _historyFuture;
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
        title: Text(
          'Kasaysayan',
          style: AppText.display(
            size: 18,
            color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'I-clear ang kasaysayan',
            onPressed: _confirmClear,
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
            ),
          ),
        ],
      ),
      body: _LeafyBackground(
        isDark: isDark,
        child: SafeArea(
          child: FutureBuilder<List<ScanHistoryItem>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                  ),
                );
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Brand.emeraldAt(0.15)
                                    : Brand.emeraldSoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.history_rounded,
                                size: 56,
                                color: isDark
                                    ? const Color(0xFF6EE7B7)
                                    : Brand.emeraldDeep,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Walang kasaysayan pa',
                              style: AppText.display(
                                size: 20,
                                color: MarketPalette.textPrimary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Ang iyong mga nakaraang scan ay lalabas dito kapag nagagamit mo na ang app.',
                                style: AppText.body(
                                  size: 14,
                                  color: MarketPalette.textBody(context),
                                ).copyWith(height: 1.5),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refresh,
                color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: history.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final produceItem = produceRepository.get(item.produceId);
                    final produceName = produceItem?.commonName ?? item.produceName;
                    final dateStr = _formatDate(item.timestamp);
                    final timeStr = _formatTime(item.timestamp);
                    final confidenceStr = item.confidence != null
                        ? '${(item.confidence! * 100).toStringAsFixed(0)}%'
                        : '-';
                    final freshnessLabel = _freshnessLabel(item.freshnessGrade, isDark);

                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(item.id),
                      onDismissed: (_) => HistoryService.instance.remove(item.id),
                      child: _HistoryCard(
                        isDark: isDark,
                        produceName: produceName,
                        dateStr: dateStr,
                        timeStr: timeStr,
                        confidenceStr: confidenceStr,
                        freshnessLabel: freshnessLabel,
                        imagePath: item.imagePath,
                        onTap: () => _openResult(item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    if (itemDate == today) return 'Ngayon';
    if (itemDate == yesterday) return 'Kahapon';

    const months = [
      'Ene', 'Peb', 'Mar', 'Abr', 'May', 'Hun',
      'Hul', 'Ago', 'Set', 'Okt', 'Nob', 'Dis'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Widget _freshnessLabel(String? grade, bool isDark) {
    if (grade == null || grade.isEmpty) {
      return const SizedBox.shrink();
    }

    Color color;
    String label;
    switch (grade.toLowerCase()) {
      case 'unripe':
        color = const Color(0xFF10B981);
        label = 'Hilaw';
        break;
      case 'ripe':
        color = const Color(0xFF059669);
        label = 'Hinog';
        break;
      case 'overripe':
        color = const Color(0xFFF59E0B);
        label = 'Sobrang Hinog';
        break;
      case 'rotten':
        color = const Color(0xFFEF4444);
        label = 'Bulok';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppText.body(
          size: 10,
          weight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tanggalin ang item?'),
        content: const Text('Maalis ito sa kasaysayan. Hindi ito mababalik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kanselahin'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tanggalin'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('I-clear ang buong kasaysayan?'),
        content: const Text('Maalis ang lahat ng nakaraang scan. Hindi ito mababalik.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kanselahin'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('I-clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService.instance.clear();
      _refresh();
    }
  }

  void _openResult(ScanHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          produceId: item.produceId,
          confidence: item.confidence,
          freshnessGrade: _parseFreshnessGrade(item.freshnessGrade),
          freshnessFromRealModel: false,
        ),
      ),
    );
  }

  FreshnessGrade? _parseFreshnessGrade(String? grade) {
    if (grade == null) return null;
    switch (grade.toLowerCase()) {
      case 'unripe':
        return FreshnessGrade.unripe;
      case 'ripe':
        return FreshnessGrade.ripe;
      case 'overripe':
        return FreshnessGrade.overripe;
      case 'rotten':
        return FreshnessGrade.rotten;
      default:
        return null;
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final bool isDark;
  final String produceName;
  final String dateStr;
  final String timeStr;
  final String confidenceStr;
  final Widget freshnessLabel;
  final String? imagePath;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.isDark,
    required this.produceName,
    required this.dateStr,
    required this.timeStr,
    required this.confidenceStr,
    required this.freshnessLabel,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark
        ? MarketPalette.surface(context)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? MarketPalette.divider(context)
                  : const Color(0xFFDDE3D8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              _buildThumbnail(),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Produce name + freshness badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            produceName,
                            style: AppText.display(
                              size: 16,
                              color: MarketPalette.textPrimary(context),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        freshnessLabel,
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Date and time
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: MarketPalette.textBody(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: AppText.body(
                            size: 11,
                            color: MarketPalette.textBody(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: MarketPalette.textBody(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: AppText.body(
                            size: 11,
                            color: MarketPalette.textBody(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Confidence
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          size: 12,
                          color: const Color(0xFF059669),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Kasiguraduhan: $confidenceStr',
                          style: AppText.body(
                            size: 11,
                            weight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: MarketPalette.textBody(context),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    const double size = 64;

    if (imagePath != null && File(imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: 256,
          errorBuilder: (_, _, _) => _fallbackThumbnail(),
        ),
      );
    }

    return _fallbackThumbnail();
  }

  Widget _fallbackThumbnail() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF059669).withValues(alpha: 0.12)
            : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF059669).withValues(alpha: 0.3)
              : const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: const Icon(
        Icons.image_rounded,
        color: Color(0xFF059669),
        size: 28,
      ),
    );
  }
}

class _LeafyBackground extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _LeafyBackground({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = isDark
        ? const [Color(0xFF091F15), Color(0xFF05170F), Color(0xFF020C07)]
        : const [Color(0xFFEAF5EC), Color(0xFFDBEFE1), Color(0xFFCCE8D4)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(painter: _LeafPainter(isDark: isDark)),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final bool isDark;
  const _LeafPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = isDark
          ? const Color(0xFF34D399).withValues(alpha: 0.14)
          : const Color(0xFF059669).withValues(alpha: 0.06);
    final stroke = Paint()
      ..color = isDark
          ? const Color(0xFF6EE7B7).withValues(alpha: 0.22)
          : const Color(0xFF10B981).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final p1 = Path()
      ..moveTo(size.width * 0.72, 0)
      ..quadraticBezierTo(
          size.width, size.height * 0.08, size.width, size.height * 0.22)
      ..quadraticBezierTo(
          size.width * 0.62, size.height * 0.18, size.width * 0.72, 0)
      ..close();
    canvas.drawPath(p1, fill);
    canvas.drawPath(p1, stroke);

    final p2 = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.38, size.height * 0.46,
          size.width * 0.28, size.height * 0.60)
      ..quadraticBezierTo(
          size.width * 0.05, size.height * 0.56, 0, size.height * 0.42)
      ..close();
    canvas.drawPath(p2, fill);
    canvas.drawPath(p2, stroke);
  }

  @override
  bool shouldRepaint(covariant _LeafPainter old) => old.isDark != isDark;
}