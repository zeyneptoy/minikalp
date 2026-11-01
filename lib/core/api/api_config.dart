import 'package:shared_preferences/shared_preferences.dart';

/// Backend connection settings for the MiniKalp API.
///
/// Resolution order for the base URL:
///   1. A value set in-app (Profil → Ayarlar → Sunucu adresi), persisted.
///   2. A build-time --dart-define=API_BASE_URL=...
///   3. A sensible local-development default.
///
/// The in-app option matters for real devices, where `127.0.0.1` points at the
/// phone itself — there you enter your computer's LAN IP (e.g.
/// http://192.168.1.20:8000/api) so the app can reach the Laravel server.
class ApiConfig {
  ApiConfig._();

  static const String _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static const bool _androidEmulator = false;

  static const String _prefKey = 'api_base_url';

  /// Set at runtime from saved preferences or the settings screen.
  static String? runtimeBaseUrl;

  static String get defaultBaseUrl {
    if (_override.isNotEmpty) return _override;
    return _androidEmulator
        ? 'http://10.0.2.2:8000/api'
        : 'http://127.0.0.1:8000/api';
  }

  static String get baseUrl {
    final rt = runtimeBaseUrl;
    if (rt != null && rt.isNotEmpty) return rt;
    return defaultBaseUrl;
  }

  /// Loads any saved base URL (call once at startup before the first request).
  static Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) runtimeBaseUrl = saved;
    } catch (_) {/* keep default */}
  }

  /// Normalizes and saves a base URL entered by the user. Returns the stored
  /// value (with trailing slash trimmed and `/api` ensured).
  static Future<String> save(String raw) async {
    var url = raw.trim();
    if (url.isNotEmpty) {
      if (!url.startsWith('http')) url = 'http://$url';
      url = url.replaceAll(RegExp(r'/+$'), '');
      if (!url.endsWith('/api')) url = '$url/api';
    }
    runtimeBaseUrl = url.isEmpty ? null : url;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url.isEmpty) {
        await prefs.remove(_prefKey);
      } else {
        await prefs.setString(_prefKey, url);
      }
    } catch (_) {/* ignore */}
    return baseUrl;
  }
}
