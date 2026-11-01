import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_radius.dart';

/// Builds Material 3 [ThemeData] for the app from a gender [AppThemeColors]
/// palette. Both light (default) and dark variants are provided.
class AppTheme {
  AppTheme._();

  /// Base text theme using Nunito for a soft, friendly, readable feel.
  static TextTheme _textTheme(Color strong, Color muted) {
    final base = GoogleFonts.nunitoTextTheme();
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: strong,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: strong,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: strong,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: strong,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: strong,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, color: strong),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, color: strong),
      bodySmall: base.bodySmall?.copyWith(fontSize: 14, color: muted),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: strong,
      ),
    );
  }

  /// Light theme (the app default).
  static ThemeData light(AppThemeColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.light,
      primary: colors.primary,
      secondary: colors.accent,
      surface: AppNeutrals.surface,
    );
    return _build(
      scheme: scheme,
      scaffold: colors.backgroundGradientStart,
      textStrong: AppNeutrals.textStrong,
      textMuted: AppNeutrals.textMuted,
    );
  }

  /// Dark theme (optional, for night feedings).
  static ThemeData dark(AppThemeColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.dark,
      primary: colors.primary,
      secondary: colors.accent,
      surface: AppNeutrals.darkSurface,
    );
    return _build(
      scheme: scheme,
      scaffold: AppNeutrals.darkScaffold,
      textStrong: AppNeutrals.darkTextStrong,
      textMuted: AppNeutrals.darkTextMuted,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffold,
    required Color textStrong,
    required Color textMuted,
  }) {
    final textTheme = _textTheme(textStrong, textMuted);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      // The app draws its own glass app bars, so keep the default transparent.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        foregroundColor: textStrong,
      ),
      iconTheme: IconThemeData(color: textStrong),
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.4),
      splashFactory: InkRipple.splashFactory,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.buttonAll,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.primary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }
}
