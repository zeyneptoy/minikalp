import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';

/// A single destination in the [GlassBottomNavBar].
class GlassNavItem {
  const GlassNavItem({required this.icon, required this.label});

  /// Rounded icon for the destination.
  final IconData icon;

  /// Turkish label shown under the selected icon.
  final String label;
}

/// A frosted-glass bottom navigation bar.
///
/// The selected destination animates into a pill that shows its label; the
/// whole bar and the selection use the active gender palette.
class GlassBottomNavBar extends ConsumerWidget {
  const GlassBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  /// Destinations (3-5 recommended).
  final List<GlassNavItem> items;

  /// Index of the selected destination.
  final int currentIndex;

  /// Called with the tapped index.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fill = (isDark ? const Color(0xFF2A2430) : Colors.white)
        .withValues(alpha: isDark ? 0.4 : 0.6);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.pillAll,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: AppRadius.pillAll,
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < items.length; i++)
                    _NavButton(
                      item: items[i],
                      selected: i == currentIndex,
                      primary: colors.primary,
                      soft: colors.soft,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One tappable destination. Expands into a labelled pill when selected.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.primary,
    required this.soft,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final Color primary;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedFg = isDark ? Colors.white70 : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.pillAll,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? AppSpacing.lg : AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: AppRadius.pillAll,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 24,
                color: selected ? Colors.white : unselectedFg,
              ),
              // Animate the label in/out with the selection.
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Text(
                          item.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
