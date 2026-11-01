import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';

/// Simple diaper form (wet / dirty / both), used from the quick-add grid.
class DiaperForm extends ConsumerStatefulWidget {
  const DiaperForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<DiaperForm> createState() => _DiaperFormState();
}

class _DiaperFormState extends ConsumerState<DiaperForm> {
  DiaperKind _kind = DiaperKind.wet;

  void _save() {
    ref.read(recordsProvider.notifier).add(DiaperRecord(kind: _kind));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Bez kaydedildi · ${_kind.label}')),
      );
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Bez içeriği'),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final kind in DiaperKind.values)
              SoftChip(
                label: kind.label,
                selected: _kind == kind,
                onTap: () => setState(() => _kind = kind),
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
