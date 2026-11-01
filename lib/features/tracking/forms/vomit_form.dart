import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';

/// Vomiting form: type, amount, color, time since feeding and accompanying
/// symptoms. Risky combinations show a calm, supportive warning card.
class VomitForm extends ConsumerStatefulWidget {
  const VomitForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<VomitForm> createState() => _VomitFormState();
}

class _VomitFormState extends ConsumerState<VomitForm> {
  VomitKind _kind = VomitKind.spitUp;
  VomitAmount _amount = VomitAmount.low;
  String _colorNote = _colorOptions.first;
  String _sinceFeeding = _sinceOptions.first;
  final Set<VomitSymptom> _symptoms = {};

  static const List<String> _colorOptions = [
    'Süt rengi',
    'Sarı',
    'Yeşil',
    'Kanlı',
  ];
  static const List<String> _sinceOptions = [
    '30 dk içinde',
    '30-60 dk',
    '1-2 saat',
    '2+ saat',
  ];

  /// Whether the current selection warrants a gentle warning.
  bool get _risky =>
      _kind == VomitKind.forceful ||
      _amount == VomitAmount.high ||
      _symptoms.contains(VomitSymptom.fever) ||
      _colorNote == 'Yeşil' ||
      _colorNote == 'Kanlı';

  void _save() {
    ref.read(recordsProvider.notifier).add(
          VomitRecord(
            kind: _kind,
            amount: _amount,
            symptoms: Set.of(_symptoms),
            colorNote: _colorNote,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Kusma kaydı eklendi.')));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Tür'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final kind in VomitKind.values)
              SoftChip(
                label: kind.label,
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Miktar'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final amount in VomitAmount.values)
              SoftChip(
                label: amount.label,
                selected: _amount == amount,
                onTap: () => setState(() => _amount = amount),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Renk'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in _colorOptions)
              SoftChip(
                label: c,
                selected: _colorNote == c,
                onTap: () => setState(() => _colorNote = c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Beslenmeden ne kadar sonra?'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in _sinceOptions)
              SoftChip(
                label: s,
                selected: _sinceFeeding == s,
                onTap: () => setState(() => _sinceFeeding = s),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Eşlik eden belirtiler'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final symptom in VomitSymptom.values)
              SoftChip(
                label: symptom.label,
                selected: _symptoms.contains(symptom),
                onTap: () => setState(() {
                  if (_symptoms.contains(symptom)) {
                    _symptoms.remove(symptom);
                  } else {
                    _symptoms.add(symptom);
                  }
                }),
              ),
          ],
        ),
        if (_risky) ...[
          const SizedBox(height: AppSpacing.lg),
          const WarningBanner(
            level: WarningLevel.important,
            title: 'Dikkatli olalım',
            message:
                'Seçtiğin belirtiler yakından izlenmeli. Durum sürerse veya '
                'kötüleşirse lütfen doktorunuza danışın.',
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
