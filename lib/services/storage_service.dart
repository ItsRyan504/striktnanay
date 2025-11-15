import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _whitelistKey = 'whitelist';
  static const String _focusModeKey = 'focusMode';

  // Tasks
  Future<List<Task>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    if (tasksJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(tasksJson);
    return decoded.map((json) => Task.fromJson(json)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
  }

  // Whitelist
  Future<Map<String, bool>> getWhitelist() async {
    final prefs = await SharedPreferences.getInstance();
    final whitelistJson = prefs.getString(_whitelistKey);
    if (whitelistJson == null) return {};
    
    final Map<String, dynamic> decoded = jsonDecode(whitelistJson);
    return decoded.map((key, value) => MapEntry(key, value as bool));
  }

  Future<void> saveWhitelist(Map<String, bool> whitelist) async {
    final prefs = await SharedPreferences.getInstance();
    final whitelistJson = jsonEncode(whitelist);
    await prefs.setString(_whitelistKey, whitelistJson);
  }

  // Focus Mode
  Future<bool> getFocusModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_focusModeKey) ?? false;
  }

  Future<void> setFocusModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusModeKey, enabled);
  }
}

