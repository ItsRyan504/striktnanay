class Task {
  final String id;
  final String name;
  final List<String> subtasks;
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
    List<String>? subtasks,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtasks': subtasks,
      'isCompleted': isCompleted,
      'startDate': startDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'color': color,
      'repeatOption': repeatOption,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    // Safely parse subtasks
    List<String> subtasksList = [];
    if (json['subtasks'] != null) {
      if (json['subtasks'] is List) {
        subtasksList = List<String>.from(
          (json['subtasks'] as List).map((e) => e.toString()),
        );
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

