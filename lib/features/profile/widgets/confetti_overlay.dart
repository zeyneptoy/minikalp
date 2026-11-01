import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A lightweight, self-contained confetti animation (no external package).
///
/// Spawns colored particles that fall and drift while fading out. Colors are
/// supplied by the caller so they can match the active gender palette.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    required this.colors,
    this.particleCount = 60,
    this.duration = const Duration(milliseconds: 2600),
  });

  /// Palette used to tint the particles.
  final List<Color> colors;

  /// How many particles to spawn.
  final int particleCount;

  /// Total animation length.
  final Duration duration;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(random, widget.colors),
    );
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value),
        ),
      ),
    );
  }
}

/// A single confetti particle with randomized motion.
class _Particle {
  _Particle({
    required this.startX,
    required this.startY,
    required this.horizontalDrift,
    required this.fallDistance,
    required this.size,
    required this.color,
    required this.rotationSpeed,
    required this.delay,
  });

  final double startX; // 0..1 of width
  final double startY; // 0..1 of height (slightly above top)
  final double horizontalDrift; // fraction of width
  final double fallDistance; // fraction of height
  final double size;
  final Color color;
  final double rotationSpeed;
  final double delay; // 0..0.4 of timeline

  factory _Particle.random(math.Random r, List<Color> palette) {
    return _Particle(
      startX: r.nextDouble(),
      startY: -0.1 - r.nextDouble() * 0.2,
      horizontalDrift: (r.nextDouble() - 0.5) * 0.4,
      fallDistance: 0.9 + r.nextDouble() * 0.3,
      size: 6 + r.nextDouble() * 8,
      color: palette[r.nextInt(palette.length)],
      rotationSpeed: (r.nextDouble() - 0.5) * 12,
      delay: r.nextDouble() * 0.35,
    );
  }
}

/// Paints all particles for the current timeline value (0..1).
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles, this.t);

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      // Normalize local progress accounting for the particle's delay.
      final local = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final eased = Curves.easeIn.transform(local);
      final x = (p.startX + p.horizontalDrift * eased) * size.width;
      final y = (p.startY + p.fallDistance * eased) * size.height;
      final opacity = (1 - local).clamp(0.0, 1.0);

      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rotationSpeed * eased);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
