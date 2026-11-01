import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../forms/breastfeeding_form.dart';
import '../forms/formula_form.dart';
import '../forms/solid_food_form.dart';
import '../widgets/pill_segmented_control.dart';

/// Beslenme segment: breastfeeding, bottle and (for 6+ months) solid food,
/// plus an expressed-milk stock mini card.
class FeedingSection extends ConsumerStatefulWidget {
  const FeedingSection({super.key});

  @override
  ConsumerState<FeedingSection> createState() => _FeedingSectionState();
}

class _FeedingSectionState extends ConsumerState<FeedingSection> {
  int _mode = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(babyProfileProvider);
    final months = profile == null
        ? 0
        : AgeCalculator.calculate(profile.birthDate).months;
    final showSolids = months >= 6;

    final segments = ['Emzirme', 'Mama', if (showSolids) 'Ek Gıda'];
    // Clamp the selected index if solids just became unavailable.
    final mode = _mode.clamp(0, segments.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExpressedMilkCard(),
        const SizedBox(height: AppSpacing.lg),
        PillSegmentedControl(
          segments: segments,
          selectedIndex: mode,
          onChanged: (i) => setState(() => _mode = i),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _formForMode(mode, showSolids),
        ),
      ],
    );
  }

  Widget _formForMode(int mode, bool showSolids) {
    if (mode == 0) return const BreastfeedingForm();
    if (mode == 1) return const FormulaForm();
    return const SolidFoodForm();
  }
}

/// Mini card showing the expressed (pumped) milk stock with +/- controls.
class _ExpressedMilkCard extends ConsumerWidget {
  const _ExpressedMilkCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final stock = ref.watch(expressedMilkStockProvider);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_rounded, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sağılmış süt stoğu',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text('$stock ml', style: theme.textTheme.titleLarge),
              ],
            ),
          ),
          IconButton(
            onPressed: stock >= 10
                ? () => ref.read(expressedMilkStockProvider.notifier).adjust(-10)
                : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          IconButton(
            onPressed: () =>
                ref.read(expressedMilkStockProvider.notifier).adjust(10),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}
