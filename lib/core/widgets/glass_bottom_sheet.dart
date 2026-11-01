import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A glassmorphism modal bottom sheet with 32 px top corners.
///
/// Use [GlassBottomSheet.show] to present any content as a frosted sheet with
/// a drag handle and an optional title.
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
    super.key,
    required this.child,
    this.title,
  });

  /// Sheet content below the handle/title.
  final Widget child;

  /// Optional title shown at the top of the sheet.
  final String? title;

  /// Presents [child] inside a frosted bottom sheet and returns its result.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => GlassBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final fill = (isDark ? const Color(0xFF2A2430) : Colors.white)
        .withValues(alpha: isDark ? 0.4 : 0.6);

    return ClipRRect(
      borderRadius: AppRadius.sheetTop,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.sheetTop,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
              width: 1,
            ),
          ),
          child: SafeArea(
            top: false,
            // Lift the whole sheet above the keyboard and allow its content to
            // scroll so fields near the bottom (e.g. the note field) stay
            // visible while typing.
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag handle.
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                            borderRadius: AppRadius.pillAll,
                          ),
                        ),
                      ),
                      if (title != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(title!, style: theme.textTheme.titleLarge),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
