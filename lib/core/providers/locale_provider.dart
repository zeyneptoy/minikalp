import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_providers.dart';

/// A selectable app language.
class AppLanguageOption {
  const AppLanguageOption(this.code, this.nativeName, this.flag);

  final String code;
  final String nativeName;
  final String flag;

  Locale get locale => Locale(code);
}

/// The languages offered on the first-run language screen.
const List<AppLanguageOption> kSupportedLanguages = [
  AppLanguageOption('tr', 'Türkçe', '🇹🇷'),
  AppLanguageOption('en', 'English', '🇬🇧'),
  AppLanguageOption('de', 'Deutsch', '🇩🇪'),
  AppLanguageOption('ar', 'العربية', '🇸🇦'),
  AppLanguageOption('fr', 'Français', '🇫🇷'),
  AppLanguageOption('it', 'Italiano', '🇮🇹'),
  AppLanguageOption('es', 'Español', '🇪🇸'),
  AppLanguageOption('ru', 'Русский', '🇷🇺'),
];

const String kLocalePrefKey = 'app_locale';

/// Whether the user has already chosen a language (drives first-run routing).
Future<bool> hasChosenLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(kLocalePrefKey);
  return code != null && code.isNotEmpty;
}

/// Holds the active [Locale], persisted locally and mirrored to the backend
/// (`/settings` → language). Null until the user picks one.
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._ref) : super(null) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(kLocalePrefKey);
    if (code != null && code.isNotEmpty) {
      state = Locale(code);
    }
  }

  /// Sets the app language, persists it and syncs it to the backend.
  Future<void> setLanguage(String code) async {
    state = Locale(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLocalePrefKey, code);

    // Best-effort backend sync (also silently creates the device account).
    try {
      await _ref.read(apiClientProvider).updateSettings({'language': code});
    } catch (_) {/* offline: kept locally */}
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) => LocaleNotifier(ref));
