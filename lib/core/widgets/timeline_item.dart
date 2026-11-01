import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';

/// A single entry in a vertical activity timeline (feeding, sleep, diaper…).
///
/// Draws a colored dot with a connecting line, a title/subtitle block and an
/// optional trailing time label. Set [isFirst]/[isLast] to trim the connector
/// line at the ends of the list.
class TimelineItem extends ConsumerWidget {
  const TimelineItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.time,
    this.isFirst = false,
    this.isLast = false,
  });

  /// Icon shown inside the timeline dot.
  final IconData icon;

  /// Primary description of the event.
  final String title;

  /// Optional secondary detail.
  final String? subtitle;

  /// Optional trailing time text (e.g. "14:30").
  final String? time;

  /// Whether this is the first item (no line above the dot).
  final bool isFirst;

  /// Whether this is the last item (no line below the dot).
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final lineColor = colors.primary.withValues(alpha: 0.25);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The connector + dot column.
          Column(
            children: [
              Container(
                width: 2,
                height: AppSpacing.sm,
                color: isFirst ? Colors.transparent : lineColor,
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.soft,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 1.5),
                ),
                child: Icon(icon, size: 18, color: colors.primary),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : lineColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          // The content.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(subtitle!, style: theme.textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (time != null)
                    Text(
                      time!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
