import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/development_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../core/widgets/widgets.dart';
import '../../tracking/widgets/value_stepper.dart';

/// Growth section: weight / height / head inputs and a themed WHO percentile
/// chart (mock curves) with the baby's current point.
class GrowthSection extends ConsumerWidget {
  const GrowthSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final growth = ref.watch(growthProvider);
    final settings = ref.watch(settingsProvider);

    // Display weight in the chosen unit (stored metric).
    final weightDisplay = settings.weightUnit == WeightUnit.kg
        ? '${growth.weightKg.toStringAsFixed(1)} kg'
        : '${(growth.weightKg * 2.20462).toStringAsFixed(1)} lb';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(title: 'Büyüme Ölçümleri'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _MeasureCard(
                icon: Icons.monitor_weight_rounded,
                label: 'Kilo',
                value: weightDisplay,
                onTap: () => _editValue(
                  context,
                  title: 'Kilo (kg)',
                  value: growth.weightKg,
                  min: 2,
                  max: 15,
                  step: 0.1,
                  suffix: 'kg',
                  onSave: (v) =>
                      ref.read(growthProvider.notifier).setWeight(v),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MeasureCard(
                icon: Icons.straighten_rounded,
                label: 'Boy',
                value: '${growth.heightCm.toStringAsFixed(0)} cm',
                onTap: () => _editValue(
                  context,
                  title: 'Boy (cm)',
                  value: growth.heightCm,
                  min: 40,
                  max: 100,
                  step: 0.5,
                  suffix: 'cm',
                  onSave: (v) =>
                      ref.read(growthProvider.notifier).setHeight(v),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MeasureCard(
                icon: Icons.circle_outlined,
                label: 'Baş',
                value: '${growth.headCm.toStringAsFixed(0)} cm',
                onTap: () => _editValue(
                  context,
                  title: 'Baş çevresi (cm)',
                  value: growth.headCm,
                  min: 30,
                  max: 55,
                  step: 0.5,
                  suffix: 'cm',
                  onSave: (v) => ref.read(growthProvider.notifier).setHead(v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kilo – WHO Persentil Eğrisi',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              const _PercentileChart(),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Eğriler yaklaşık referans değerleridir (örnek).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _GrowthHistory(),
      ],
    );
  }

  Future<void> _editValue(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required double step,
    required String suffix,
    required ValueChanged<double> onSave,
  }) async {
    double current = value;
    await GlassBottomSheet.show<void>(
      context,
      title: title,
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueStepper(
              value: current,
              min: min,
              max: max,
              step: step,
              valueLabel: '${current.toStringAsFixed(step < 1 ? 1 : 0)} '
                  '$suffix',
              onChanged: (v) => setSheetState(() => current = v),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Kaydet',
              icon: Icons.check_rounded,
              onPressed: () {
                onSave(double.parse(current.toStringAsFixed(1)));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasureCard extends ConsumerWidget {
  const _MeasureCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Mock WHO weight-for-age percentile curves (0–12 months) + baby's point.
class _PercentileChart extends ConsumerWidget {
  const _PercentileChart();

  // Approximate reference values (kg) by month for a mock chart.
  static const List<double> _p15 = [
    2.9, 3.9, 4.9, 5.6, 6.2, 6.7, 7.1, 7.4, 7.7, 8.0, 8.2, 8.4, 8.6,
  ];
  static const List<double> _p50 = [
    3.3, 4.5, 5.6, 6.4, 7.0, 7.5, 7.9, 8.3, 8.6, 8.9, 9.2, 9.4, 9.6,
  ];
  static const List<double> _p85 = [
    3.9, 5.1, 6.3, 7.2, 7.8, 8.4, 8.8, 9.2, 9.6, 9.9, 10.2, 10.5, 10.8,
  ];

  LineChartBarData _curve(List<double> values, Color color, {bool dashed = false}) {
    return LineChartBarData(
      spots: [
        for (var m = 0; m < values.length; m++) FlSpot(m.toDouble(), values[m]),
      ],
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dashArray: dashed ? [6, 4] : null,
      dotData: const FlDotData(show: false),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final profile = ref.watch(babyProfileProvider);
    final growth = ref.watch(growthProvider);
    final month = profile == null
        ? 2
        : AgeCalculator.calculate(profile.birthDate).months.clamp(0, 12);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 12,
          minY: 2,
          maxY: 12,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: colors.soft, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 2),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 2,
                reservedSize: 24,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 6,
                  child: Text('${v.toInt()}a',
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
            ),
          ),
          lineBarsData: [
            _curve(_p15, colors.accent, dashed: true),
            _curve(_p50, colors.primary),
            _curve(_p85, colors.accent, dashed: true),
            // Baby's current point.
            LineChartBarData(
              spots: [FlSpot(month.toDouble(), growth.weightKg)],
              color: Colors.transparent,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 6,
                  color: colors.primary,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) => '${d.day}.${d.month}.${d.year}';

/// Month-by-month list of growth measurements + an "add" entry form.
class _GrowthHistory extends ConsumerWidget {
  const _GrowthHistory();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(growthHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: SectionTitle(title: 'Aylık Ölçümler')),
            TextButton.icon(
              onPressed: () => GlassBottomSheet.show<void>(
                context,
                title: 'Ölçüm ekle',
                child: const _GrowthAddForm(),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ekle'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Henüz ölçüm yok. Her ay kilo, boy ve baş çevresini '
                    'buraya ekleyebilirsin.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : Column(
                  children: [
                    for (final m in history)
                      ListTile(
                        leading: const Icon(Icons.straighten_rounded),
                        title: Text(
                          '${(m.weightKg ?? 0).toStringAsFixed(1)} kg · '
                          '${(m.heightCm ?? 0).toStringAsFixed(0)} cm · '
                          '${(m.headCm ?? 0).toStringAsFixed(0)} cm',
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(_fmtDate(m.measuredAt)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _GrowthAddForm extends ConsumerStatefulWidget {
  const _GrowthAddForm();

  @override
  ConsumerState<_GrowthAddForm> createState() => _GrowthAddFormState();
}

class _GrowthAddFormState extends ConsumerState<_GrowthAddForm> {
  late double _weight;
  late double _height;
  late double _head;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final latest = ref.read(growthProvider);
    _weight = latest.weightKg;
    _height = latest.heightCm;
    _head = latest.headCm;
    _date = DateTime.now();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showCupertinoDateSheet(
      context,
      initial: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      title: 'Ölçüm tarihi',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    await ref.read(growthHistoryProvider.notifier).add(
          weightKg: double.parse(_weight.toStringAsFixed(1)),
          heightCm: double.parse(_height.toStringAsFixed(1)),
          headCm: double.parse(_head.toStringAsFixed(1)),
          measuredAt: _date,
        );
    ref.read(growthProvider.notifier).applyLatest(_weight, _height, _head);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          onTap: _pickDate,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.event_rounded),
              const SizedBox(width: AppSpacing.md),
              Text('Tarih', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(_fmtDate(_date),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Kilo: ${_weight.toStringAsFixed(1)} kg',
            style: theme.textTheme.bodyMedium),
        ValueStepper(
          value: _weight,
          min: 2,
          max: 15,
          step: 0.1,
          valueLabel: '${_weight.toStringAsFixed(1)} kg',
          onChanged: (v) => setState(() => _weight = v),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Boy: ${_height.toStringAsFixed(0)} cm',
            style: theme.textTheme.bodyMedium),
        ValueStepper(
          value: _height,
          min: 40,
          max: 100,
          step: 0.5,
          valueLabel: '${_height.toStringAsFixed(0)} cm',
          onChanged: (v) => setState(() => _height = v),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Baş çevresi: ${_head.toStringAsFixed(0)} cm',
            style: theme.textTheme.bodyMedium),
        ValueStepper(
          value: _head,
          min: 30,
          max: 55,
          step: 0.5,
          valueLabel: '${_head.toStringAsFixed(0)} cm',
          onChanged: (v) => setState(() => _head = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(label: 'Kaydet', icon: Icons.check_rounded, onPressed: _save),
      ],
    );
  }
}
