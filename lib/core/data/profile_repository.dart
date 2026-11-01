import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_profile.dart';

/// Local persistence for the single baby profile, backed by
/// shared_preferences. This is the only storage used in the prototype — there
/// is no backend.
class ProfileRepository {
  ProfileRepository._();

  static const String _key = 'baby_profile';

  /// Loads the saved profile, or null if none has been created yet.
  static Future<BabyProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return BabyProfile.fromJson(map);
    } catch (_) {
      // Corrupted entry — treat as "no profile" so onboarding can run again.
      return null;
    }
  }

  /// Persists [profile], overwriting any existing one.
  static Future<void> save(BabyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toJson()));
  }

  /// Removes the saved profile (used by a future "reset" action).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Whether a profile already exists (drives the splash redirect).
  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    return raw != null && raw.isNotEmpty;
  }

  // --- Multi-baby persistence (Round 5) ---

  static const String _babiesKey = 'babies';
  static const String _activeKey = 'active_baby_index';

  /// Loads all saved babies (empty if none).
  static Future<List<BabyProfile>> loadBabies() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_babiesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BabyProfile.fromJson(e as Map<String, dynamic>))
          .whereType<BabyProfile>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the full list of babies.
  static Future<void> saveBabies(List<BabyProfile> babies) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(babies.map((b) => b.toJson()).toList());
    await prefs.setString(_babiesKey, encoded);
  }

  /// Loads the active baby index (defaults to 0).
  static Future<int> loadActiveIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeKey) ?? 0;
  }

  /// Persists the active baby index.
  static Future<void> saveActiveIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeKey, index);
  }
}
