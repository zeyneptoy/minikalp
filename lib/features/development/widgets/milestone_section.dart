import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/milestones_mock.dart';
import '../../../core/providers/development_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../core/widgets/widgets.dart';

/// Monthly milestone checklist. The baby's current month is shown as an open
/// card with a progress bar; other months are collapsible.
class MilestoneSection extends ConsumerWidget {
  const MilestoneSection({super.key});

  String _key(int month, int index) => '$month:$index';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(babyProfileProvider);
    final checked = ref.watch(milestoneCheckProvider);
    final month = profile == null
        ? 0
        : AgeCalculator.calculate(profile.birthDate).months.clamp(0, 12);

    final current = MilestonesMock.forMonth(month);
    var checkedCount = 0;
    for (var i = 0; i < current.length; i++) {
      if (checked.contains(_key(month, i))) checkedCount++;
    }
    final progress = current.isEmpty ? 0.0 : checkedCount / current.length;

    final otherMonths = [
      for (var m = 0; m <= 12; m++)
        if (m != month) m,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(title: 'Gelişim Basamakları'),
        const SizedBox(height: AppSpacing.sm),
        // Current month, open by default.
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('$month. Ay Gelişimi',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  Text('$checkedCount / ${current.length}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _Progress(value: progress),
              const SizedBox(height: AppSpacing.sm),
              for (var i = 0; i < current.length; i++)
                _MilestoneTile(
                  label: current[i],
                  checked: checked.contains(_key(month, i)),
                  onChanged: () => ref
                      .read(milestoneCheckProvider.notifier)
                      .toggle(_key(month, i)),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (final m in otherMonths)
                Theme(
                  // Remove the default expansion divider lines.
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll,
                    ),
                    title: Text('$m. Ay',
                        style: Theme.of(context).textTheme.titleMedium),
                    children: [
                      for (var i = 0;
                          i < MilestonesMock.forMonth(m).length;
                          i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: _MilestoneTile(
                            label: MilestonesMock.forMonth(m)[i],
                            checked: checked.contains(_key(m, i)),
                            onChanged: () => ref
                                .read(milestoneCheckProvider.notifier)
                                .toggle(_key(m, i)),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Progress extends ConsumerWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    return ClipRRect(
      borderRadius: AppRadius.pillAll,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 350),
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 8,
          backgroundColor: colors.soft,
          valueColor: AlwaysStoppedAnimation(colors.primary),
        ),
      ),
    );
  }
}

class _MilestoneTile extends ConsumerWidget {
  const _MilestoneTile({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: onChanged,
      child: Semantics(
        checked: checked,
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: checked ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary, width: 1.8),
                ),
                child: checked
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
