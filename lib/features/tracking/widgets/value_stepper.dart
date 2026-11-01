import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';

/// A rounded +/- stepper for numeric values (ml, temperature, counts).
///
/// Works with doubles; use [step] for the increment and [valueLabel] to format
/// the displayed value (e.g. "90 ml", "37.5°C").
class ValueStepper extends ConsumerWidget {
  const ValueStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.valueLabel,
    this.step = 1,
    this.min = 0,
    this.max = 9999,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String valueLabel;
  final double step;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _RoundButton(
          icon: Icons.remove_rounded,
          color: colors.primary,
          soft: colors.soft,
          onTap: value - step >= min ? () => onChanged(value - step) : null,
        ),
        const SizedBox(width: AppSpacing.xl),
        SizedBox(
          width: 120,
          child: Text(
            valueLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        _RoundButton(
          icon: Icons.add_rounded,
          color: colors.primary,
          soft: colors.soft,
          onTap: value + step <= max ? () => onChanged(value + step) : null,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.color,
    required this.soft,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: soft, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
      ),
    );
  }
}
