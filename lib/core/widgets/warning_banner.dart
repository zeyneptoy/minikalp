import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Severity levels for [WarningBanner].
enum WarningLevel {
  /// Soft blue — general information.
  info,

  /// Soft yellow — gentle caution.
  caution,

  /// Soft red-orange — important, needs attention.
  important,
}

/// A soft informational banner with three severity levels.
///
/// Colors are intentionally gentle so even the "important" level feels
/// reassuring rather than alarming to a tired parent.
class WarningBanner extends StatelessWidget {
  const WarningBanner({
    super.key,
    required this.level,
    required this.message,
    this.title,
    this.onClose,
  });

  /// Severity, which picks the color scheme and default icon.
  final WarningLevel level;

  /// Main message text.
  final String message;

  /// Optional bold title above the message.
  final String? title;

  /// Optional close handler (shows a dismiss button when provided).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg, icon) = _styleFor(level);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: theme.textTheme.titleMedium?.copyWith(color: fg),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: fg.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(Icons.close_rounded, color: fg, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  /// Returns (background, foreground, icon) for a level.
  (Color, Color, IconData) _styleFor(WarningLevel level) {
    switch (level) {
      case WarningLevel.info:
        return (
          AppNeutrals.infoBg,
          AppNeutrals.infoFg,
          Icons.info_rounded,
        );
      case WarningLevel.caution:
        return (
          AppNeutrals.cautionBg,
          AppNeutrals.cautionFg,
          Icons.warning_amber_rounded,
        );
      case WarningLevel.important:
        return (
          AppNeutrals.importantBg,
          AppNeutrals.importantFg,
          Icons.priority_high_rounded,
        );
    }
  }
}
