import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserPrefs {
  static const _kUserName = 'user_name';
  static const _kDefaultWorkMinutes = 'default_work_minutes';
  static const _kDefaultBreakMinutes = 'default_break_minutes';
  static const _kAutoContinue = 'auto_continue';

  Future<String> getUserName() async {
    final sp = await SharedPreferences.getInstance();
    final name = sp.getString(_kUserName) ?? 'User';
    // Initialize notifier if not yet set
    if (_userNameNotifier.value != name) {
      _userNameNotifier.value = name;
    }
    return name;
    }

  Future<void> setUserName(String name) async {
    final sp = await SharedPreferences.getInstance();
    final normalized = name.trim().isEmpty ? 'User' : name.trim();
    await sp.setString(_kUserName, normalized);
    _userNameNotifier.value = normalized;
  }

  Future<int> getDefaultWorkMinutes() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kDefaultWorkMinutes) ?? 25;
  }

  Future<int> getDefaultBreakMinutes() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kDefaultBreakMinutes) ?? 5;
  }

  Future<void> setDefaultDurations({required int workMinutes, required int breakMinutes}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kDefaultWorkMinutes, workMinutes);
    await sp.setInt(_kDefaultBreakMinutes, breakMinutes);
  }

  Future<bool> getAutoContinue() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kAutoContinue) ?? true;
  }

  Future<void> setAutoContinue(bool value) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAutoContinue, value);
  }
}

// Global ValueNotifier to broadcast username changes across UI without heavy state management.
final ValueNotifier<String> _userNameNotifier = ValueNotifier<String>('User');

ValueListenable<String> get userNameListenable => _userNameNotifier;
