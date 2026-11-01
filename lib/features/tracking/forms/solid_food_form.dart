import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';

/// "Ek gıda" form: new food name, date and the baby's reaction. Only shown for
/// babies aged 6+ months (the caller gates visibility).
class SolidFoodForm extends ConsumerStatefulWidget {
  const SolidFoodForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<SolidFoodForm> createState() => _SolidFoodFormState();
}

class _SolidFoodFormState extends ConsumerState<SolidFoodForm> {
  final TextEditingController _food = TextEditingController();
  SolidReaction _reaction = SolidReaction.none;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _food.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showCupertinoDateSheet(
      context,
      initial: _date,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final name = _food.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Lütfen bir besin adı girin.')),
        );
      return;
    }
    ref.read(recordsProvider.notifier).add(
          SolidFoodRecord(
            foodName: name,
            reaction: _reaction,
            timestamp: _date,
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Ek gıda kaydedildi · $name')));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Yeni besin'),
        GlassTextField(
          controller: _food,
          hintText: 'Örn. Havuç püresi',
          prefixIcon: Icons.restaurant_rounded,
          textStyle: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Tarih'),
        GlassCard(
          onTap: _pickDate,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              const Icon(Icons.event_rounded),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${_date.day}.${_date.month}.${_date.year}',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Tepki'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final reaction in SolidReaction.values)
              SoftChip(
                label: reaction.label,
                selected: _reaction == reaction,
                onTap: () => setState(() => _reaction = reaction),
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
