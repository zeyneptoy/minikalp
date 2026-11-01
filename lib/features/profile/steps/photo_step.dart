import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/profile_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';
import '../widgets/step_layout.dart';

/// Step 4 — optional baby photo. Shows a large avatar (gender-based default
/// when empty) and a "Fotoğraf ekle" action that opens a glass bottom sheet
/// to pick the camera or gallery. Skipping is handled by the parent flow.
class PhotoStep extends ConsumerWidget {
  const PhotoStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(profileDraftProvider);
    final hasPhoto = draft.photoPath != null && draft.photoPath!.isNotEmpty;

    return StepLayout(
      title: 'Bir fotoğraf ekleyelim mi?',
      subtitle: 'İstersen şimdi ekle, dilersen daha sonra da ekleyebilirsin.',
      child: Column(
        children: [
          Center(
            child: BabyAvatar(
              photoPath: draft.photoPath,
              radius: 72,
              onTap: () => _showPhotoSheet(context, ref),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: hasPhoto ? 'Fotoğrafı değiştir' : 'Fotoğraf ekle',
            icon: Icons.add_a_photo_rounded,
            onPressed: () => _showPhotoSheet(context, ref),
          ),
          if (hasPhoto) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () =>
                  ref.read(profileDraftProvider.notifier).clearPhoto(),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Fotoğrafı kaldır'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPhotoSheet(BuildContext context, WidgetRef ref) async {
    await GlassBottomSheet.show(
      context,
      title: 'Fotoğraf kaynağı',
      child: Column(
        children: [
          _SourceTile(
            icon: Icons.photo_camera_rounded,
            label: 'Kamera',
            onTap: () => _pick(context, ref, ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.md),
          _SourceTile(
            icon: Icons.photo_library_rounded,
            label: 'Galeri',
            onTap: () => _pick(context, ref, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 800);
      if (file != null) {
        ref.read(profileDraftProvider.notifier).setPhoto(file.path);
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fotoğraf seçilemedi.')),
      );
    } finally {
      // Close the bottom sheet.
      if (navigator.canPop()) navigator.pop();
    }
  }
}

/// A row tile used inside the photo-source bottom sheet.
class _SourceTile extends ConsumerWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.cardAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.soft.withValues(alpha: 0.6),
            borderRadius: AppRadius.cardAll,
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.lg),
              Text(label, style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
