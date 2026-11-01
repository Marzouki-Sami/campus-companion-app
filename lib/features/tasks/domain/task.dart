class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isDone = false,
    this.remindDaysBefore,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isDone;

  /// Days before the due date to be reminded (0 = on the day), or null.
  final int? remindDaysBefore;

  /// A task is overdue once its due *day* has passed; due today is not overdue.
  bool isOverdueAt(DateTime now) {
    final due = dueDate;
    if (due == null || isDone) return false;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  bool get isOverdue => isOverdueAt(DateTime.now());

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isDone,
    int? remindDaysBefore,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    );
  }
}
