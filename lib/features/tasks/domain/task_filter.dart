import 'package:campus_companion/features/tasks/domain/task.dart';

enum TaskStatusFilter {
  all('All'),
  open('Open'),
  done('Done');

  const TaskStatusFilter(this.label);

  final String label;
}

/// Filters [tasks] and orders them: open tasks first, earliest due date first,
/// tasks without a due date last.
List<Task> applyTaskFilter(
  List<Task> tasks, {
  TaskStatusFilter status = TaskStatusFilter.all,
  bool onlyOverdue = false,
  String query = '',
  DateTime? now,
}) {
  final reference = now ?? DateTime.now();
  final needle = query.trim().toLowerCase();

  final result = tasks.where((t) {
    final statusOk = switch (status) {
      TaskStatusFilter.all => true,
      TaskStatusFilter.open => !t.isDone,
      TaskStatusFilter.done => t.isDone,
    };
    if (!statusOk) return false;
    if (onlyOverdue && !t.isOverdueAt(reference)) return false;
    if (needle.isEmpty) return true;
    return t.title.toLowerCase().contains(needle) ||
        (t.description?.toLowerCase().contains(needle) ?? false);
  }).toList();

  result.sort((a, b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });
  return result;
}
