import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/announcements/data/supabase_announcement_repository.dart';
import 'package:campus_companion/features/auth/data/supabase_user_repository.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';
import 'package:campus_companion/features/categories/data/supabase_category_repository.dart';
import 'package:campus_companion/features/tasks/data/supabase_task_repository.dart';

void main() {
  group('profileFromRow', () {
    test('maps every column', () {
      final user = profileFromRow({
        'id': 'u1',
        'email': 'a@b.c',
        'display_name': 'Sam',
        'role': 'professor',
        'is_suspended': true,
      });

      expect(user.id, 'u1');
      expect(user.email, 'a@b.c');
      expect(user.displayName, 'Sam');
      expect(user.role, UserRole.professor);
      expect(user.isSuspended, isTrue);
    });

    test('falls back to a student for unknown roles', () {
      final user = profileFromRow({
        'id': 'u1',
        'email': 'a@b.c',
        'display_name': null,
        'role': 'superuser',
        'is_suspended': false,
      });

      expect(user.role, UserRole.student);
      expect(user.displayName, isNull);
    });
  });

  group('taskFromRow', () {
    test('parses the due date into local time', () {
      final task = taskFromRow({
        'id': 't1',
        'title': 'Read',
        'description': 'Chapter 7',
        'due_date': '2026-03-05T10:00:00+00:00',
        'is_done': true,
      });

      expect(task.dueDate, DateTime.utc(2026, 3, 5, 10).toLocal());
      expect(task.dueDate!.isUtc, isFalse);
      expect(task.isDone, isTrue);
    });

    test('handles tasks without a due date or description', () {
      final task = taskFromRow({
        'id': 't1',
        'title': 'Read',
        'description': null,
        'due_date': null,
        'is_done': false,
      });

      expect(task.dueDate, isNull);
      expect(task.description, isNull);
    });
  });

  group('announcementFromRow', () {
    test('collects the linked category ids', () {
      final announcement = announcementFromRow({
        'id': 'a1',
        'title': 'Hello',
        'body': 'World',
        'created_at': '2026-03-05T10:00:00+00:00',
        'announcement_categories': [
          {'category_id': 'c1'},
          {'category_id': 'c2'},
        ],
      });

      expect(announcement.categories, ['c1', 'c2']);
      expect(announcement.createdAt, DateTime.utc(2026, 3, 5, 10).toLocal());
    });

    test('works without any categories', () {
      final announcement = announcementFromRow({
        'id': 'a1',
        'title': 'Hello',
        'body': 'World',
        'created_at': '2026-03-05T10:00:00+00:00',
        'announcement_categories': <dynamic>[],
      });

      expect(announcement.categories, isEmpty);
    });

    test('orders photos by position and builds their urls', () {
      final announcement = announcementFromRow(
        {
          'id': 'a1',
          'title': 'Hello',
          'body': 'World',
          'created_at': '2026-03-05T10:00:00+00:00',
          'announcement_images': [
            {'path': 'a1/second.jpg', 'position': 1},
            {'path': 'a1/first.jpg', 'position': 0},
          ],
        },
        imageUrl: (path) => 'https://files.test/$path',
      );

      expect(announcement.images.map((i) => i.path),
          ['a1/first.jpg', 'a1/second.jpg']);
      expect(announcement.images.first.url, 'https://files.test/a1/first.jpg');
    });

    test('an announcement without photos has none', () {
      final announcement = announcementFromRow({
        'id': 'a1',
        'title': 'Hello',
        'body': 'World',
        'created_at': '2026-03-05T10:00:00+00:00',
      });

      expect(announcement.images, isEmpty);
    });
  });

  test('categoryFromRow maps the columns', () {
    final category = categoryFromRow({
      'id': 'c1',
      'name': 'Exams',
      'created_at': '2026-03-05T10:00:00+00:00',
    });

    expect(category.id, 'c1');
    expect(category.name, 'Exams');
  });
}
