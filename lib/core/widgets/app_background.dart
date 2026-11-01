import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

/// A soft, animated gradient background with blurred colored "blobs".
///
/// Gives the glass surfaces something colorful to sample through their blur.
/// The colors come from the active gender palette and animate smoothly when
/// the gender (and therefore the theme) changes.
class AppBackground extends ConsumerWidget {
  const AppBackground({super.key, required this.child});

  /// Foreground content drawn above the background.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? const [AppNeutrals.darkGradientStart, AppNeutrals.darkGradientEnd]
        : [colors.backgroundGradientStart, colors.backgroundGradientEnd];

    return AnimatedContainer(
      duration: AppConstants.themeAnimationDuration,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Decorative blurred blobs.
          _Blob(
            color: colors.accent.withValues(alpha: isDark ? 0.22 : 0.45),
            diameter: 260,
            alignment: const Alignment(-1.1, -0.9),
          ),
          _Blob(
            color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.30),
            diameter: 220,
            alignment: const Alignment(1.2, -0.4),
          ),
          _Blob(
            color: colors.soft.withValues(alpha: isDark ? 0.14 : 0.70),
            diameter: 300,
            alignment: const Alignment(1.0, 1.1),
          ),
          // Content.
          child,
        ],
      ),
    );
  }
}

/// A single soft, blurred circular color blob used by [AppBackground].
class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.diameter,
    required this.alignment,
  });

  final Color color;
  final double diameter;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: AnimatedContainer(
          duration: AppConstants.themeAnimationDuration,
          curve: Curves.easeInOut,
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
