import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_profile.dart';
import 'app_colors.dart';

/// Preference keys for the simple local persistence used in the prototype.
class _PrefKeys {
  static const String gender = 'baby_gender';
  static const String themeMode = 'theme_mode';
}

/// Holds the currently selected baby [Gender], which drives the whole palette.
///
/// The value is persisted with shared_preferences so the chosen theme survives
/// app restarts. Writes are fire-and-forget (the UI updates instantly).
class GenderNotifier extends StateNotifier<Gender> {
  GenderNotifier() : super(Gender.unspecified) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = GenderLabel.fromStorageKey(prefs.getString(_PrefKeys.gender));
  }

  /// Change the gender and persist it.
  Future<void> setGender(Gender gender) async {
    state = gender;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.gender, gender.storageKey);
  }
}

/// Current baby gender.
final genderProvider =
    StateNotifierProvider<GenderNotifier, Gender>((ref) => GenderNotifier());

/// Derived, read-only palette for the current gender.
///
/// Every gender-dependent color in the app should be read from here.
final appColorsProvider = Provider<AppThemeColors>((ref) {
  final gender = ref.watch(genderProvider);
  return AppThemeColors.forGender(gender);
});

/// Holds the current [ThemeMode]. Light is the default; dark can be toggled
/// from settings (handy for night feedings).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_PrefKeys.themeMode);
    state = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  /// Toggle between light and dark, persisting the choice.
  Future<void> toggle() => setDark(state != ThemeMode.dark);

  /// Explicitly set dark (true) or light (false).
  Future<void> setDark(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.themeMode, isDark ? 'dark' : 'light');
  }
}

/// Current theme mode (light by default).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);
