import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/baby_record.dart';
import '../../../core/providers/records_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/field_label.dart';

/// Stool form: color picker (with per-color info + critical warning),
/// consistency chips, photo, note and time.
class StoolForm extends ConsumerStatefulWidget {
  const StoolForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<StoolForm> createState() => _StoolFormState();
}

class _StoolFormState extends ConsumerState<StoolForm> {
  StoolColor? _color;
  StoolConsistency _consistency = StoolConsistency.normal;
  String? _photoPath;
  final TextEditingController _note = TextEditingController();
  TimeOfDay _time = TimeOfDay.now();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file =
          await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (file != null) setState(() => _photoPath = file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf seçilemedi.')),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final picked = await showCupertinoTimeSheet(context, initial: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    final color = _color;
    if (color == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Lütfen bir renk seçin.')));
      return;
    }
    final now = DateTime.now();
    ref.read(recordsProvider.notifier).add(
          StoolRecord(
            color: color,
            consistency: _consistency,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            photoPath: _photoPath,
            timestamp:
                DateTime(now.year, now.month, now.day, _time.hour, _time.minute),
          ),
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Kaka kaydı eklendi.')));
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final color = _color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Renk'),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final c in StoolColor.values)
              _ColorCircle(
                color: c.swatch,
                selected: _color == c,
                borderColor: colors.primary,
                onTap: () => setState(() => _color = c),
              ),
          ],
        ),
        if (color != null) ...[
          const SizedBox(height: AppSpacing.lg),
          WarningBanner(
            level: WarningLevel.info,
            title: color.label,
            message: color.info,
          ),
        ],
        if (color != null && color.isCritical) ...[
          const SizedBox(height: AppSpacing.md),
          const WarningBanner(
            level: WarningLevel.important,
            title: 'Dikkat',
            message:
                'Bu renk doktor değerlendirmesi gerektirebilir. Lütfen çocuk '
                'doktorunuza danışın.',
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Kıvam'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in StoolConsistency.values)
              SoftChip(
                label: c.label,
                selected: _consistency == c,
                onTap: () => setState(() => _consistency = c),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Fotoğraf (isteğe bağlı)'),
        _PhotoPicker(photoPath: _photoPath, onTap: _pickPhoto),
        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Not'),
        GlassTextField(
          controller: _note,
          hintText: 'Kısa bir not ekleyebilirsin',
          textCapitalization: TextCapitalization.sentences,
          textStyle: theme.textTheme.bodyLarge,
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
                  style: theme.textTheme.titleMedium),
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

/// A single large tappable color circle.
class _ColorCircle extends StatelessWidget {
  const _ColorCircle({
    required this.color,
    required this.selected,
    required this.borderColor,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? borderColor : Colors.white.withValues(alpha: 0.7),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
            : null,
      ),
    );
  }
}

/// Photo attachment control showing a thumbnail or an "add" prompt.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.photoPath, required this.onTap});

  final String? photoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (hasPhoto)
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: Image.file(
                File(photoPath!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_rounded, size: 40),
              ),
            )
          else
            const Icon(Icons.add_a_photo_rounded, size: 32),
          const SizedBox(width: AppSpacing.lg),
          Text(
            hasPhoto ? 'Fotoğrafı değiştir' : 'Fotoğraf ekle',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
