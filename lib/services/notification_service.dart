import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    // Skip on web where this plugin isn't supported
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _fln.initialize(initSettings);

    // Initialize timezone database for zoned scheduling
    tz.initializeTimeZones();

    const androidChannel = AndroidNotificationChannel(
      'pomodoro_alerts',
      'Pomodoro Alerts',
      description: 'Reminders when focus/break sessions end',
      importance: Importance.high,
    );

    await _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<bool> ensurePermission() async {
    if (kIsWeb) return false;
    // Android 13+ requires POST_NOTIFICATIONS; on iOS, alert/badge/sound permissions
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    final res = await Permission.notification.request();
    return res.isGranted;
  }

  Future<void> showImmediate({required String title, required String body}) async {
    if (kIsWeb) return;
    await init();
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_alerts',
      'Pomodoro Alerts',
      channelDescription: 'Reminders when focus/break sessions end',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _fln.show(0, title, body, details);
  }

  Future<void> scheduleIn({required String title, required String body, required Duration inFromNow, int id = 1}) async {
    if (kIsWeb) return;
    await init();
    final scheduled = tz.TZDateTime.now(tz.local).add(inFromNow);
    const androidDetails = AndroidNotificationDetails(
      'pomodoro_alerts',
      'Pomodoro Alerts',
      channelDescription: 'Reminders when focus/break sessions end',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _fln.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await init();
    await _fln.cancel(id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await init();
    await _fln.cancelAll();
  }
}
