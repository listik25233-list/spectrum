import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spectrum/features/player/dominant_color_provider.dart';

class NeuralAura extends ConsumerStatefulWidget {
  const NeuralAura({super.key});

  @override
  ConsumerState<NeuralAura> createState() => _NeuralAuraState();
}

class _NeuralAuraState extends ConsumerState<NeuralAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_AuraOrb> _orbs = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initialize random orbs
    for (int i = 0; i < 5; i++) {
      _orbs.add(_AuraOrb(
        position: Offset(_random.nextDouble(), _random.nextDouble()),
        radius: 0.3 + _random.nextDouble() * 0.4,
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 0.002,
          (_random.nextDouble() - 0.5) * 0.002,
        ),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorsAsync = ref.watch(auraPaletteProvider);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Update orb positions
        for (var orb in _orbs) {
          orb.update();
        }

        return Stack(
          children: [
            // Base background
            Container(color: const Color(0xFF0F0F15)),
            
            // Orbs Layer
            colorsAsync.when(
              data: (colors) => CustomPaint(
                painter: _AuraPainter(
                  orbs: _orbs,
                  colors: colors,
                ),
                size: Size.infinite,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // High-quality Blur overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AuraOrb {
  Offset position;
  final double radius;
  final Offset velocity;

  _AuraOrb({
    required this.position,
    required this.radius,
    required this.velocity,
  });

  void update() {
    position += velocity;
    
    // Bounce off edges
    if (position.dx < 0 || position.dx > 1) {
      position = Offset(position.dx.clamp(0, 1), position.dy);
    }
    if (position.dy < 0 || position.dy > 1) {
      position = Offset(position.dx, position.dy.clamp(0, 1));
    }
  }
}

class _AuraPainter extends CustomPainter {
  final List<_AuraOrb> orbs;
  final List<Color> colors;

  _AuraPainter({required this.orbs, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (colors.isEmpty) return;

    for (int i = 0; i < orbs.length; i++) {
      final orb = orbs[i];
      final color = colors[i % colors.length];
      
      final center = Offset(
        orb.position.dx * size.width,
        orb.position.dy * size.height,
      );
      
      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

      canvas.drawCircle(center, orb.radius * size.width, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
