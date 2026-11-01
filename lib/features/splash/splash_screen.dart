import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/api/api_providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/data/profile_repository.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// First screen shown at launch: logo + app name with a soft animation.
///
/// While it is visible (kept on screen for a minimum ~2s, the UX sweet spot for
/// a branded launch) it fetches the app config from the backend, checks whether
/// a forced update is required, and then routes to the force-update screen, the
/// language picker (first run), onboarding, or home.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// Minimum time the splash stays visible — long enough to feel intentional,
  /// short enough not to annoy. ~2 seconds is the commonly recommended value.
  static const Duration _minVisible = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      _decideTarget(),
      Future<void>.delayed(_minVisible),
    ]);
    if (!mounted) return;
    context.go(results.first as String);
  }

  Future<String> _decideTarget() async {
    // 1) Version / force-update check (best-effort; offline → skip).
    try {
      final config = await ref
          .read(apiClientProvider)
          .appConfig()
          .timeout(const Duration(seconds: 4));
      ref.read(appConfigDataProvider.notifier).state = config;

      final info = await PackageInfo.fromPlatform();
      final forceFlag = config['force_update'] == true;
      final tooOld =
          _isOlder(info.version, config['min_required_version'] as String?);
      if (forceFlag || tooOld) {
        return AppRoutes.forceUpdate;
      }
    } catch (_) {
      // Network/server unavailable — continue without blocking the user.
    }

    // 2) First run → ask for the language before anything else.
    if (!await hasChosenLanguage()) {
      return AppRoutes.language;
    }

    // 3) Returning user → home if a profile exists, otherwise onboarding.
    final hasProfile = await ProfileRepository.exists();
    return hasProfile ? AppRoutes.home : AppRoutes.onboarding;
  }

  /// True when [current] is a lower version than [minRequired] ("1.0.0" style).
  bool _isOlder(String current, String? minRequired) {
    if (minRequired == null || minRequired.isEmpty) return false;

    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();

    final a = parts(current);
    final b = parts(minRequired);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ref.watch(appColorsProvider);

    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                radius: AppRadius.pill,
                child: const _LogoMark(),
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1, 1),
                  )
                  .fadeIn(duration: 500.ms),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppConstants.appName,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              )
                  .animate(delay: 250.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Minik anların takibi',
                style: theme.textTheme.bodyMedium,
              ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: AppSpacing.xxl),
              // A subtle, on-brand progress indicator while bootstrapping.
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ).animate(delay: 700.ms).fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// The circular baby icon used as the app logo.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Icon(
        Icons.child_care_rounded,
        size: 56,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
