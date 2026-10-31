class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isDone = false,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isDone;

  bool isOverdueAt(DateTime now) =>
      dueDate != null && dueDate!.isBefore(now) && !isDone;

  bool get isOverdue => isOverdueAt(DateTime.now());

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
    );
  }
}
