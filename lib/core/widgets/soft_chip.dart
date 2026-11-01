import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';

/// A fully rounded (pill) chip with soft styling.
///
/// Works as a static tag or as a selectable filter chip. When [selected] it
/// fills with the active primary color; otherwise it uses the soft tint.
class SoftChip extends ConsumerWidget {
  const SoftChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  /// Chip text.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the chip is in the selected state.
  final bool selected;

  /// Optional tap handler (makes it behave like a choice chip).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final Color bg = selected
        ? colors.primary
        : (isDark ? Colors.white.withValues(alpha: 0.08) : colors.soft);
    final Color fg = selected
        ? Colors.white
        : (isDark ? Colors.white : colors.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillAll,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          constraints: const BoxConstraints(minHeight: 40),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
