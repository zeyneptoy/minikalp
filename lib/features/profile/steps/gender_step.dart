import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_profile.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../widgets/step_layout.dart';

/// Step 3 — gender selection. Choosing an option immediately animates the
/// whole screen's color theme to the matching palette (live preview), because
/// [genderProvider] drives [appColorsProvider] / [AppBackground].
class GenderStep extends ConsumerWidget {
  const GenderStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(profileDraftProvider).gender;

    return StepLayout(
      title: 'Bebeğinizin cinsiyeti?',
      subtitle: 'Seçtiğin renk tüm uygulamanın temasını belirler.',
      child: Column(
        children: [
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _GenderOptionCard(
                gender: option.gender,
                label: option.label,
                icon: option.icon,
                selected: selected == option.gender,
                onTap: () {
                  // Update the draft and the live theme in one tap.
                  ref
                      .read(profileDraftProvider.notifier)
                      .setGender(option.gender);
                  ref
                      .read(genderProvider.notifier)
                      .setGender(option.gender);
                },
              ),
            ),
        ],
      ),
    );
  }

  static const List<_GenderOption> _options = [
    _GenderOption(Gender.girl, 'Kız', Icons.female_rounded),
    _GenderOption(Gender.boy, 'Erkek', Icons.male_rounded),
    _GenderOption(
      Gender.unspecified,
      'Belirtmek istemiyorum',
      Icons.favorite_rounded,
    ),
  ];
}

class _GenderOption {
  const _GenderOption(this.gender, this.label, this.icon);
  final Gender gender;
  final String label;
  final IconData icon;
}

/// A large selectable glass card for one gender option. Uses that gender's own
/// palette so the three options preview pink / blue / orange side by side.
class _GenderOptionCard extends StatelessWidget {
  const _GenderOptionCard({
    required this.gender,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final Gender gender;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Each card shows its own gender color, regardless of the active theme.
    final palette = AppThemeColors.forGender(gender);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? palette.primary : palette.soft.withValues(alpha: 0.6),
          borderRadius: const BorderRadius.all(
            Radius.circular(AppRadius.cardLarge),
          ),
          border: Border.all(
            color: selected ? palette.primary : palette.accent,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : palette.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : palette.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? Colors.white : AppNeutrals.textStrong,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
