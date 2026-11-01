import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/mock/analytics_mock.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/age_calculator.dart';
import '../../core/widgets/widgets.dart';
import '../tracking/widgets/pill_segmented_control.dart';
import 'widgets/analytics_charts.dart';

/// Analiz tab: period selector + themed fl_chart charts in glass cards, smart
/// insight cards and a (non-functional) doctor report preview.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsPeriod _period = AnalyticsPeriod.weekly;

  Future<void> _sendReport() async {
    final babyId = ref.read(currentBabyIdProvider);
    if (babyId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
            content: Text('Önce bir bebek profili oluşturun.')));
      return;
    }

    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Doktora gönder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Raporun gönderileceği e-posta adresini girin.'),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'ornek@eposta.com',
                prefixIcon: Icon(Icons.mail_outline_rounded),
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
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty || !mounted) return;

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    final messenger = ScaffoldMessenger.of(context);
    if (!valid) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Geçerli bir e-posta girin.')));
      return;
    }

    try {
      final message = await ref.read(apiClientProvider).sendReport(babyId, email);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Rapor gönderilemedi.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = ref.watch(analyticsProvider(_period));

    final cards = <Widget>[
      _ChartCard(
        title: 'Beslenme Sıklığı',
        child: FeedingBarChart(data: data.feeding),
      ),
      const SizedBox(height: AppSpacing.lg),
      _ChartCard(
        title: 'Uyku Süresi (saat)',
        child: SleepLineChart(data: data.sleep),
      ),
      const SizedBox(height: AppSpacing.lg),
      _ChartCard(
        title: 'Kaka Renk Dağılımı',
        child: StoolDonut(data: data.stool),
      ),
      const SizedBox(height: AppSpacing.lg),
      _ChartCard(
        title: 'Kusma Sıklığı',
        child: VomitBarChart(data: data.vomiting),
      ),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Akıllı İçgörüler'),
      const SizedBox(height: AppSpacing.sm),
      _InsightList(insights: data.insights),
      const SizedBox(height: AppSpacing.xl),
      const SectionTitle(title: 'Doktor Raporu'),
      const SizedBox(height: AppSpacing.sm),
      const _ReportPreview(),
      const SizedBox(height: AppSpacing.lg),
      PrimaryButton(
        label: 'Doktora Gönder',
        icon: Icons.ios_share_rounded,
        onPressed: _sendReport,
      ),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Analiz', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.md),
                    PillSegmentedControl(
                      segments: AnalyticsPeriod.values
                          .map((p) => p.label)
                          .toList(),
                      selectedIndex: _period.index,
                      onChanged: (i) => setState(
                        () => _period = AnalyticsPeriod.values[i],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    190,
                  ),
                  children: cards
                      .animate(interval: 50.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, end: 0, curve: Curves.easeOut),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A glass card wrapping a titled chart.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _InsightList extends ConsumerWidget {
  const _InsightList({required this.insights});

  final List<AnalyticsInsight> insights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final insight in insights)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GlassCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.soft,
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.auto_awesome_rounded, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(insight.title,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(insight.message,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A stylized, non-functional PDF report preview.
class _ReportPreview extends ConsumerWidget {
  const _ReportPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final profile = ref.watch(babyProfileProvider);
    final theme = Theme.of(context);
    final name = profile?.name ?? 'Bebek';
    final age = profile == null
        ? ''
        : AgeCalculator.describe(profile.birthDate);

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // A "paper" sheet.
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.mdAll,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_rounded, color: colors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Sağlık Özeti',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.black87)),
                    const Spacer(),
                    Text('PDF', style: theme.textTheme.bodySmall),
                  ],
                ),
                const Divider(height: AppSpacing.xl),
                Text('$name · $age',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.black87)),
                const SizedBox(height: AppSpacing.md),
                for (final line in const [
                  'Son 7 gün beslenme ve uyku özeti',
                  'Kaka renk dağılımı ve sıklığı',
                  'Kusma ve ateş kayıtları',
                  'Büyüme ölçümleri (kilo/boy/baş)',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 16, color: colors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(line,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.black54)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Bu önizleme örnektir; gerçek PDF dışa aktarımı sonraki '
            'aşamada eklenecek.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
