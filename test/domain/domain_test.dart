import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';

void main() {
  group('UserRole', () {
    test('parse falls back to student for unknown or missing values', () {
      expect(UserRole.parse(null), UserRole.student);
      expect(UserRole.parse('superuser'), UserRole.student);
      expect(UserRole.parse('admin'), UserRole.admin);
    });

    test('only professors and admins manage announcements', () {
      expect(UserRole.student.canManageAnnouncements, isFalse);
      expect(UserRole.professor.canManageAnnouncements, isTrue);
      expect(UserRole.admin.canManageAnnouncements, isTrue);
    });

    test('only admins are admins', () {
      expect(UserRole.professor.isAdmin, isFalse);
      expect(UserRole.admin.isAdmin, isTrue);
    });
  });

  group('AppUser.copyWith', () {
    test('keeps the suspension flag when only the name changes', () {
      const user = AppUser(id: '1', email: 'a@b.c', isSuspended: true);
      final renamed = user.copyWith(displayName: 'New');
      expect(renamed.isSuspended, isTrue);
      expect(renamed.displayName, 'New');
      expect(renamed.id, '1');
    });
  });

  group('Task', () {
    final now = DateTime(2026, 1, 10);

    test('is overdue only when past due and not done', () {
      final past = DateTime(2026, 1, 1);
      expect(Task(id: '1', title: 't', dueDate: past).isOverdueAt(now), isTrue);
      expect(
        Task(id: '1', title: 't', dueDate: past, isDone: true).isOverdueAt(now),
        isFalse,
      );
      expect(
        Task(id: '1', title: 't', dueDate: DateTime(2026, 2, 1))
            .isOverdueAt(now),
        isFalse,
      );
      expect(const Task(id: '1', title: 't').isOverdueAt(now), isFalse);
    });
  });
}
