import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';

import '../support/fakes.dart';

void main() {
  late FakeTaskRepository repository;
  late FakeReminderService reminders;
  late TaskProvider provider;

  setUp(() {
    repository = FakeTaskRepository();
    reminders = FakeReminderService();
    provider = TaskProvider(repository, reminders: reminders);
  });

  test('reminders are synced after loading, saving and deleting', () async {
    await provider.loadTasks('u1');
    await provider.addOrUpdateTask(
      'u1',
      Task(
        id: '',
        title: 'Essay',
        dueDate: DateTime(2030, 6, 20),
        remindDaysBefore: 1,
      ),
    );
    await provider.deleteTask('u1', provider.tasks.single);
    await Future<void>.delayed(Duration.zero);

    expect(reminders.synced, hasLength(3));
  });

  test('a failing reminder service never breaks task actions', () async {
    reminders.failSync = true;

    final ok = await provider.addOrUpdateTask(
      'u1',
      const Task(id: '', title: 'Essay'),
    );

    expect(ok, isTrue);
    expect(provider.errorMessage, isNull);
  });

  test('clear forgets the tasks and cancels reminders', () async {
    await provider.addOrUpdateTask('u1', const Task(id: '', title: 'Essay'));

    await provider.clear();

    expect(provider.tasks, isEmpty);
    expect(reminders.cancelCount, 1);
  });

  test('allowReminders reports the permission answer', () async {
    reminders.allowed = false;

    expect(await provider.allowReminders(), isFalse);
  });
}
