import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/profile_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/confetti_overlay.dart';

/// Short celebration shown after the profile is created: "Merhaba [Ad]!" with
/// a light confetti animation, then it auto-navigates to home.
class CelebrationScreen extends ConsumerStatefulWidget {
  const CelebrationScreen({super.key});

  @override
  ConsumerState<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends ConsumerState<CelebrationScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-continue to home after the celebration plays.
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final profile = ref.watch(babyProfileProvider);
    final name = profile?.name ?? '';

    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      radius: AppRadius.pill,
                      child: Icon(
                        Icons.celebration_rounded,
                        size: 64,
                        color: colors.primary,
                      ),
                    )
                        .animate()
                        .scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                          begin: const Offset(0.4, 0.4),
                          end: const Offset(1, 1),
                        )
                        .fadeIn(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Merhaba $name!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                        .animate(delay: 300.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Profilin hazır. Birlikte minik anları takip edelim.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ).animate(delay: 600.ms).fadeIn(duration: 500.ms),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      label: 'Ana Sayfaya Git',
                      icon: Icons.home_rounded,
                      expand: false,
                      onPressed: () => context.go(AppRoutes.home),
                    ).animate(delay: 900.ms).fadeIn(duration: 500.ms),
                  ],
                ),
              ),
            ),
            // Confetti above the content.
            Positioned.fill(
              child: ConfettiOverlay(
                colors: [colors.primary, colors.accent, colors.soft],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
