import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';
import '../widgets/value_stepper.dart';

/// Bottle feeding form: amount (ml) + milk type + time.
class FormulaForm extends ConsumerStatefulWidget {
  const FormulaForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<FormulaForm> createState() => _FormulaFormState();
}

class _FormulaFormState extends ConsumerState<FormulaForm> {
  double _ml = 90;
  MilkType _milkType = MilkType.formula;
  TimeOfDay _time = TimeOfDay.now();

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Saat seç',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final now = DateTime.now();
    final timestamp =
        DateTime(now.year, now.month, now.day, _time.hour, _time.minute);
    ref.read(recordsProvider.notifier).add(
          FormulaRecord(
            milkType: _milkType,
            ml: _ml.round(),
            timestamp: timestamp,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Mama kaydedildi · ${_ml.round()} ml')),
      );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Miktar'),
        const SizedBox(height: AppSpacing.sm),
        ValueStepper(
          value: _ml,
          step: 10,
          min: 10,
          max: 400,
          valueLabel: '${_ml.round()} ml',
          onChanged: (v) => setState(() => _ml = v),
        ),
        const SizedBox(height: AppSpacing.md),
        Slider(
          value: _ml,
          min: 10,
          max: 400,
          divisions: 39,
          label: '${_ml.round()} ml',
          onChanged: (v) => setState(() => _ml = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Süt türü'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final type in MilkType.values)
              SoftChip(
                label: type.label,
                selected: _milkType == type,
                onTap: () => setState(() => _milkType = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Saat'),
        GlassCard(
          onTap: _pickTime,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded),
              const SizedBox(width: AppSpacing.md),
              Text(_time.format(context),
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
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
