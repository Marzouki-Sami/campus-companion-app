import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import '../support/fakes.dart';

void main() {
  late FakeTaskRepository repository;
  late TaskProvider provider;

  setUp(() {
    repository = FakeTaskRepository();
    provider = TaskProvider(repository);
  });

  test('adds a task and refreshes the list', () async {
    final ok =
        await provider.addOrUpdateTask('u', const Task(id: '', title: 'Read'));

    expect(ok, isTrue);
    expect(provider.tasks.map((t) => t.title), ['Read']);
    expect(provider.tasks.single.id, isNotEmpty);
  });

  test('updates an existing task', () async {
    await provider.addOrUpdateTask('u', const Task(id: '', title: 'Read'));
    final created = provider.tasks.single;

    await provider.addOrUpdateTask('u', created.copyWith(isDone: true));

    expect(provider.tasks.single.isDone, isTrue);
  });

  test('deletes a task', () async {
    await provider.addOrUpdateTask('u', const Task(id: '', title: 'Read'));
    await provider.deleteTask('u', provider.tasks.single);

    expect(provider.tasks, isEmpty);
  });

  test('tasks are scoped per user', () async {
    await provider.addOrUpdateTask('a', const Task(id: '', title: 'Mine'));
    await provider.loadTasks('b');

    expect(provider.tasks, isEmpty);
  });

  test('exposes an error message and recovers after a failure', () async {
    repository.shouldFail = true;
    final failed = await provider.loadTasks('u');

    expect(failed, isFalse);
    expect(provider.errorMessage, 'Failed to load tasks');
    expect(provider.isLoading, isFalse);

    repository.shouldFail = false;
    expect(await provider.loadTasks('u'), isTrue);
    expect(provider.errorMessage, isNull);
  });

  test('notifies listeners while loading', () async {
    final states = <bool>[];
    provider.addListener(() => states.add(provider.isLoading));

    await provider.loadTasks('u');

    expect(states, [true, false]);
  });
}
