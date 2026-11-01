import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';
import '../widgets/value_stepper.dart';

/// Fever / temperature entry with measurement method and a supportive warning
/// when the temperature is high.
class FeverForm extends ConsumerStatefulWidget {
  const FeverForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<FeverForm> createState() => _FeverFormState();
}

class _FeverFormState extends ConsumerState<FeverForm> {
  double _temp = 36.8;
  FeverMethod _method = FeverMethod.armpit;

  bool get _high => _temp >= 38.0;

  void _save() {
    ref.read(recordsProvider.notifier).add(
          FeverRecord(
            temperature: double.parse(_temp.toStringAsFixed(1)),
            method: _method,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Ateş kaydedildi · ${_temp.toStringAsFixed(1)}°C')),
      );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Ateş (°C)'),
        const SizedBox(height: AppSpacing.sm),
        ValueStepper(
          value: _temp,
          step: 0.1,
          min: 35,
          max: 42,
          valueLabel: '${_temp.toStringAsFixed(1)}°C',
          onChanged: (v) => setState(() => _temp = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Ölçüm yöntemi'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final method in FeverMethod.values)
              SoftChip(
                label: method.label,
                selected: _method == method,
                onTap: () => setState(() => _method = method),
              ),
          ],
        ),
        if (_high) ...[
          const SizedBox(height: AppSpacing.lg),
          const WarningBanner(
            level: WarningLevel.important,
            title: 'Ateş yüksek görünüyor',
            message:
                'Ateş 38°C ve üzerinde. Sıvı alımına dikkat edin ve lütfen '
                'doktorunuza danışın.',
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Kaydet',
          icon: Icons.check_rounded,
          onPressed: _save,
        ),
      ],
    );
  }
}
