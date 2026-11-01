import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/tasks/domain/reminder_plan.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';

Task _task(
  String id, {
  DateTime? due,
  int? remind,
  bool done = false,
}) =>
    Task(
      id: id,
      title: id,
      dueDate: due,
      remindDaysBefore: remind,
      isDone: done,
    );

void main() {
  final now = DateTime(2030, 6, 10, 8);

  test('schedules at 9:00 on the chosen day', () {
    final plan = planReminders(
      [_task('a', due: DateTime(2030, 6, 12), remind: 1)],
      now: now,
    );

    expect(plan.single.fireAt, DateTime(2030, 6, 11, 9));
  });

  test('skips tasks without a due date or reminder, and finished ones', () {
    final plan = planReminders(
      [
        _task('no-due', remind: 1),
        _task('no-reminder', due: DateTime(2030, 6, 20)),
        _task('done', due: DateTime(2030, 6, 20), remind: 0, done: true),
      ],
      now: now,
    );

    expect(plan, isEmpty);
  });

  test('skips reminders whose time has already passed', () {
    final plan = planReminders(
      [
        _task('late', due: DateTime(2030, 6, 10), remind: 0),
        _task('ok', due: DateTime(2030, 6, 10, 0), remind: 0),
      ],
      now: DateTime(2030, 6, 10, 9, 30),
    );

    expect(plan, isEmpty);
  });

  test('keeps a reminder due later today and sorts by time', () {
    final plan = planReminders(
      [
        _task('later', due: DateTime(2030, 6, 20), remind: 0),
        _task('today', due: DateTime(2030, 6, 10), remind: 0),
      ],
      now: now,
    );

    expect(plan.map((p) => p.task.id), ['today', 'later']);
  });

  test('a week before crosses month boundaries', () {
    final plan = planReminders(
      [_task('a', due: DateTime(2030, 7, 3), remind: 7)],
      now: now,
    );

    expect(plan.single.fireAt, DateTime(2030, 6, 26, 9));
  });

  test('body wording', () {
    expect(reminderBody(0), 'Due today');
    expect(reminderBody(1), 'Due tomorrow');
    expect(reminderBody(7), 'Due in 7 days');
  });
}
