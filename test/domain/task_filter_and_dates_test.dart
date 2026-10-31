import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_filter.dart';

void main() {
  final now = DateTime(2026, 1, 10, 12);

  group('applyTaskFilter', () {
    final tasks = [
      Task(id: '1', title: 'Write report', dueDate: DateTime(2026, 1, 20)),
      Task(id: '2', title: 'Read chapter', dueDate: DateTime(2026, 1, 5)),
      const Task(id: '3', title: 'Buy notebook'),
      Task(
          id: '4',
          title: 'Submit form',
          dueDate: DateTime(2026, 1, 2),
          isDone: true),
    ];

    test('orders open tasks by due date, undated and done tasks last', () {
      final ids = applyTaskFilter(tasks, now: now).map((t) => t.id);
      expect(ids, ['2', '1', '3', '4']);
    });

    test('filters by status', () {
      expect(
        applyTaskFilter(tasks, status: TaskStatusFilter.done, now: now)
            .map((t) => t.id),
        ['4'],
      );
      expect(
        applyTaskFilter(tasks, status: TaskStatusFilter.open, now: now).length,
        3,
      );
    });

    test('overdue excludes completed tasks', () {
      final ids =
          applyTaskFilter(tasks, onlyOverdue: true, now: now).map((t) => t.id);
      expect(ids, ['2']);
    });

    test('search is case-insensitive and matches anywhere in the title', () {
      final ids =
          applyTaskFilter(tasks, query: 'CHAPTER', now: now).map((t) => t.id);
      expect(ids, ['2']);
    });
  });

  group('date formatting', () {
    test('formatDate', () {
      expect(formatDate(DateTime(2026, 10, 3)), '3 Oct 2026');
    });

    test('formatRelativeDate', () {
      expect(formatRelativeDate(DateTime(2026, 1, 10, 3), now: now), 'Today');
      expect(formatRelativeDate(DateTime(2026, 1, 9), now: now), 'Yesterday');
      expect(formatRelativeDate(DateTime(2026, 1, 7), now: now), '3 days ago');
      expect(formatRelativeDate(DateTime(2025, 12, 1), now: now), '1 Dec 2025');
    });

    test('formatDue', () {
      expect(formatDue(DateTime(2026, 1, 10), now: now), 'Due today');
      expect(formatDue(DateTime(2026, 1, 11), now: now), 'Due tomorrow');
      expect(formatDue(DateTime(2026, 1, 9), now: now), '1 day overdue');
      expect(formatDue(DateTime(2026, 1, 5), now: now), '5 days overdue');
      expect(formatDue(DateTime(2026, 2, 1), now: now), 'Due 1 Feb 2026');
    });
  });
}
