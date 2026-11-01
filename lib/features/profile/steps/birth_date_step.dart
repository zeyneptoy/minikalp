import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/step_layout.dart';

/// Step 2 — birth date selection with a live age preview.
///
/// The date picker only allows dates within the last 12 months (not in the
/// future, not older than a year); an info banner explains the constraint. The
/// age is derived automatically with [AgeCalculator] and shown live.
class BirthDateStep extends ConsumerWidget {
  const BirthDateStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final selected = draft.birthDate;
    final dateFormat = DateFormat('d MMMM y', 'tr_TR');

    return StepLayout(
      title: 'Doğum tarihi ne zaman?',
      subtitle: 'Yaşı otomatik hesaplayıp sana göstereceğiz.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WarningBanner(
            level: WarningLevel.info,
            message: 'MiniKalp 0-12 ay arası bebekler için tasarlandı. '
                'Gelecek tarihler ve 12 aydan büyük tarihler seçilemez.',
          ),
          const SizedBox(height: AppSpacing.xl),
          // Date selector button (opens the rounded date picker).
          GlassCard(
            onTap: () => _pickDate(context, ref),
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
                  child: Icon(Icons.event_rounded, color: colors.primary),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Doğum tarihi', style: theme.textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        selected == null
                            ? 'Tarih seç'
                            : dateFormat.format(selected),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.primary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Live age preview.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: selected == null
                ? const SizedBox.shrink()
                : _AgePreviewCard(
                    key: ValueKey(selected),
                    label: AgeCalculator.describe(selected),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 12 months ago is the oldest allowed birth date.
    final earliest = DateTime(now.year, now.month - 12, now.day);
    final current = ref.read(profileDraftProvider).birthDate ?? today;

    final picked = await showCupertinoDateSheet(
      context,
      initial: current,
      firstDate: earliest,
      lastDate: today,
      title: 'Doğum tarihini seç',
    );

    if (picked != null) {
      ref.read(profileDraftProvider.notifier).setBirthDate(picked);
    }
  }
}

/// Soft card showing the computed age (e.g. "2 ay 14 günlük").
class _AgePreviewCard extends ConsumerWidget {
  const _AgePreviewCard({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.cake_rounded, color: colors.primary, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text('Bebeğiniz şu an', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
