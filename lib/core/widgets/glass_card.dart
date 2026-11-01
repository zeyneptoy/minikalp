import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// A frosted-glass (glassmorphism) card.
///
/// Combines a [BackdropFilter] blur with a translucent fill, a hairline white
/// border and a very soft, wide shadow. Used for the most important surfaces
/// in the app. Place it over an [AppBackground] so the blur has colorful
/// content to sample.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.card,
    this.blur = 18,
    this.opacity = 0.55,
    this.onTap,
    this.margin,
  });

  /// Content of the card.
  final Widget child;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  /// Corner radius.
  final double radius;

  /// Gaussian blur sigma for the backdrop (16-24 looks best).
  final double blur;

  /// Fill opacity of the glass tint (0.45-0.65 recommended).
  final double opacity;

  /// Optional tap handler (adds an ink ripple).
  final VoidCallback? onTap;

  /// Optional outer margin.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(radius);

    // In dark mode the glass fill is a translucent dark tone; in light mode a
    // translucent white. This keeps the frosted look in both themes.
    final fill = (isDark ? const Color(0xFF2A2430) : Colors.white)
        .withValues(alpha: isDark ? (opacity * 0.6) : opacity);
    final borderColor = Colors.white.withValues(alpha: isDark ? 0.12 : 0.6);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Soft, tight shadow. Kept small so it doesn't get clipped (and look
        // cut-off) inside horizontally scrolling lists.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: borderRadius,
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
