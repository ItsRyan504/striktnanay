import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'notification_prefs.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final NotificationPrefs _prefs = NotificationPrefs();
  static const int _statusId = 50;

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
    const statusChannel = AndroidNotificationChannel(
      'pomodoro_status',
      'Pomodoro Status',
      description: 'Ongoing status while the timer is running',
      importance: Importance.low,
      playSound: false,
      showBadge: false,
    );

    await _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
    await _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(statusChannel);

    _initialized = true;
  }

  Future<void> showOngoingStatus({required String title, required String body}) async {
    if (kIsWeb) return;
    await init();
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_status',
      'Pomodoro Status',
      channelDescription: 'Ongoing status while the timer is running',
      importance: Importance.low,
      priority: Priority.low,
      category: AndroidNotificationCategory.progress,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      playSound: false,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(presentSound: false);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _fln.show(_statusId, title, body, details);
  }

  Future<void> cancelOngoingStatus() async {
    if (kIsWeb) return;
    await init();
    await _fln.cancel(_statusId);
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
    final uri = await _prefs.getAndroidRingtoneUri();
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_alerts',
      'Pomodoro Alerts',
      channelDescription: 'Reminders when focus/break sessions end',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      sound: (uri != null && uri.isNotEmpty) ? UriAndroidNotificationSound(uri) : null,
      fullScreenIntent: true,
      ticker: 'Pomodoro finished',
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(presentSound: true);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _fln.show(0, title, body, details);
  }

  Future<void> scheduleIn({
    required String title,
    required String body,
    required Duration inFromNow,
    int id = 1,
    bool preferExact = false,
  }) async {
    if (kIsWeb) return;
    await init();
    // Must be strictly in the future; clamp to at least +1s
    final delay = inFromNow.inSeconds <= 0 ? const Duration(seconds: 1) : inFromNow;
    final scheduled = tz.TZDateTime.now(tz.local).add(delay);
    final uri = await _prefs.getAndroidRingtoneUri();
    final androidDetails = AndroidNotificationDetails(
      'pomodoro_alerts',
      'Pomodoro Alerts',
      channelDescription: 'Reminders when focus/break sessions end',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      playSound: true,
      sound: (uri != null && uri.isNotEmpty) ? UriAndroidNotificationSound(uri) : null,
      fullScreenIntent: true,
      ticker: 'Pomodoro finished',
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(presentSound: true);
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    if (preferExact) {
      final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      // Request permission if needed; some devices show a settings page
      await android?.requestExactAlarmsPermission();
      try {
        await _fln.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          details,
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        return;
      } catch (_) {
        // Fall through to inexact if exact not permitted
      }
    }
    await _fln.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
        androidScheduleMode: AndroidScheduleMode.inexact);
  }

  // Optional: call to open exact alarms settings if you later want precise timing
  Future<void> openExactAlarmsSettings() async {
    final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
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
