import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';
import 'glass_card.dart';

/// A compact statistic card showing an icon, a big value and a caption.
///
/// Used in dashboard-style rows (e.g. "Son emzirme 2s önce", "Uyku 4s 20dk").
class StatMiniCard extends ConsumerWidget {
  const StatMiniCard({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
    this.onTap,
  });

  /// Leading rounded icon.
  final IconData icon;

  /// Prominent value text.
  final String value;

  /// Small caption describing the value.
  final String caption;

  /// Optional tap handler.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
