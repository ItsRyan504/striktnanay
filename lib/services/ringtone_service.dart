import 'dart:io' show Platform;
import 'package:flutter/services.dart';

class RingtoneService {
  static const MethodChannel _channel = MethodChannel('com.striktnanay.app/ringtone');

  Future<String?> pickAndroidAlarmRingtone() async {
    if (!Platform.isAndroid) return null;
    try {
      final uri = await _channel.invokeMethod<String>('pickRingtone');
      return uri; // content:// media URI or null
    } on MissingPluginException {
      // Native side not (yet) registered. Usually fixed by a clean rebuild.
      // Returning null avoids crashing the UI and lets us prompt the user.
      return null;
    } on PlatformException {
      // Any other platform issue picking a tone -> just return null.
      return null;
    }
  }

  Future<bool> scheduleAndroidAlarm(int id, int timeMillis, String? uri) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'id': id,
        'timeMillis': timeMillis,
        'uri': uri,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> cancelAndroidAlarm(int id) async {
    if (!Platform.isAndroid) return false;
    try {
      final res = await _channel.invokeMethod<bool>('cancelAlarm', {'id': id});
      return res ?? false;
    } catch (_) {
      return false;
    }
  }
}
