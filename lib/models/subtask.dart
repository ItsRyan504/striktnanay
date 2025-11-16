class Subtask {
  final String id;
  final String name;
  final bool isCompleted;

  Subtask({
    required this.id,
    required this.name,
    this.isCompleted = false,
  });

  Subtask copyWith({
    String? id,
    String? name,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
    };
  }

  factory Subtask.fromJson(Map<String, dynamic> json) {
    return Subtask(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

