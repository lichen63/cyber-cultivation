/// Status of a todo item
enum TodoStatus { todo, doing, done }

/// Model for a single todo item
class TodoItem {
  final String id;
  final String title;
  final TodoStatus status;
  final DateTime createdAt;

  const TodoItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static TodoStatus _parseStatus(String? value) {
    switch (value) {
      case 'doing':
        return TodoStatus.doing;
      case 'done':
        return TodoStatus.done;
      default:
        return TodoStatus.todo;
    }
  }

  /// Create a copy with updated fields
  TodoItem copyWith({String? title, TodoStatus? status}) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  /// Cycle to next status: todo -> doing -> done -> todo
  TodoItem cycleStatus() {
    final nextStatus = switch (status) {
      TodoStatus.todo => TodoStatus.doing,
      TodoStatus.doing => TodoStatus.done,
      TodoStatus.done => TodoStatus.todo,
    };
    return copyWith(status: nextStatus);
  }
}
