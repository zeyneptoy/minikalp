import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';

/// A pill-shaped, glassy segmented control. The selected segment slides with a
/// gender-colored fill. Segments share the width equally.
class PillSegmentedControl extends ConsumerWidget {
  const PillSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final fill = (isDark ? const Color(0xFF2A2430) : Colors.white)
        .withValues(alpha: isDark ? 0.4 : 0.55);

    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.pillAll,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segWidth = constraints.maxWidth / segments.length;
              return Stack(
                children: [
                  // Sliding selected indicator.
                  AnimatedAlign(
                    alignment: Alignment(
                      segments.length == 1
                          ? 0
                          : -1 + 2 * (selectedIndex / (segments.length - 1)),
                      0,
                    ),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    child: Container(
                      width: segWidth,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: AppRadius.pillAll,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < segments.length; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onChanged(i),
                            child: SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  segments[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: i == selectedIndex
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
