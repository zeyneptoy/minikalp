import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';

/// Volume unit for feeding amounts.
enum VolumeUnit { ml, oz }

extension VolumeUnitLabel on VolumeUnit {
  String get label => this == VolumeUnit.ml ? 'Mililitre (ml)' : 'Ons (oz)';
  String get short => this == VolumeUnit.ml ? 'ml' : 'oz';
}

/// Weight unit for growth entries.
enum WeightUnit { kg, lb }

extension WeightUnitLabel on WeightUnit {
  String get label => this == WeightUnit.kg ? 'Kilogram (kg)' : 'Pound (lb)';
  String get short => this == WeightUnit.kg ? 'kg' : 'lb';
}

/// Display language (prototype — only Turkish is fully implemented).
enum AppLanguage { tr, en }

extension AppLanguageLabel on AppLanguage {
  String get label => this == AppLanguage.tr ? 'Türkçe' : 'İngilizce';
}

/// Immutable app settings bundle (excluding theme mode, which has its own
/// provider from Round 1).
class AppSettings {
  const AppSettings({
    this.notifications = true,
    this.volumeUnit = VolumeUnit.ml,
    this.weightUnit = WeightUnit.kg,
    this.language = AppLanguage.tr,
  });

  final bool notifications;
  final VolumeUnit volumeUnit;
  final WeightUnit weightUnit;
  final AppLanguage language;

  AppSettings copyWith({
    bool? notifications,
    VolumeUnit? volumeUnit,
    WeightUnit? weightUnit,
    AppLanguage? language,
  }) =>
      AppSettings(
        notifications: notifications ?? this.notifications,
        volumeUnit: volumeUnit ?? this.volumeUnit,
        weightUnit: weightUnit ?? this.weightUnit,
        language: language ?? this.language,
      );
}

/// Loads and persists [AppSettings] locally (shared_preferences) and mirrors
/// every change to the backend `/settings` endpoint.
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._ref) : super(const AppSettings()) {
    _load();
  }

  final Ref _ref;
  ApiClient get _api => _ref.read(apiClientProvider);

  static const _kNotif = 'set_notifications';
  static const _kVolume = 'set_volume_unit';
  static const _kWeight = 'set_weight_unit';
  static const _kLang = 'set_language';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      notifications: prefs.getBool(_kNotif) ?? true,
      volumeUnit:
          prefs.getString(_kVolume) == 'oz' ? VolumeUnit.oz : VolumeUnit.ml,
      weightUnit:
          prefs.getString(_kWeight) == 'lb' ? WeightUnit.lb : WeightUnit.kg,
      language: prefs.getString(_kLang) == 'en' ? AppLanguage.en : AppLanguage.tr,
    );
    _hydrateRemote();
  }

  /// Pulls the authoritative settings from the backend once authenticated.
  Future<void> _hydrateRemote() async {
    try {
      final data = await _api.getSettings();
      state = AppSettings(
        notifications: data['notifications'] as bool? ?? state.notifications,
        volumeUnit:
            data['volume_unit'] == 'oz' ? VolumeUnit.oz : VolumeUnit.ml,
        weightUnit:
            data['weight_unit'] == 'lb' ? WeightUnit.lb : WeightUnit.kg,
        language: data['language'] == 'en' ? AppLanguage.en : AppLanguage.tr,
      );
      await _persistLocal();
    } catch (_) {/* keep local */}
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotif, state.notifications);
    await prefs.setString(_kVolume, state.volumeUnit.name);
    await prefs.setString(_kWeight, state.weightUnit.name);
    await prefs.setString(_kLang, state.language.name);
  }

  void _pushRemote(Map<String, dynamic> body) {
    _api.updateSettings(body).catchError((_) => <String, dynamic>{});
  }

  Future<void> setNotifications(bool value) async {
    state = state.copyWith(notifications: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotif, value);
    _pushRemote({'notifications': value});
  }

  Future<void> setVolumeUnit(VolumeUnit unit) async {
    state = state.copyWith(volumeUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVolume, unit.name);
    _pushRemote({'volume_unit': unit.name});
  }

  Future<void> setWeightUnit(WeightUnit unit) async {
    state = state.copyWith(weightUnit: unit);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWeight, unit.name);
    _pushRemote({'weight_unit': unit.name});
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = state.copyWith(language: lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, lang.name);
    _pushRemote({'language': lang.name});
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref),
);
