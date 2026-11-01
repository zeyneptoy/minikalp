import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../forms/stool_form.dart';
import '../widgets/field_label.dart';

/// Kaka segment: the stool form plus a wet/dirty diaper counter.
class StoolSection extends StatelessWidget {
  const StoolSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _DiaperCounterCard(),
        SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: StoolForm(),
        ),
      ],
    );
  }
}

/// A live counter of today's wet/dirty diapers with quick-add buttons.
class _DiaperCounterCard extends ConsumerWidget {
  const _DiaperCounterCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayRecordsProvider).whereType<DiaperRecord>();
    final wet = today.where((r) => r.kind.isWet).length;
    final dirty = today.where((r) => r.kind.isDirty).length;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Bugünkü bez sayısı'),
          Row(
            children: [
              Expanded(
                child: _CounterTile(
                  label: 'Islak',
                  count: wet,
                  icon: Icons.water_drop_rounded,
                  onAdd: () => ref
                      .read(recordsProvider.notifier)
                      .add(DiaperRecord(kind: DiaperKind.wet)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _CounterTile(
                  label: 'Kirli',
                  count: dirty,
                  icon: Icons.baby_changing_station_rounded,
                  onAdd: () => ref
                      .read(recordsProvider.notifier)
                      .add(DiaperRecord(kind: DiaperKind.dirty)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CounterTile extends ConsumerWidget {
  const _CounterTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.onAdd,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.soft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: AppSpacing.xs),
          Text('$count',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
