import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_providers.dart';
import '../../core/providers/development_provider.dart';
import '../../core/providers/diary_provider.dart';
import '../../core/providers/month_summary_provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';

/// Shows everything recorded during a single month of the baby's life:
/// photos, a records summary (feeding / stool / sleep), completed skills
/// (milestones) and the mother's diary for that month.
class MonthDetailScreen extends ConsumerWidget {
  const MonthDetailScreen({super.key, required this.month});

  final int month;

  String _sleep(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '${h}s ${m}dk';
  }

  /// Picks a photo from the gallery and uploads it tagged with THIS month.
  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final babyId = ref.read(currentBabyIdProvider);
    if (babyId == null) return;
    try {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1000);
      if (file == null) return;
      await ref.read(apiClientProvider).createPhoto(
        babyId,
        {'path': file.path, 'month': month},
      );
      ref.invalidate(monthSummaryProvider(month));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf eklenemedi.')),
        );
      }
    }
  }

  /// Confirms and deletes a photo, then refreshes the month view.
  Future<void> _confirmDeletePhoto(
      BuildContext context, WidgetRef ref, int photoId) async {
    final babyId = ref.read(currentBabyIdProvider);
    if (babyId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fotoğrafı sil'),
        content: const Text('Bu fotoğrafı silmek istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiClientProvider).deletePhoto(babyId, photoId);
      ref.invalidate(monthSummaryProvider(month));
    } catch (_) {/* ignore */}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = ref.watch(appColorsProvider);
    final summaryAsync = ref.watch(monthSummaryProvider(month));

    final milestonesDone = ref
        .watch(milestoneCheckProvider)
        .where((k) => k.startsWith('$month:'))
        .length;
    final diary =
        ref.watch(diaryProvider).where((e) => e.month == month).toList();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Geri',
                    ),
                    Text('$month. ay',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Expanded(
                child: summaryAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4)),
                  error: (_, __) => Center(
                    child: Text('Veriler yüklenemedi.',
                        style: theme.textTheme.bodyMedium),
                  ),
                  data: (s) => ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                    children: [
                      // Photos.
                      Row(
                        children: [
                          const Expanded(
                              child: SectionTitle(title: 'Fotoğraflar')),
                          TextButton.icon(
                            onPressed: () => _addPhoto(context, ref),
                            icon: const Icon(Icons.add_a_photo_rounded),
                            label: const Text('Ekle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (s.photos.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text('Bu aya ait fotoğraf yok.',
                              style: theme.textTheme.bodyMedium),
                        )
                      else
                        SizedBox(
                          height: 110,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: s.photos.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, i) => GestureDetector(
                              onLongPress: () =>
                                  _confirmDeletePhoto(context, ref, s.photos[i].id),
                              child: ClipRRect(
                                borderRadius: AppRadius.mdAll,
                                child: Image.file(
                                  File(s.photos[i].path),
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 110,
                                    height: 110,
                                    color: colors.soft,
                                    child: Icon(Icons.image_rounded,
                                        color: colors.primary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),

                      // Records summary.
                      SectionTitle(title: 'Bu ayki kayıtlar'),
                      const SizedBox(height: AppSpacing.sm),
                      GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            _row(theme, Icons.local_drink_rounded, 'Emzirme',
                                '${s.feeding} kez', colors),
                            _row(theme, Icons.local_cafe_rounded, 'Mama',
                                '${s.formulaMl} ml', colors),
                            _row(theme, Icons.wc_rounded, 'Kaka',
                                '${s.stool} kez', colors),
                            _row(theme, Icons.baby_changing_station_rounded,
                                'Islak bez', '${s.wet}', colors),
                            _row(theme, Icons.bedtime_rounded, 'Uyku',
                                _sleep(s.sleepSeconds), colors),
                            _row(theme, Icons.emoji_events_rounded,
                                'Tamamlanan beceri', '$milestonesDone', colors),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Diary for the month.
                      SectionTitle(title: 'Anne günlüğü'),
                      const SizedBox(height: AppSpacing.sm),
                      if (diary.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text('Bu aya ait günlük kaydı yok.',
                              style: theme.textTheme.bodyMedium),
                        )
                      else
                        for (final e in diary)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: GlassCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(e.body,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(height: 1.4)),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, IconData icon, String label, String value,
      dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
