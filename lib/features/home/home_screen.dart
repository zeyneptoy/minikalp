import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/mock/home_mock.dart';
import '../../core/models/baby_record.dart';
import '../../core/models/info_article.dart';
import '../../core/models/record_type.dart';
import '../../core/providers/info_articles_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/records_provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/widgets/widgets.dart';
import '../info/info_article_screen.dart';
import '../tracking/record_sheets.dart';

/// The main dashboard. Combines age-aware mock guidance (alerts, tip, next
/// feeding) with live data from the in-memory records repository (timeline,
/// daily summary, last feeding). Everything sits in one scroll view so nothing
/// overflows on small phones.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(babyProfileProvider);

    final birthDate = profile?.birthDate ??
        DateTime.now().subtract(const Duration(days: 74));
    final age = AgeCalculator.calculate(birthDate);
    final data = HomeMock.forAge(age);
    final name = profile?.name ?? 'Bebeğim';

    // Live data from the repository.
    final summary = ref.watch(dailySummaryProvider);
    final timeline = ref.watch(todayRecordsProvider);
    final lastFeeding = ref.watch(lastFeedingProvider) ?? data.lastFeeding;

    final sections = <Widget>[
      _Header(
        name: name,
        ageLabel: AgeCalculator.formatTurkish(age),
        photoPath: profile?.photoPath,
      ),
      const SizedBox(height: AppSpacing.xl),
      _LastFeedingCard(
        lastFeeding: lastFeeding,
        nextEstimate: data.nextFeedingEstimate,
      ),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Hızlı Kayıt'),
      const SizedBox(height: AppSpacing.sm),
      const _QuickGrid(),
      const SectionTitle(title: 'Bugünün Özeti'),
      const SizedBox(height: AppSpacing.sm),
      _SummaryStrip(summary: summary),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Akıllı Uyarılar'),
      const SizedBox(height: AppSpacing.sm),
      _AlertsList(alerts: data.alerts),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Bugün Ne Var?'),
      const SizedBox(height: AppSpacing.sm),
      _TimelineCard(entries: timeline),
      const SizedBox(height: AppSpacing.xl),
      _AgeTipCard(tip: data.tip),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Bilgilendirmeler'),
      const SizedBox(height: AppSpacing.sm),
      const _InfoArticlesList(),
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
                .animate(interval: 55.ms)
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOut),
          ),
        ),
      ),
    );
  }
}

// ----- Header -----

class _Header extends ConsumerWidget {
  const _Header({
    required this.name,
    required this.ageLabel,
    required this.photoPath,
  });

  final String name;
  final String ageLabel;
  final String? photoPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          BabyAvatar(photoPath: photoPath, radius: 30),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merhaba, $name', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(ageLabel, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Bildirimler',
                onPressed: () => _snack(context, 'Yeni bildirim yok.'),
                icon: const Icon(Icons.notifications_rounded),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----- Last feeding -----

class _LastFeedingCard extends ConsumerWidget {
  const _LastFeedingCard({
    required this.lastFeeding,
    required this.nextEstimate,
  });

  final LastFeedingInfo lastFeeding;
  final String nextEstimate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_drink_rounded, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Son beslenme', style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Son ${lastFeeding.agoText} • ${lastFeeding.summary}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 16, color: colors.primary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        nextEstimate,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----- Quick record grid -----

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    final types = RecordType.values;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        // Fixed row height sized to hug the tile content so it neither
        // overflows nor leaves an empty gap below the grid.
        mainAxisExtent: 98,
      ),
      itemBuilder: (context, i) => QuickActionTile(
        icon: types[i].icon,
        label: types[i].label,
        onTap: () => RecordSheets.open(context, types[i]),
      ),
    );
  }
}

// ----- Daily summary (horizontally scrollable chips) -----

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final chips = <_SummaryData>[
      _SummaryData(Icons.local_drink_rounded,
          '${summary.breastfeedingCount}', 'Emzirme'),
      _SummaryData(Icons.local_cafe_rounded, '${summary.formulaMl} ml', 'Mama'),
      _SummaryData(Icons.wc_rounded, '${summary.stoolCount}', 'Kaka'),
      _SummaryData(Icons.baby_changing_station_rounded,
          '${summary.wetDiapers}', 'Islak bez'),
      _SummaryData(Icons.bedtime_rounded, summary.totalSleep, 'Uyku'),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Let card shadows breathe instead of being clipped at the edges.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => _SummaryChip(data: chips[i]),
      ),
    );
  }
}

class _SummaryData {
  const _SummaryData(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;
}

class _SummaryChip extends ConsumerWidget {
  const _SummaryChip({required this.data});

  final _SummaryData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: colors.primary, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ----- Smart alerts -----

class _AlertsList extends StatelessWidget {
  const _AlertsList({required this.alerts});

  final List<SmartAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < alerts.length; i++) ...[
          WarningBanner(
            level: alerts[i].level,
            title: alerts[i].title,
            message: alerts[i].message,
          ),
          if (i != alerts.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// ----- Timeline (live from the records repository) -----

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.entries});

  final List<BabyRecord> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            'Bugün henüz kayıt yok. "+" ile ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    final timeFormat = DateFormat('HH:mm');
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            TimelineItem(
              icon: entries[i].icon,
              title: entries[i].title,
              subtitle: entries[i].detail,
              time: timeFormat.format(entries[i].timestamp),
              isFirst: i == 0,
              isLast: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

// ----- Age-specific tip -----

class _AgeTipCard extends ConsumerWidget {
  const _AgeTipCard({required this.tip});

  final AgeTip tip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.soft,
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(Icons.lightbulb_rounded, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.title, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(tip.message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----- Informational articles -----

class _InfoArticlesList extends ConsumerWidget {
  const _InfoArticlesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(infoArticlesProvider);
    return articles.when(
      loading: () => const GlassCard(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      ),
      error: (_, __) => GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Bilgilendirmeler yüklenemedi.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => ref.invalidate(infoArticlesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
          ],
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Henüz yazı yok.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          children: [
            for (final a in list)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _InfoArticleCard(article: a),
              ),
          ],
        );
      },
    );
  }
}

class _InfoArticleCard extends ConsumerWidget {
  const _InfoArticleCard({required this.article});

  final InfoArticle article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);

    final thumbFallback = Container(
      width: 64,
      height: 64,
      color: colors.soft,
      child: Icon(Icons.menu_book_rounded, color: colors.primary),
    );

    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InfoArticleScreen(article: article),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: (article.imageUrl == null || article.imageUrl!.isEmpty)
                ? thumbFallback
                : Image.network(
                    article.imageUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => thumbFallback,
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(article.excerpt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.primary),
        ],
      ),
    );
  }
}

/// Small helper for the notification tap feedback.
void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
