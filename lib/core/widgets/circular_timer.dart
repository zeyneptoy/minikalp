import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';

/// A circular progress ring with a time label in the center.
///
/// Useful for a live feeding/sleep timer or a daily goal ring. [progress] is a
/// value in 0..1 that fills the ring; [timeLabel] is the big center text and
/// [caption] the small text below it.
class CircularTimer extends ConsumerWidget {
  const CircularTimer({
    super.key,
    required this.progress,
    required this.timeLabel,
    this.caption,
    this.size = 180,
    this.strokeWidth = 14,
  });

  /// Fill amount, clamped to 0..1.
  final double progress;

  /// Large center label (e.g. "12:45").
  final String timeLabel;

  /// Optional small caption under the label.
  final String? caption;

  /// Overall diameter.
  final double size;

  /// Thickness of the ring.
  final double strokeWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              trackColor: colors.soft,
              fillColor: colors.primary,
              accentColor: colors.accent,
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeLabel,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(caption!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Paints the track and the gradient progress arc.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.accentColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;
  final Color accentColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [fillColor, accentColor, fillColor],
      ).createShader(rect);

    // Track (full circle).
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    // Progress arc, starting from the top (−90°).
    const startAngle = -math.pi / 2;
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(rect, startAngle, sweep, false, fill);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.fillColor != fillColor ||
      old.trackColor != trackColor ||
      old.accentColor != accentColor ||
      old.strokeWidth != strokeWidth;
}
