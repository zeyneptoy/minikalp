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
import '../widgets/value_stepper.dart';

/// Breastfeeding form with two input modes:
///   * Kronometre: a live start/pause/stop timer.
///   * Elle gir:  manual minute entry — useful when the mother is holding the
///     baby and cannot start a stopwatch in time.
class BreastfeedingForm extends ConsumerStatefulWidget {
  const BreastfeedingForm({super.key, this.onSaved});

  /// Called after a successful save (used to close a bottom sheet).
  final VoidCallback? onSaved;

  @override
  ConsumerState<BreastfeedingForm> createState() => _BreastfeedingFormState();
}

class _BreastfeedingFormState extends ConsumerState<BreastfeedingForm> {
  BreastSide _side = BreastSide.left;

  // 0 = timer, 1 = manual entry.
  int _mode = 0;

  // Timer state.
  Duration _elapsed = Duration.zero;
  bool _running = false;
  Timer? _ticker;

  // Manual entry state (minutes).
  double _manualMinutes = 15;

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
          BreastfeedingRecord(side: _side, duration: duration),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Emzirme kaydedildi · ${_side.label} meme · '
            '${DurationFormat.hm(duration)}',
          ),
        ),
      );
    widget.onSaved?.call();
  }

  void _finishTimer() {
    _ticker?.cancel();
    final duration = _elapsed;
    _save(duration);
    setState(() {
      _elapsed = Duration.zero;
      _running = false;
    });
  }

  void _saveManual() {
    _save(Duration(minutes: _manualMinutes.round()));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Hangi meme?'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final side in BreastSide.values)
              SoftChip(
                label: side.label,
                selected: _side == side,
                onTap: () => setState(() => _side = side),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        PillSegmentedControl(
          segments: const ['Kronometre', 'Elle gir'],
          selectedIndex: _mode,
          onChanged: (i) => setState(() => _mode = i),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_mode == 0) _buildTimer() else _buildManual(),
      ],
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Center(
          child: CircularTimer(
            progress: (_elapsed.inSeconds % 60) / 60,
            timeLabel: DurationFormat.clock(_elapsed),
            caption: '${_side.label} meme',
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: _running ? 'Duraklat' : 'Başlat',
                icon: _running
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                outlined: true,
                onPressed: _toggleRunning,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                label: 'Bitir',
                icon: Icons.check_rounded,
                onPressed: _elapsed.inSeconds > 0 ? _finishTimer : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManual() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Süre (dakika)'),
        ValueStepper(
          value: _manualMinutes,
          min: 1,
          max: 120,
          step: 1,
          valueLabel: '${_manualMinutes.round()} dk',
          onChanged: (v) => setState(() => _manualMinutes = v),
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Kaydet',
          icon: Icons.check_rounded,
          onPressed: _saveManual,
        ),
      ],
    );
  }
}
