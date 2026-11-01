import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// Content for a single onboarding page.
class _OnboardPage {
  const _OnboardPage({
    required this.icons,
    required this.title,
    required this.subtitle,
  });

  /// Icon composition (main + two accents) forming a soft illustration.
  final List<IconData> icons;
  final String title;
  final String subtitle;
}

/// Three-page intro carousel with a skip button, dot indicator and a final
/// "Başlayalım" button that starts profile creation.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      icons: [
        Icons.local_drink_rounded,
        Icons.schedule_rounded,
        Icons.favorite_rounded,
      ],
      title: 'Beslenmeyi takip et',
      subtitle:
          'Emzirme ve biberon zamanlarını saniyeler içinde kaydet, '
          'düzeni tek bakışta gör.',
    ),
    _OnboardPage(
      icons: [
        Icons.baby_changing_station_rounded,
        Icons.science_rounded,
        Icons.sick_rounded,
      ],
      title: 'Kaka ve kusmayı kaydet, anlamlandır',
      subtitle:
          'Renk ve sıklığı not al; neyin normal, neyin dikkat gerektirdiğini '
          'birlikte anlayalım.',
    ),
    _OnboardPage(
      icons: [
        Icons.insights_rounded,
        Icons.notifications_active_rounded,
        Icons.auto_graph_rounded,
      ],
      title: 'Akıllı analiz ve uyarılar',
      subtitle:
          'Grafikler ve nazik hatırlatmalarla bebeğinin gelişimini '
          'rahatça izle.',
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  void _finish() => context.go(AppRoutes.profileCreate);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip button.
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text('Atla'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _OnboardPageView(
                    page: _pages[i],
                    key: ValueKey(i),
                  ),
                ),
              ),
              _DotIndicator(count: _pages.length, index: _index),
              const SizedBox(height: AppSpacing.xl),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: PrimaryButton(
                  label: _isLast ? 'Başlayalım' : 'Devam',
                  icon: _isLast
                      ? Icons.celebration_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: colors.backgroundGradientStart,
    );
  }
}

/// Renders one onboarding page with an icon composition and text.
class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({required this.page, super.key});

  final _OnboardPage page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconComposition(icons: page.icons)
              .animate()
              .fadeIn(duration: 450.ms)
              .scale(begin: const Offset(0.85, 0.85), end: const Offset(1, 1)),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ).animate(delay: 120.ms).fadeIn(duration: 450.ms).slideY(
                begin: 0.2,
                end: 0,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 450.ms),
        ],
      ),
    );
  }
}

/// A soft illustration built from one large icon plus two small accents in a
/// frosted glass circle.
class _IconComposition extends ConsumerWidget {
  const _IconComposition({required this.icons});

  final List<IconData> icons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            radius: AppRadius.pill,
            child: Icon(icons.first, size: 72, color: colors.primary),
          ),
          Positioned(
            top: 8,
            right: 18,
            child: _AccentBubble(icon: icons[1], color: colors.primary),
          ),
          Positioned(
            bottom: 12,
            left: 10,
            child: _AccentBubble(icon: icons[2], color: colors.accent),
          ),
        ],
      ),
    );
  }
}

/// Small circular accent used by [_IconComposition].
class _AccentBubble extends StatelessWidget {
  const _AccentBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }
}

/// Animated dot page indicator; the active dot stretches into a pill.
class _DotIndicator extends ConsumerWidget {
  const _DotIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: i == index ? 26 : 9,
            height: 9,
            decoration: BoxDecoration(
              color: i == index
                  ? colors.primary
                  : colors.primary.withValues(alpha: 0.25),
              borderRadius: AppRadius.pillAll,
            ),
          ),
      ],
    );
  }
}
