import 'subtask.dart';

class Task {
  final String id;
  final String name;
  final List<Subtask> subtasks;
  final bool isCompleted;
  final DateTime? startDate;
  final DateTime? dueDate;
  final String? category;
  final String? color;
  final String? repeatOption;

  Task({
    required this.id,
    required this.name,
    this.subtasks = const [],
    this.isCompleted = false,
    this.startDate,
    this.dueDate,
    this.category,
    this.color,
    this.repeatOption,
  });

  Task copyWith({
    String? id,
    String? name,
    List<Subtask>? subtasks,
    bool? isCompleted,
    DateTime? startDate,
    DateTime? dueDate,
    String? category,
    String? color,
    String? repeatOption,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      startDate: startDate ?? this.startDate,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      color: color ?? this.color,
      repeatOption: repeatOption ?? this.repeatOption,
    );
  }

  int get progressPercentage {
    if (subtasks.isEmpty) {
      return isCompleted ? 100 : 0;
    }
    final completedCount = subtasks.where((s) => s.isCompleted).length;
    return ((completedCount / subtasks.length) * 100).round();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtasks': subtasks.map((s) => s.toJson()).toList(),
      'isCompleted': isCompleted,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'color': color,
      'repeatOption': repeatOption,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Safely parse subtasks - handle both old format (List<String>) and new format (List<Subtask>)
    List<Subtask> subtasksList = [];
    if (json['subtasks'] != null) {
      if (json['subtasks'] is List) {
        final subtasksData = json['subtasks'] as List;
        for (var item in subtasksData) {
          if (item is Map<String, dynamic>) {
            // New format: Subtask object
            try {
              subtasksList.add(Subtask.fromJson(item));
            } catch (e) {
              // Skip invalid subtask entries
            }
          } else if (item is String) {
            // Legacy support: if subtask is just a string, convert it to Subtask
            subtasksList.add(Subtask(
              id: '${DateTime.now().millisecondsSinceEpoch}_${subtasksList.length}',
              name: item,
            ));
          }
        }
      }
    }

    // Safely parse nullable strings
    String? parseNullableString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return null; // If it's a List, return null
      return value.toString();
    }

    return Task(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      subtasks: subtasksList,
      isCompleted: json['isCompleted'] as bool? ?? false,
      startDate: json['startDate'] != null && json['startDate'] is String
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      dueDate: json['dueDate'] != null && json['dueDate'] is String
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      category: parseNullableString(json['category']),
      color: parseNullableString(json['color']),
      repeatOption: parseNullableString(json['repeatOption']),
    );
  }
}

