import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';
import '../widgets/pill_segmented_control.dart';
import '../widgets/star_rating.dart';
import '../widgets/value_stepper.dart';

/// Sleep form with two input modes:
///   * Kronometre: a live start/stop timer.
///   * Elle gir:  manual hours + minutes entry (for sleep that already ended).
class SleepForm extends ConsumerStatefulWidget {
  const SleepForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<SleepForm> createState() => _SleepFormState();
}

class _SleepFormState extends ConsumerState<SleepForm> {
  int _mode = 0; // 0 = timer, 1 = manual

  // Timer state.
  Duration _elapsed = Duration.zero;
  bool _running = false;
  Timer? _ticker;

  // Manual state.
  double _hours = 1;
  double _minutes = 30;

  // Shared.
  DayNight _dayNight = DayNight.day;
  int _quality = 4;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleRunning() {
    setState(() {
      _running = !_running;
      if (_running) {
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() => _elapsed += const Duration(seconds: 1));
        });
      } else {
        _ticker?.cancel();
      }
    });
  }

  void _save(Duration duration) {
    if (duration.inSeconds == 0) return;
    ref.read(recordsProvider.notifier).add(
          SleepRecord(
            duration: duration,
            dayNight: _dayNight,
            quality: _quality,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Uyku kaydedildi · ${DurationFormat.hm(duration)}')),
      );
    widget.onSaved?.call();
  }

  void _finishTimer() {
    _ticker?.cancel();
    _save(_elapsed);
    setState(() {
      _elapsed = Duration.zero;
      _running = false;
    });
  }

  void _saveManual() {
    _save(Duration(hours: _hours.round(), minutes: _minutes.round()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todaySleep = ref
        .watch(todayRecordsProvider)
        .whereType<SleepRecord>()
        .fold<Duration>(Duration.zero, (sum, r) => sum + r.duration);
    final total = todaySleep + _elapsed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bugünkü toplam uyku', style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                DurationFormat.stat(total),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PillSegmentedControl(
          segments: const ['Kronometre', 'Elle gir'],
          selectedIndex: _mode,
          onChanged: (i) => setState(() => _mode = i),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_mode == 0) _buildTimer(theme) else _buildManual(theme),
        const SizedBox(height: AppSpacing.xl),
        const FieldLabel('Zaman'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final dn in DayNight.values)
              SoftChip(
                label: dn.label,
                icon: dn == DayNight.day
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round,
                selected: _dayNight == dn,
                onTap: () => setState(() => _dayNight = dn),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Uyku kalitesi'),
        StarRating(
          value: _quality,
          onChanged: (v) => setState(() => _quality = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_mode == 0)
          PrimaryButton(
            label: 'Kaydet',
            icon: Icons.check_rounded,
            onPressed: _elapsed.inSeconds > 0 ? _finishTimer : null,
          )
        else
          PrimaryButton(
            label: 'Kaydet',
            icon: Icons.check_rounded,
            onPressed: (_hours + _minutes) > 0 ? _saveManual : null,
          ),
      ],
    );
  }

  Widget _buildTimer(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'Bu oturum: ${DurationFormat.clock(_elapsed)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(
          label: _running ? 'Uykuyu Bitir' : 'Uykuyu Başlat',
          icon: _running ? Icons.stop_rounded : Icons.play_arrow_rounded,
          onPressed: _toggleRunning,
        ),
      ],
    );
  }

  Widget _buildManual(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Saat'),
        ValueStepper(
          value: _hours,
          min: 0,
          max: 14,
          step: 1,
          valueLabel: '${_hours.round()} saat',
          onChanged: (v) => setState(() => _hours = v),
        ),
        const SizedBox(height: AppSpacing.md),
        const FieldLabel('Dakika'),
        ValueStepper(
          value: _minutes,
          min: 0,
          max: 55,
          step: 5,
          valueLabel: '${_minutes.round()} dk',
          onChanged: (v) => setState(() => _minutes = v),
        ),
      ],
    );
  }
}
