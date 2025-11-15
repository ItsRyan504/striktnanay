class Task {
  final String id;
  final String name;
  final List<String> subtasks;
  final bool isCompleted;
  final DateTime? dueDate;
  final String? category;
  final String? color;

  Task({
    required this.id,
    required this.name,
    this.subtasks = const [],
    this.isCompleted = false,
    this.dueDate,
    this.category,
    this.color,
  });

  Task copyWith({
    String? id,
    String? name,
    List<String>? subtasks,
    bool? isCompleted,
    DateTime? dueDate,
    String? category,
    String? color,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      subtasks: subtasks ?? this.subtasks,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subtasks': subtasks,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'color': color,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      subtasks: List<String>.from(json['subtasks'] ?? []),
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      category: json['category'] as String?,
      color: json['color'] as String?,
    );
  }
}

