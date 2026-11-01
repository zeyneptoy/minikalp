import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/development_provider.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/widgets.dart';

/// Memory album: "firsts" cards plus a free-form photo grid.
class MemorySection extends ConsumerWidget {
  const MemorySection({super.key});

  Future<String?> _pick() async {
    try {
      final file =
          await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1000);
      return file?.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firsts = ref.watch(firstsProvider);
    final album = ref.watch(albumProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle(title: 'İlklerimiz'),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 136,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            itemCount: firsts.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) => _FirstCard(
              memory: firsts[i],
              onTap: () async {
                final path = await _pick();
                if (path != null) {
                  ref.read(firstsProvider.notifier).setPhoto(i, path);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: Text('Fotoğraf Albümü',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: () async {
                final path = await _pick();
                if (path != null) {
                  ref.read(albumProvider.notifier).add(path);
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ekle'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (album.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: EmptyState(
              icon: Icons.photo_library_rounded,
              title: 'Albüm henüz boş',
              message: 'Bebeğinin özel anlarını buraya ekleyebilirsin.',
              actionLabel: 'Fotoğraf ekle',
              onAction: () async {
                final path = await _pick();
                if (path != null) {
                  ref.read(albumProvider.notifier).add(path);
                }
              },
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: album.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: Image.file(
                File(album[i]),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0x11000000)),
              ),
            ),
          ),
      ],
    );
  }
}

class _FirstCard extends ConsumerWidget {
  const _FirstCard({required this.memory, required this.onTap});

  final FirstMemory memory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final hasPhoto = memory.photoPath != null;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 110,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colors.soft,
                backgroundImage:
                    hasPhoto ? FileImage(File(memory.photoPath!)) : null,
                child: hasPhoto
                    ? null
                    : Icon(Icons.add_a_photo_rounded, color: colors.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                memory.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
