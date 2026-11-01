import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Thrown when the backend returns a non-2xx response.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, [this.errors]);

  final int statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// A thin, dependency-light client for the MiniKalp Laravel API.
///
/// Authentication uses the backend's bearer-token scheme. Because the app has
/// no login screen, a per-device account is created silently on first use and
/// its credentials + token are persisted locally, so every subsequent launch
/// reuses the same backend user.
class ApiClient {
  ApiClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  static const _kToken = 'api_token';
  static const _kEmail = 'api_device_email';
  static const _kPassword = 'api_device_password';

  String? _token;
  Future<void>? _authInFlight;

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Ensures a valid token exists, creating a device account on first run.
  /// Safe to call repeatedly and concurrently.
  Future<void> ensureAuthenticated() {
    return _authInFlight ??= _authenticate().whenComplete(() {
      _authInFlight = null;
    });
  }

  Future<void> _authenticate() async {
    final prefs = await SharedPreferences.getInstance();

    _token ??= prefs.getString(_kToken);
    if (_token != null) return;

    // Reuse stored device credentials, or mint new ones.
    var email = prefs.getString(_kEmail);
    var password = prefs.getString(_kPassword);
    final isNew = email == null || password == null;

    if (isNew) {
      final suffix = '${DateTime.now().microsecondsSinceEpoch}'
          '${Random().nextInt(1 << 32)}';
      email = 'device-$suffix@miniknot.local';
      password = _randomPassword();
      await prefs.setString(_kEmail, email);
      await prefs.setString(_kPassword, password);
    }

    try {
      if (isNew) {
        await _registerDevice(email, password, prefs);
      } else {
        await _loginDevice(email, password, prefs);
      }
    } on ApiException {
      // Fallback: if register failed because the account exists, log in; if
      // login failed, try registering a fresh account.
      if (isNew) {
        await _loginDevice(email, password, prefs);
      } else {
        await _registerDevice(email, password, prefs);
      }
    }
  }

  Future<void> _registerDevice(
    String email,
    String password,
    SharedPreferences prefs,
  ) async {
    final res = await _send('POST', '/register', body: {
      'name': 'MiniKalp',
      'email': email,
      'password': password,
      'device_name': 'mobile',
    }, auth: false);
    await _storeToken(res['token'] as String, prefs);
  }

  Future<void> _loginDevice(
    String email,
    String password,
    SharedPreferences prefs,
  ) async {
    final res = await _send('POST', '/login', body: {
      'email': email,
      'password': password,
      'device_name': 'mobile',
    }, auth: false);
    await _storeToken(res['token'] as String, prefs);
  }

  Future<void> _storeToken(String token, SharedPreferences prefs) async {
    _token = token;
    await prefs.setString(_kToken, token);
  }

  String _randomPassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<Map<String, dynamic>> currentUser() async => _get('/user');

  Future<void> logout() async {
    try {
      await _send('POST', '/logout');
    } catch (_) {
      // Ignore network errors on logout.
    }
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
  }

  // ---------------------------------------------------------------------------
  // App config & articles (public)
  // ---------------------------------------------------------------------------

  /// Public: the splash screen reads this before authenticating to decide
  /// whether a forced update is required.
  Future<Map<String, dynamic>> appConfig() async =>
      (await _send('GET', '/app/config', auth: false))['data'];

  /// The age-appropriate article for the baby's current month.
  Future<Map<String, dynamic>?> articleForBaby(int babyId) async =>
      (await _get('/babies/$babyId/article'))['data'];

  /// Public: informational articles for the home "Bilgilendirmeler" section.
  Future<List<dynamic>> infoArticles() async =>
      (await _send('GET', '/info-articles', auth: false))['data'];

  // ---------------------------------------------------------------------------
  // Mother's monthly diary
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listDiary(int babyId, {int? month}) async {
    final q = <String, String>{};
    if (month != null) q['month'] = '$month';
    return (await _get('/babies/$babyId/diary', query: q))['data'];
  }

  Future<Map<String, dynamic>> createDiary(
    int babyId,
    String body, {
    int? month,
  }) async =>
      (await _send('POST', '/babies/$babyId/diary', body: {
        'body': body,
        if (month != null) 'month': month,
      }))['data'];

  Future<Map<String, dynamic>> updateDiary(
          int babyId, int entryId, String body) async =>
      (await _send('PUT', '/babies/$babyId/diary/$entryId',
          body: {'body': body}))['data'];

  Future<void> deleteDiary(int babyId, int entryId) =>
      _send('DELETE', '/babies/$babyId/diary/$entryId');

  // ---------------------------------------------------------------------------
  // Babies
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listBabies() async => (await _get('/babies'))['data'];

  Future<Map<String, dynamic>> createBaby(Map<String, dynamic> body) async =>
      (await _send('POST', '/babies', body: body))['data'];

  Future<Map<String, dynamic>> updateBaby(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('PUT', '/babies/$babyId', body: body))['data'];

  Future<void> deleteBaby(int babyId) => _send('DELETE', '/babies/$babyId');

  // ---------------------------------------------------------------------------
  // Records
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listRecords(
    int babyId, {
    String? type,
    String? date,
    String? from,
    String? to,
  }) async {
    final q = <String, String>{};
    if (type != null) q['type'] = type;
    if (date != null) q['date'] = date;
    if (from != null) q['from'] = from;
    if (to != null) q['to'] = to;
    return (await _get('/babies/$babyId/records', query: q))['data'];
  }

  Future<Map<String, dynamic>> createRecord(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/records', body: body))['data'];

  Future<void> deleteRecord(int babyId, int recordId) =>
      _send('DELETE', '/babies/$babyId/records/$recordId');

  // ---------------------------------------------------------------------------
  // Dashboard / summary
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> dashboard(int babyId) async =>
      (await _get('/babies/$babyId/dashboard'))['data'];

  Future<Map<String, dynamic>> summary(int babyId, {String? date}) async =>
      (await _get('/babies/$babyId/summary',
          query: date != null ? {'date': date} : null))['data'];

  // ---------------------------------------------------------------------------
  // Growth
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listGrowth(int babyId) async =>
      (await _get('/babies/$babyId/growth'))['data'];

  Future<Map<String, dynamic>?> latestGrowth(int babyId) async =>
      (await _get('/babies/$babyId/growth/latest'))['data'];

  Future<Map<String, dynamic>> createGrowth(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/growth', body: body))['data'];

  // ---------------------------------------------------------------------------
  // Milestones & teeth (sets)
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> getMilestones(int babyId) async =>
      (await _get('/babies/$babyId/milestones'))['data'];

  Future<List<dynamic>> toggleMilestone(int babyId, String key) async =>
      (await _send('POST', '/babies/$babyId/milestones/toggle',
          body: {'key': key}))['data'];

  Future<List<dynamic>> getTeeth(int babyId) async =>
      (await _get('/babies/$babyId/teeth'))['data'];

  Future<List<dynamic>> toggleTooth(int babyId, int index) async =>
      (await _send('POST', '/babies/$babyId/teeth/toggle',
          body: {'index': index}))['data'];

  // ---------------------------------------------------------------------------
  // Memories & photos
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listMemories(int babyId) async =>
      (await _get('/babies/$babyId/memories'))['data'];

  Future<Map<String, dynamic>> createMemory(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/memories', body: body))['data'];

  Future<Map<String, dynamic>> updateMemory(
          int babyId, int memoryId, Map<String, dynamic> body) async =>
      (await _send('PUT', '/babies/$babyId/memories/$memoryId', body: body))['data'];

  Future<void> deleteMemory(int babyId, int memoryId) =>
      _send('DELETE', '/babies/$babyId/memories/$memoryId');

  Future<List<dynamic>> listPhotos(int babyId, {int? month}) async =>
      (await _get('/babies/$babyId/photos',
          query: month != null ? {'month': '$month'} : null))['data'];

  Future<Map<String, dynamic>> createPhoto(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/photos', body: body))['data'];

  Future<void> deletePhoto(int babyId, int photoId) =>
      _send('DELETE', '/babies/$babyId/photos/$photoId');

  // ---------------------------------------------------------------------------
  // Expressed milk
  // ---------------------------------------------------------------------------

  Future<int> getExpressedMilk(int babyId) async {
    final data = (await _get('/babies/$babyId/expressed-milk'))['data'];
    return (data['stock_ml'] as num).toInt();
  }

  Future<int> setExpressedMilk(int babyId, {int? stockMl, int? delta}) async {
    final body = <String, dynamic>{};
    if (stockMl != null) body['stock_ml'] = stockMl;
    if (delta != null) body['delta'] = delta;
    final data =
        (await _send('PUT', '/babies/$babyId/expressed-milk', body: body))['data'];
    return (data['stock_ml'] as num).toInt();
  }

  // ---------------------------------------------------------------------------
  // Health: medicine reminders, vaccines, appointments
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listReminders(int babyId) async =>
      (await _get('/babies/$babyId/medicine-reminders'))['data'];

  Future<Map<String, dynamic>> createReminder(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/medicine-reminders', body: body))['data'];

  Future<Map<String, dynamic>> toggleReminder(int babyId, int reminderId) async =>
      (await _send('POST',
          '/babies/$babyId/medicine-reminders/$reminderId/toggle'))['data'];

  Future<void> deleteReminder(int babyId, int reminderId) =>
      _send('DELETE', '/babies/$babyId/medicine-reminders/$reminderId');

  Future<List<dynamic>> listVaccines(int babyId) async =>
      (await _get('/babies/$babyId/vaccines'))['data'];

  Future<Map<String, dynamic>> createVaccine(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/vaccines', body: body))['data'];

  Future<Map<String, dynamic>> updateVaccine(
          int babyId, int vaccineId, Map<String, dynamic> body) async =>
      (await _send('PUT', '/babies/$babyId/vaccines/$vaccineId', body: body))['data'];

  Future<void> deleteVaccine(int babyId, int vaccineId) =>
      _send('DELETE', '/babies/$babyId/vaccines/$vaccineId');

  Future<List<dynamic>> listAppointments(int babyId) async =>
      (await _get('/babies/$babyId/appointments'))['data'];

  Future<Map<String, dynamic>> createAppointment(
          int babyId, Map<String, dynamic> body) async =>
      (await _send('POST', '/babies/$babyId/appointments', body: body))['data'];

  Future<Map<String, dynamic>> updateAppointment(
          int babyId, int appointmentId, Map<String, dynamic> body) async =>
      (await _send('PUT', '/babies/$babyId/appointments/$appointmentId',
          body: body))['data'];

  Future<void> deleteAppointment(int babyId, int appointmentId) =>
      _send('DELETE', '/babies/$babyId/appointments/$appointmentId');

  /// Emails a health report for the baby to [email].
  Future<String> sendReport(int babyId, String email) async {
    final res = await _send('POST', '/babies/$babyId/send-report',
        body: {'email': email});
    return res['message'] as String? ?? 'Rapor gönderildi.';
  }

  // ---------------------------------------------------------------------------
  // Mood (per user)
  // ---------------------------------------------------------------------------

  Future<List<dynamic>> listMood() async => (await _get('/mood'))['data'];

  Future<Map<String, dynamic>> createMood(Map<String, dynamic> body) async =>
      (await _send('POST', '/mood', body: body))['data'];

  // ---------------------------------------------------------------------------
  // Settings (per user)
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getSettings() async =>
      (await _get('/settings'))['data'];

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body) async =>
      (await _send('PUT', '/settings', body: body))['data'];

  // ---------------------------------------------------------------------------
  // Low-level transport
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> _get(String path,
          {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    if (auth) {
      await ensureAuthenticated();
    }

    var uri = Uri.parse('${ApiConfig.baseUrl}$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (auth && _token != null) 'Authorization': 'Bearer $_token',
    };

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _http.send(request);
    final response = await http.Response.fromStream(streamed);

    // A stale/invalid token: drop it so the next call re-authenticates.
    if (response.statusCode == 401 && auth) {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kToken);
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final map = decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      throw ApiException(
        response.statusCode,
        (map['message'] as String?) ?? 'İstek başarısız (${response.statusCode}).',
        map['errors'] as Map<String, dynamic>?,
      );
    }

    if (decoded is Map<String, dynamic>) return decoded;
    // Some list endpoints could in theory return a bare array; wrap it.
    return {'data': decoded};
  }
}
