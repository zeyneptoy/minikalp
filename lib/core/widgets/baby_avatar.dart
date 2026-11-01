import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';

/// A circular baby avatar with a gender-colored ring.
///
/// Shows the photo at [photoPath] when available; otherwise a soft fallback
/// icon. An optional [onTap] (e.g. to pick a new photo) shows a small edit
/// badge.
class BabyAvatar extends ConsumerWidget {
  const BabyAvatar({
    super.key,
    this.photoPath,
    this.radius = 36,
    this.onTap,
  });

  /// Local file path of the baby's photo (from image_picker). May be null.
  final String? photoPath;

  /// Avatar radius.
  final double radius;

  /// Optional tap handler; when set, an edit badge is shown.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    final avatar = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: hasPhoto
            ? Image.file(
                File(photoPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(colors.soft),
              )
            : _fallback(colors.soft),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (onTap != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(Color bg) {
    return Container(
      color: bg,
      child: Icon(
        Icons.child_care_rounded,
        size: radius,
        color: Colors.white,
      ),
    );
  }
}
