import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_config.dart';
import '../../core/api/api_providers.dart';
import '../../core/models/baby_profile.dart';
import '../../core/models/diary_entry.dart';
import '../../core/providers/article_provider.dart';
import '../../core/providers/babies_provider.dart';
import '../../core/providers/development_provider.dart';
import '../../core/providers/diary_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/widgets/widgets.dart';
import 'month_detail_screen.dart';

/// Profil / Ayarlar tab: baby switcher, active baby card, caregiver sharing,
/// mother's health, and settings (theme, notifications, units, language, KVKK,
/// disclaimer).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sections = <Widget>[
      Text('Profil', style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpacing.lg),
      const _BabySwitcher(),
      const SizedBox(height: AppSpacing.xl),
      const _ActiveBabyCard(),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Bu Ayın Rehberi'),
      const SizedBox(height: AppSpacing.sm),
      const _ArticleCard(),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Aylık Gelişim Defteri'),
      const SizedBox(height: AppSpacing.sm),
      const _MonthsStrip(),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Bu Ayın Anne Günlüğü'),
      const SizedBox(height: AppSpacing.sm),
      const _DiaryModule(),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Aile & Bakıcı Paylaşımı'),
      const SizedBox(height: AppSpacing.sm),
      const _SharingCard(),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Anne Sağlığı'),
      const SizedBox(height: AppSpacing.sm),
      const _MotherHealthCard(),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Ayarlar'),
      const SizedBox(height: AppSpacing.sm),
      const _SettingsCard(),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              190,
            ),
            children: sections
                .animate(interval: 45.ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }
}

// ----- Age-appropriate article -----

class _ArticleCard extends ConsumerWidget {
  const _ArticleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final babyId = ref.watch(currentBabyIdProvider);

    if (babyId == null) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Rehber bebeğin yaşına göre hazırlanıyor.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final profile = ref.watch(babyProfileProvider);
    final month = profile == null
        ? 0
        : AgeCalculator.calculate(profile.birthDate).months.clamp(0, 11);

    final article = ref.watch(babyArticleProvider(babyId));

    return article.when(
      loading: () => const GlassCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ),
        ),
      ),
      error: (_, __) => GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Text('Rehber yüklenemedi.',
                  style: theme.textTheme.bodyMedium),
            ),
            TextButton.icon(
              onPressed: () => ref.invalidate(babyArticleProvider(babyId)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
          ],
        ),
      ),
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        return GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Soft banner header.
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.22),
                      colors.accent.withValues(alpha: 0.14),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.6),
                          shape: BoxShape.circle),
                      child: Icon(Icons.menu_book_rounded,
                          color: colors.primary),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$month. ay rehberi',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            data['title'] as String? ?? '',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  data['body'] as String? ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----- Monthly development notebook (month browser) -----

class _MonthsStrip extends ConsumerWidget {
  const _MonthsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final profile = ref.watch(babyProfileProvider);

    final current = profile == null
        ? 0
        : AgeCalculator.calculate(profile.birthDate).months.clamp(0, 11);
    final count = current + 1;

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) {
          // Newest month first.
          final month = current - i;
          return GlassCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MonthDetailScreen(month: month),
              ),
            ),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories_rounded, color: colors.primary),
                const SizedBox(height: AppSpacing.xs),
                Text('$month. ay',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ----- Mother's monthly diary -----

class _DiaryModule extends ConsumerStatefulWidget {
  const _DiaryModule();

  @override
  ConsumerState<_DiaryModule> createState() => _DiaryModuleState();
}

class _DiaryModuleState extends ConsumerState<_DiaryModule> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? _currentMonth() {
    final profile = ref.read(babyProfileProvider);
    if (profile == null) return null;
    final m = AgeCalculator.calculate(profile.birthDate).months;
    return m < 0 ? 0 : (m > 11 ? 11 : m);
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    await ref.read(diaryProvider.notifier).add(text, month: _currentMonth());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final entries = ref.watch(diaryProvider);
    final month = _currentMonth();

    // Group entries by month, newest month first.
    final byMonth = <int, List<DiaryEntry>>{};
    for (final e in entries) {
      byMonth.putIfAbsent(e.month, () => []).add(e);
    }
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Composer for the current month.
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    month == null ? 'Günlük' : '$month. ay günlüğü',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: colors.primary,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Bugün aklına geleni yaz… '
                      '(ör. ilk tatilimiz, ilk gülüşü)',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: colors.soft.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: PrimaryButton(
                  label: 'Ekle',
                  icon: Icons.add_rounded,
                  onPressed: month == null ? null : _save,
                ),
              ),
            ],
          ),
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          for (final m in months) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
                top: AppSpacing.sm,
              ),
              child: Text(
                '$m. ay',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (final e in byMonth[m]!)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DiaryEntryCard(entry: e),
              ),
          ],
        ],
      ],
    );
  }
}

class _DiaryEntryCard extends ConsumerWidget {
  const _DiaryEntryCard({required this.entry});

  final DiaryEntry entry;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: entry.body);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlüğü düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 2,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Notunu güncelle'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await ref.read(diaryProvider.notifier).update(entry.id, result);
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Güncellenemedi.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final d = entry.createdAt;
    final dateLabel = '${d.day}.${d.month}.${d.year}';

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(dateLabel, style: theme.textTheme.bodySmall),
              const Spacer(),
              InkWell(
                onTap: () => _edit(context, ref),
                child: Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              InkWell(
                onTap: () =>
                    ref.read(diaryProvider.notifier).remove(entry.id),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(entry.body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}

// ----- Baby switcher -----

class _BabySwitcher extends ConsumerWidget {
  const _BabySwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(babiesProvider);
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < state.babies.length; i++)
            _BabyChip(
              profile: state.babies[i],
              selected: i == state.activeIndex,
              onTap: () => ref.read(babiesProvider.notifier).setActive(i),
            ),
          _AddBabyChip(onTap: () => context.push(AppRoutes.profileAdd)),
        ],
      ),
    );
  }
}

class _BabyChip extends StatelessWidget {
  const _BabyChip({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final BabyProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemeColors.forGender(profile.gender);
    final theme = Theme.of(context);
    final hasPhoto = profile.photoPath != null && profile.photoPath!.isNotEmpty;

    return Semantics(
      selected: selected,
      button: true,
      label: '${profile.name} profiline geç',
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.accent],
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: palette.soft,
                  backgroundImage:
                      hasPhoto ? FileImage(File(profile.photoPath!)) : null,
                  child: hasPhoto
                      ? null
                      : Icon(Icons.child_care_rounded,
                          color: palette.primary, size: 28),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 68,
                child: Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBabyChip extends ConsumerWidget {
  const _AddBabyChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Bebek ekle',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.soft,
                border: Border.all(color: colors.primary, width: 1.5),
              ),
              child: Icon(Icons.add_rounded, color: colors.primary, size: 28),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Bebek ekle', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ----- Active baby card -----

class _ActiveBabyCard extends ConsumerWidget {
  const _ActiveBabyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(babyProfileProvider);
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          BabyAvatar(photoPath: profile?.photoPath, radius: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(profile?.name ?? 'Profil yok',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          if (profile != null)
            Text(AgeCalculator.describe(profile.birthDate),
                style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          if (profile != null)
            SoftChip(label: profile.gender.label, icon: _genderIcon(profile.gender)),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Profili Düzenle',
            icon: Icons.edit_rounded,
            onPressed: () => context.push(AppRoutes.profileEdit),
          ),
        ],
      ),
    );
  }

  IconData _genderIcon(Gender g) {
    switch (g) {
      case Gender.girl:
        return Icons.female_rounded;
      case Gender.boy:
        return Icons.male_rounded;
      case Gender.unspecified:
        return Icons.favorite_rounded;
    }
  }
}

// ----- Caregiver sharing (UI only) -----

class _SharingCard extends ConsumerWidget {
  const _SharingCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('Aileyle paylaş',
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Eş veya bakıcıyı davet ederek kayıtları birlikte tutabilirsiniz.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: const [
              SoftChip(label: 'Anne', icon: Icons.person_rounded, selected: true),
              SoftChip(label: 'Baba', icon: Icons.person_outline_rounded),
              SoftChip(label: 'Bakıcı', icon: Icons.person_outline_rounded),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Davet Bağlantısı Oluştur',
            icon: Icons.link_rounded,
            outlined: true,
            onPressed: () => _snack(context, 'Paylaşım yakında eklenecek.'),
          ),
        ],
      ),
    );
  }
}

// ----- Mother's health -----

class _MotherHealthCard extends ConsumerWidget {
  const _MotherHealthCard();

  static const List<IconData> _moods = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final moods = ref.watch(moodProvider);

    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ruh hali günlüğü', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('Bugün nasıl hissediyorsun?',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _moods.length; i++)
                    IconButton(
                      tooltip: '${i + 1} / 5',
                      iconSize: 34,
                      color: colors.primary,
                      onPressed: () {
                        ref.read(moodProvider.notifier).add(i + 1);
                        _snack(context, 'Ruh hali kaydedildi.');
                      },
                      icon: Icon(_moods[i]),
                    ),
                ],
              ),
              if (moods.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text('${moods.length} kayıt',
                      style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----- Settings -----

class _SettingsCard extends ConsumerWidget {
  const _SettingsCard();

  Future<void> _editServer(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sunucu adresi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Gerçek telefonda bilgisayarınızın IP adresini girin. '
              'Örn: http://192.168.1.20:8000',
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.20:8000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await ApiConfig.save(result);
    // Re-attempt backend sync so data starts flowing at the new address.
    await ref.read(babiesProvider.notifier).retrySync();
    messenger.showSnackBar(
      SnackBar(content: Text('Sunucu adresi kaydedildi: ${ApiConfig.baseUrl}')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
            ),
            title: const Text('Gece modu'),
            value: themeMode == ThemeMode.dark,
            onChanged: (v) => ref.read(themeModeProvider.notifier).setDark(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_rounded),
            title: const Text('Bildirimler'),
            value: settings.notifications,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotifications(v),
          ),
          _SettingRow(
            icon: Icons.local_drink_rounded,
            title: 'Hacim birimi',
            child: SegmentedButton<VolumeUnit>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: VolumeUnit.ml, label: Text('ml')),
                ButtonSegment(value: VolumeUnit.oz, label: Text('oz')),
              ],
              selected: {settings.volumeUnit},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setVolumeUnit(s.first),
            ),
          ),
          _SettingRow(
            icon: Icons.monitor_weight_rounded,
            title: 'Ağırlık birimi',
            child: SegmentedButton<WeightUnit>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
              ],
              selected: {settings.weightUnit},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setWeightUnit(s.first),
            ),
          ),
          _SettingRow(
            icon: Icons.language_rounded,
            title: 'Dil',
            child: SegmentedButton<AppLanguage>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: AppLanguage.tr, label: Text('TR')),
                ButtonSegment(value: AppLanguage.en, label: Text('EN')),
              ],
              selected: {settings.language},
              onSelectionChanged: (s) =>
                  ref.read(settingsProvider.notifier).setLanguage(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dns_rounded),
            title: const Text('Sunucu adresi'),
            subtitle: Text(
              ApiConfig.baseUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
            trailing: const Icon(Icons.edit_rounded),
            onTap: () => _editServer(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_rounded),
            title: const Text('KVKK & Gizlilik'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.medical_information_rounded),
            title: const Text('Tıbbi Sorumluluk Reddi'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.disclaimer),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'MiniKalp prototip sürümü',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// A settings row with a leading icon, a title and a trailing control.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          child,
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
