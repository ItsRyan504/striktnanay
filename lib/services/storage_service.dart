import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import 'task_sync.dart';

class StorageService {
  static const String _tasksKey = 'tasks';
  static const String _whitelistKey = 'whitelist';
  static const String _focusModeKey = 'focusMode';

  // Tasks
  Future<List<Task>> getTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);
      if (tasksJson == null) return [];
      
      final decoded = jsonDecode(tasksJson);
      if (decoded is! List) return [];
      
      final List<dynamic> tasksList = decoded;
      final List<Task> validTasks = [];
      
      for (var json in tasksList) {
        try {
          if (json is Map<String, dynamic>) {
            // Create a copy of the json map to avoid modifying the original
            final taskJson = Map<String, dynamic>.from(json);
            
            // Ensure subtasks are properly converted from old format (List<String>) to new format (List<Subtask>)
            if (taskJson['subtasks'] != null && taskJson['subtasks'] is List) {
              final subtasks = taskJson['subtasks'] as List;
              // Convert old String subtasks to Subtask format
              if (subtasks.isNotEmpty && subtasks.first is String) {
                final timestamp = DateTime.now().millisecondsSinceEpoch;
                taskJson['subtasks'] = subtasks.asMap().entries.map((entry) {
                  return {
                    'id': '${timestamp}_${entry.key}',
                    'name': entry.value.toString(),
                    'isCompleted': false,
                  };
                }).toList();
              }
            }
            validTasks.add(Task.fromJson(taskJson));
          }
        } catch (e) {
          // Skip invalid task entries, but log for debugging
          print('Error parsing task: $e');
        }
      }
      
      return validTasks;
    } catch (e) {
      // If there's an error reading tasks, return empty list
      print('Error loading tasks: $e');
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await prefs.setString(_tasksKey, tasksJson);
    // Notify listeners that tasks changed
    TaskSync.instance.notifyChanged();
  }

  // Whitelist
  Future<Map<String, bool>> getWhitelist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final whitelistJson = prefs.getString(_whitelistKey);
      if (whitelistJson == null) return {};
      
      final decoded = jsonDecode(whitelistJson);
      if (decoded is! Map) return {};
      
      final Map<String, dynamic> whitelistMap = decoded.cast<String, dynamic>();
      return whitelistMap.map((key, value) {
        if (value is bool) {
          return MapEntry(key, value);
        }
        // If value is not bool, default to false
        return MapEntry(key, false);
      });
    } catch (e) {
      // If there's an error reading whitelist, return empty map
      return {};
    }
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

