import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_provider.dart';
import 'glass_card.dart';

/// A large, rounded, glassmorphism text field.
///
/// Wraps a [TextField] inside a [GlassCard] so inputs match the app's frosted
/// look. Big by default for comfortable one-handed typing.
class GlassTextField extends ConsumerWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.words,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.textStyle,
  });

  /// Optional external controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String? hintText;

  /// Optional leading icon.
  final IconData? prefixIcon;

  /// Text alignment within the field.
  final TextAlign textAlign;

  /// Capitalization behavior (words by default, good for names).
  final TextCapitalization textCapitalization;

  /// Change callback.
  final ValueChanged<String>? onChanged;

  /// Submit callback.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field grabs focus on mount.
  final bool autofocus;

  /// Optional text style override (defaults to a large title style).
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(appColorsProvider);
    final theme = Theme.of(context);
    final effectiveStyle = textStyle ??
        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      radius: AppRadius.cardLarge,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        textAlign: textAlign,
        textCapitalization: textCapitalization,
        cursorColor: colors.primary,
        style: effectiveStyle,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: effectiveStyle?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
          ),
          icon: prefixIcon != null
              ? Icon(prefixIcon, color: colors.primary)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
          ),
        ),
      ),
    );
  }
}
