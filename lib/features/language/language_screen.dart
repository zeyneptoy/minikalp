import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// First-run language selection, shown before the baby profile is created.
/// Offers Turkish, English, German, Arabic, French, Italian, Spanish, Russian.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref, String code) async {
    await ref.read(localeProvider.notifier).setLanguage(code);
    if (!context.mounted) return;
    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colors.soft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.language_rounded,
                      size: 30, color: colors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Dil / Language',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Uygulama dilini seçin · Choose your language',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView.separated(
                    itemCount: kSupportedLanguages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final lang = kSupportedLanguages[i];
                      return GlassCard(
                        onTap: () => _choose(context, ref, lang.code),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Text(lang.flag,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Text(
                                lang.nativeName,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: colors.primary),
                          ],
                        ),
                      )
                          .animate(delay: (40 * i).ms)
                          .fadeIn(duration: 260.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
