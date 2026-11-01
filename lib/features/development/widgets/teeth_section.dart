import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/development_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';

/// Shape of a primary tooth, used to draw an odontogram-style glyph.
enum ToothType { incisor, canine, molar }

/// The type of each tooth in a 10-tooth arch, from the patient's right to left.
/// Order out → in → out: 2nd molar, 1st molar, canine, lateral, central,
/// central, lateral, canine, 1st molar, 2nd molar.
ToothType _typeForPosition(int i) {
  final d = i < 5 ? 4 - i : i - 5; // 0 = central … 4 = second molar
  if (d <= 1) return ToothType.incisor;
  if (d == 2) return ToothType.canine;
  return ToothType.molar;
}

String _toothName(int globalIndex) {
  final pos = globalIndex % 10;
  switch (_typeForPosition(pos)) {
    case ToothType.incisor:
      return 'kesici diş';
    case ToothType.canine:
      return 'köpek dişi';
    case ToothType.molar:
      return 'azı dişi';
  }
}

/// A 20-tooth odontogram (upper + lower arch). Tap a tooth to mark it erupted;
/// each tooth is drawn with a shape appropriate to its type.
class TeethSection extends ConsumerWidget {
  const TeethSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final erupted = ref.watch(teethProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(title: 'Diş Takibi'),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text('Üst çene', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              _Arch(start: 0, upper: true, erupted: erupted),
              const SizedBox(height: AppSpacing.lg),
              _Arch(start: 10, upper: false, erupted: erupted),
              const SizedBox(height: AppSpacing.sm),
              Text('Alt çene', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '${erupted.length} / 20 diş çıktı',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row of 10 teeth starting at [start]. Scales down to fit narrow screens.
class _Arch extends ConsumerWidget {
  const _Arch({
    required this.start,
    required this.upper,
    required this.erupted,
  });

  final int start;
  final bool upper;
  final Set<int> erupted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = start; i < start + 10; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: GestureDetector(
                onTap: () => ref.read(teethProvider.notifier).toggle(i),
                child: Semantics(
                  button: true,
                  checked: erupted.contains(i),
                  label: '${i + 1}. ${_toothName(i)}',
                  child: _Tooth(
                    type: _typeForPosition(i % 10),
                    upper: upper,
                    erupted: erupted.contains(i),
                    color: colors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tooth extends StatelessWidget {
  const _Tooth({
    required this.type,
    required this.upper,
    required this.erupted,
    required this.color,
  });

  final ToothType type;
  final bool upper;
  final bool erupted;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        width: type == ToothType.molar ? 30 : (type == ToothType.canine ? 24 : 22),
        height: 40,
        child: CustomPaint(
          painter: _ToothPainter(
            type: type,
            upper: upper,
            erupted: erupted,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Draws a single primary tooth: a crown (with a type-specific silhouette) and
/// one or two roots. For the upper arch the roots point up; for the lower arch
/// the glyph is flipped so the roots point down.
class _ToothPainter extends CustomPainter {
  _ToothPainter({
    required this.type,
    required this.upper,
    required this.erupted,
    required this.color,
  });

  final ToothType type;
  final bool upper;
  final bool erupted;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw with the crown at the bottom and roots at the top, then flip for the
    // lower arch so crowns face the mouth opening.
    if (!upper) {
      canvas.translate(0, size.height);
      canvas.scale(1, -1);
    }

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = erupted ? color : color.withValues(alpha: 0.10);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = color.withValues(alpha: erupted ? 0.0 : 0.55);

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Vertical split: roots occupy the top ~42%, crown the bottom ~58%.
    final crownTop = h * 0.42;

    // --- roots ---
    final roots = Path();
    if (type == ToothType.molar) {
      // Two tapering roots.
      roots
        ..moveTo(w * 0.28, crownTop)
        ..lineTo(w * 0.16, h * 0.06)
        ..lineTo(w * 0.40, crownTop)
        ..close()
        ..moveTo(w * 0.72, crownTop)
        ..lineTo(w * 0.84, h * 0.06)
        ..lineTo(w * 0.60, crownTop)
        ..close();
    } else {
      // Single root (longer for canines).
      final tipY = type == ToothType.canine ? h * 0.02 : h * 0.08;
      roots
        ..moveTo(cx - w * 0.14, crownTop)
        ..lineTo(cx, tipY)
        ..lineTo(cx + w * 0.14, crownTop)
        ..close();
    }

    // --- crown ---
    final crown = Path();
    final bottom = h * 0.96;
    switch (type) {
      case ToothType.incisor:
        // Chisel-shaped crown with a flat incisal (bottom) edge.
        final r = Radius.circular(w * 0.28);
        crown.addRRect(RRect.fromLTRBAndCorners(
          w * 0.14, crownTop, w * 0.86, bottom,
          topLeft: r,
          topRight: r,
          bottomLeft: const Radius.circular(4),
          bottomRight: const Radius.circular(4),
        ));
        break;
      case ToothType.canine:
        // Pointed cusp at the bottom.
        crown
          ..moveTo(w * 0.18, crownTop + h * 0.05)
          ..quadraticBezierTo(cx, crownTop - h * 0.04, w * 0.82, crownTop + h * 0.05)
          ..lineTo(w * 0.74, bottom * 0.86)
          ..quadraticBezierTo(cx, bottom, w * 0.26, bottom * 0.86)
          ..close();
        break;
      case ToothType.molar:
        // Broad crown with two small cusps on the chewing (bottom) edge.
        final r = Radius.circular(w * 0.22);
        crown.addRRect(RRect.fromLTRBAndCorners(
          w * 0.12, crownTop, w * 0.88, bottom,
          topLeft: r,
          topRight: r,
          bottomLeft: r,
          bottomRight: r,
        ));
        break;
    }

    canvas.drawPath(roots, fill);
    canvas.drawPath(crown, fill);
    if (!erupted) {
      canvas.drawPath(roots, stroke);
      canvas.drawPath(crown, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ToothPainter old) =>
      old.erupted != erupted || old.color != color || old.type != type ||
      old.upper != upper;
}
