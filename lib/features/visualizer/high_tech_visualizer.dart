import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:spectrum/core/theme/spectrum_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/visualizer/visualizer_provider.dart';

/// Spectrum "Crimson Wavefront" Visualizer.
/// Redesigned to use centralized SpectrumColors design system.
class HighTechVisualizer extends ConsumerStatefulWidget {
  final Color baseColor;
  final bool isPlaying;

  const HighTechVisualizer({
    super.key,
    required this.baseColor,
    required this.isPlaying,
  });

  @override
  ConsumerState<HighTechVisualizer> createState() => _HighTechVisualizerState();
}

class _HighTechVisualizerState extends ConsumerState<HighTechVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final math.Random _random = math.Random();
  final List<double> _frequencies = List.generate(16, (_) => 0.0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bands = ref.watch(visualizerBandsProvider).value ??
        List.generate(16, (_) => 0.0);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CrimsonWavePainter(
              time: _controller.value,
              baseColor: widget.baseColor,
              isPlaying: widget.isPlaying,
              frequencies: bands,
              random: _random,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _CrimsonWavePainter extends CustomPainter {
  final double time;
  final Color baseColor;
  final bool isPlaying;
  final List<double> frequencies;
  final math.Random random;

  _CrimsonWavePainter({
    required this.time,
    required this.baseColor,
    required this.isPlaying,
    required this.frequencies,
    required this.random,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Deep Field (Pulse on average bass)
    final avgBass = (frequencies[0] + frequencies[1] + frequencies[2]) / 3;
    _drawDeepField(canvas, size, avgBass);

    // 2. Liquid Core (Organic center mass)
    _drawLiquidCore(canvas, size, center, avgBass);

    // 3. Hypersonic Waves (Multi-band response)
    _drawCrimsonWaves(canvas, size, center);

    // 4. HUD Marking
    _drawHUDMod(canvas, size);
  }

  void _drawLiquidCore(
      Canvas canvas, Size size, Offset center, double bassEnergy) {
    final paint = Paint()
      ..maskFilter =
          MaskFilter.blur(BlurStyle.normal, (15 * bassEnergy).clamp(1.0, 50.0))
      ..style = PaintingStyle.fill;

    // Layered organic blobs
    for (var i = 0; i < 3; i++) {
      final floatTime = time * 2 * math.pi;
      final radius = (30.0 + (i * 25.0)) * (1.0 + (bassEnergy * 0.4));

      final offsetX = math.sin(floatTime + (i * 2.1)) * 20 * bassEnergy;
      final offsetY = math.cos(floatTime * 0.8 + (i * 1.5)) * 15 * bassEnergy;

      final color = i == 0
          ? SpectrumColors.accent
          : (i == 1 ? SpectrumColors.accentSecondary : Colors.white);

      paint.color =
          color.withOpacity((0.1 * (3 - i) * bassEnergy).clamp(0.0, 0.4));

      canvas.drawCircle(center + Offset(offsetX, offsetY), radius, paint);
    }

    // Core glow streak
    final streakPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          SpectrumColors.accent.withOpacity(0.5 * bassEnergy),
          Colors.transparent
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(center.dx - 100, center.dy - 2, 200, 4));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * 0.5);
    canvas.drawRect(const Rect.fromLTWH(-150, -0.5, 300, 1.0),
        Paint()..color = SpectrumColors.accent.withOpacity(0.1 * bassEnergy));
    canvas.restore();
  }

  void _drawDeepField(Canvas canvas, Size size, double bassEnergy) {
    // Background pulse on bass energy
    final paint = Paint()
      ..color = SpectrumColors.accent.withOpacity(0.06 * bassEnergy);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Scanlines (Optimized: draw fewer, thicker lines)
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 2;
    for (double i = 0; i < size.height; i += 10) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), linePaint);
    }
  }

  void _drawCrimsonWaves(Canvas canvas, Size size, Offset center) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var j = 0; j < 5; j++) {
      final path = Path();
      final offset = j * 0.5;
      final speed = 2.0 + j * 0.8;

      // Select index range based on layer
      // j=0 (Bass), j=1 (Low Mid), j=2 (Mid), j=3 (High Mid), j=4 (High)
      final startIndex = j * 3;
      final rangeEnergy =
          (frequencies[startIndex] + frequencies[startIndex + 1]) / 2;

      // COLOR SYNC
      final layerColor = j == 0
          ? SpectrumColors.textPrimary
          : (j % 2 == 0
              ? SpectrumColors.accent
              : SpectrumColors.accentSecondary);
      final opacity = (0.2 + 0.8 * rangeEnergy) / (j + 1);

      for (double i = 0; i <= size.width; i += 4) {
        final normalizedX = i / size.width;

        // Complex wave logic using local energy
        var wave = math.sin(normalizedX * (8 + j) + time * speed + offset) *
            50 *
            rangeEnergy;

        // Add harmonics from the high end for texture
        if (j > 2) {
          wave += math.sin(normalizedX * 40 + time * 12) * 10 * frequencies[15];
        }

        final y = center.dy + wave;
        if (i == 0) {
          path.moveTo(i, y);
        } else {
          path.lineTo(i, y);
        }
      }

      paint.color = layerColor.withOpacity(opacity.clamp(0.0, 1.0));
      paint.strokeWidth = 1.0 + (4.0 * rangeEnergy);

      canvas.drawPath(path, paint);

      // Mirror
      canvas.save();
      canvas.translate(0, center.dy * 2);
      canvas.scale(1, -1);
      canvas.drawPath(
          path, paint..color = layerColor.withOpacity(opacity * 0.2));
      canvas.restore();
    }
  }

  void _drawHUDMod(Canvas canvas, Size size) {
    final textStyle = TextStyle(
        color: SpectrumColors.textUltraMuted,
        fontSize: 8,
        fontFamily: 'monospace',
        letterSpacing: 2.5);
    final accentStyle = TextStyle(
        color: SpectrumColors.accent.withOpacity(0.5),
        fontSize: 8,
        fontFamily: 'monospace',
        fontWeight: FontWeight.bold);

    void drawText(String text, Offset pos, {bool isAccent = false}) {
      final tp = TextPainter(
          text: TextSpan(text: text, style: isAccent ? accentStyle : textStyle),
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, pos);
    }

    final topX = size.width - 200;
    drawText('LINK: ESTABLISHED', Offset(topX, 20));
    drawText('CORE_STABILITY: 99.8%', Offset(topX, 32));
    drawText('NEURAL_SYNC: ACTIVE', Offset(topX, 44), isAccent: true);

    // Bottom detail
    drawText('SPECTRUM // LIQUID_QUARTZ_ENGINE // v1.2',
        Offset(24, size.height - 30));

    // Corner accents
    final cornerPaint = Paint()
      ..color = SpectrumColors.accent.withOpacity(0.3)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(15, 15), const Offset(45, 15), cornerPaint);
    canvas.drawLine(const Offset(15, 15), const Offset(15, 45), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _CrimsonWavePainter oldDelegate) => true;
}
