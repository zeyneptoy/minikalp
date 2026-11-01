import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';

/// Logs a medicine / vitamin dose. Quick suggestion chips make common entries
/// one tap away.
class MedicineForm extends ConsumerStatefulWidget {
  const MedicineForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<MedicineForm> createState() => _MedicineFormState();
}

class _MedicineFormState extends ConsumerState<MedicineForm> {
  final TextEditingController _name = TextEditingController();

  static const List<String> _suggestions = [
    'D Vitamini',
    'Demir',
    'Ateş düşürücü',
    'Probiyotik',
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Lütfen bir isim girin.')),
        );
      return;
    }
    ref.read(recordsProvider.notifier).add(MedicineRecord(name: name));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$name kaydedildi.')));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('İlaç / Vitamin'),
        GlassTextField(
          controller: _name,
          hintText: 'Örn. D Vitamini',
          prefixIcon: Icons.medication_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final s in _suggestions)
              SoftChip(
                label: s,
                onTap: () => setState(() => _name.text = s),
              ),
          ],
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
