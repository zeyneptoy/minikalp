import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications for the app's reminders.
///
/// Used to schedule a daily medicine/vitamin reminder and one-off appointment
/// and vaccine reminders. All methods degrade gracefully (swallow errors) so a
/// platform without notification support never breaks the flow.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  // ID namespaces so backend ids of different kinds never collide.
  static int medicineId(int id) => id;
  static int appointmentId(int id) => 1000000 + id;
  static int vaccineId(int id) => 2000000 + id;

  static Future<void> init() async {
    if (_inited) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC if the local zone can't be resolved.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _inited = true;
  }

  /// Asks the user for notification permission. Returns true if granted.
  static Future<bool> requestPermission() async {
    await init();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }

    return true;
  }

  static NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'minikalp_reminders',
          'Hatırlatıcılar',
          channelDescription: 'İlaç, aşı ve randevu hatırlatıcıları',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Schedules a notification that repeats every day at [hour]:[minute].
  static Future<void> scheduleDaily(
    int id,
    int hour,
    int minute,
    String title,
    String body,
  ) async {
    await init();
    try {
      final now = tz.TZDateTime.now(tz.local);
      var when =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!when.isAfter(now)) {
        when = when.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {/* ignore scheduling errors */}
  }

  /// Schedules a one-off notification at [dateTime] (ignored if in the past).
  static Future<void> scheduleOnce(
    int id,
    DateTime dateTime,
    String title,
    String body,
  ) async {
    await init();
    try {
      final when = tz.TZDateTime.from(dateTime, tz.local);
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {/* ignore */}
  }

  static Future<void> cancel(int id) async {
    await init();
    try {
      await _plugin.cancel(id);
    } catch (_) {/* ignore */}
  }
}
