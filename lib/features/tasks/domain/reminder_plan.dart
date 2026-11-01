import 'package:campus_companion/features/tasks/domain/task.dart';

/// Reminders go off at this hour (local time) on the chosen day.
const reminderHour = 9;

class PlannedReminder {
  const PlannedReminder({required this.task, required this.fireAt});

  final Task task;
  final DateTime fireAt;
}

/// The reminders worth scheduling: open tasks with a due date and a reminder
/// whose time is still ahead, soonest first.
List<PlannedReminder> planReminders(List<Task> tasks, {required DateTime now}) {
  final planned = <PlannedReminder>[];
  for (final task in tasks) {
    final due = task.dueDate;
    final daysBefore = task.remindDaysBefore;
    if (task.isDone || due == null || daysBefore == null) continue;

    final fireAt = DateTime(
      due.year,
      due.month,
      due.day - daysBefore,
      reminderHour,
    );
    if (fireAt.isAfter(now)) {
      planned.add(PlannedReminder(task: task, fireAt: fireAt));
    }
  }
  planned.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return planned;
}

/// The wording of a reminder's body, e.g. `Due today` or `Due tomorrow`.
String reminderBody(int daysBefore) {
  return switch (daysBefore) {
    0 => 'Due today',
    1 => 'Due tomorrow',
    _ => 'Due in $daysBefore days',
  };
}
