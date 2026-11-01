import 'package:flutter/material.dart';

import '../models/baby_profile.dart';

/// A full color palette derived from the baby's gender.
///
/// Every gender-dependent color in the app (buttons, selected icons, chart
/// colors, bottom bar, gradients, blobs, accents) is read from an instance of
/// this class, which is provided dynamically through Riverpod.
@immutable
class AppThemeColors {
  const AppThemeColors({
    required this.gender,
    required this.primary,
    required this.soft,
    required this.accent,
    required this.backgroundGradientStart,
    required this.backgroundGradientEnd,
  });

  /// The gender this palette represents.
  final Gender gender;

  /// Main brand color — primary buttons, active icons, highlights.
  final Color primary;

  /// Soft tint of the primary — chip fills, subtle backgrounds.
  final Color soft;

  /// Secondary accent — gradients, charts, decorative blobs.
  final Color accent;

  /// Top color of the page background gradient.
  final Color backgroundGradientStart;

  /// Bottom color of the page background gradient.
  final Color backgroundGradientEnd;

  /// Ordered palette used to color multi-series charts, built around [primary].
  List<Color> get chartSeries => <Color>[
        primary,
        accent,
        primary.withValues(alpha: 0.55),
        accent.withValues(alpha: 0.55),
      ];

  // ----- Gender palettes -----

  /// Girl -> pink.
  static const AppThemeColors girl = AppThemeColors(
    gender: Gender.girl,
    primary: Color(0xFFF27AA6),
    soft: Color(0xFFFFE3EE),
    accent: Color(0xFFFFB6D0),
    backgroundGradientStart: Color(0xFFFFF5F9),
    backgroundGradientEnd: Color(0xFFFFE9F1),
  );

  /// Boy -> blue.
  static const AppThemeColors boy = AppThemeColors(
    gender: Gender.boy,
    primary: Color(0xFF5AA9F0),
    soft: Color(0xFFE1F0FF),
    accent: Color(0xFFA8D4FA),
    backgroundGradientStart: Color(0xFFF3F9FF),
    backgroundGradientEnd: Color(0xFFE3F1FF),
  );

  /// Unspecified -> orange.
  static const AppThemeColors unspecified = AppThemeColors(
    gender: Gender.unspecified,
    primary: Color(0xFFF59E5B),
    soft: Color(0xFFFFEBD8),
    accent: Color(0xFFFFC896),
    backgroundGradientStart: Color(0xFFFFF8F1),
    backgroundGradientEnd: Color(0xFFFFEBD9),
  );

  /// Returns the palette for a given [gender].
  static AppThemeColors forGender(Gender gender) {
    switch (gender) {
      case Gender.girl:
        return girl;
      case Gender.boy:
        return boy;
      case Gender.unspecified:
        return unspecified;
    }
  }
}

/// Neutral colors shared by every palette (text, surfaces, warning levels).
///
/// These do not depend on gender; they keep the app readable and calm.
class AppNeutrals {
  AppNeutrals._();

  // Light scheme neutrals.
  static const Color textStrong = Color(0xFF2E2A33);
  static const Color textMuted = Color(0xFF7A7484);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color scaffoldFallback = Color(0xFFFFF7FB);

  // Dark scheme neutrals (for night feedings).
  static const Color darkTextStrong = Color(0xFFF2EEF6);
  static const Color darkTextMuted = Color(0xFFB4AEBE);
  static const Color darkSurface = Color(0xFF241F2B);
  static const Color darkScaffold = Color(0xFF161219);
  static const Color darkGradientStart = Color(0xFF1C1722);
  static const Color darkGradientEnd = Color(0xFF130F18);

  // Warning banner levels (soft, mother-friendly tones).
  static const Color infoBg = Color(0xFFE3F0FF);
  static const Color infoFg = Color(0xFF2F6FB3);
  static const Color cautionBg = Color(0xFFFFF4D6);
  static const Color cautionFg = Color(0xFFB8860B);
  static const Color importantBg = Color(0xFFFFE3DB);
  static const Color importantFg = Color(0xFFC2452E);
}
