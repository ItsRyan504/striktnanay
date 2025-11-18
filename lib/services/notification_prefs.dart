import 'package:shared_preferences/shared_preferences.dart';

class NotificationPrefs {
  static const _kAndroidRingtoneUri = 'notif_android_ringtone_uri';

  Future<void> setAndroidRingtoneUri(String? uri) async {
    final sp = await SharedPreferences.getInstance();
    if (uri == null || uri.isEmpty) {
      await sp.remove(_kAndroidRingtoneUri);
    } else {
      await sp.setString(_kAndroidRingtoneUri, uri);
    }
  }

  Future<String?> getAndroidRingtoneUri() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kAndroidRingtoneUri);
  }
}
