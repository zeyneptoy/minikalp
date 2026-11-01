import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';

/// A 1–5 star rating selector (icon-based, no emoji). Used for sleep quality.
class StarRating extends ConsumerWidget {
  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= max; i++)
          GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Icon(
                i <= value ? Icons.star_rounded : Icons.star_outline_rounded,
                color: colors.primary,
                size: 40,
              ),
            ),
          ),
      ],
    );
  }
}
