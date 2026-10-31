import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';

class TaskProvider extends ChangeNotifier with LoadingStateMixin {
  TaskProvider(this._repository);

  final TaskRepository _repository;

  List<Task> _tasks = const [];
  List<Task> get tasks => _tasks;

  Future<bool> loadTasks(String userId) {
    return runGuarded(() async {
      _tasks = await _repository.fetchAll(userId);
    }, failureMessage: 'Failed to load tasks');
  }

  Future<bool> addOrUpdateTask(String userId, Task task) {
    return runGuarded(() async {
      await _repository.save(userId, task);
      _tasks = await _repository.fetchAll(userId);
    }, failureMessage: 'Failed to save task');
  }

  Future<bool> deleteTask(String userId, Task task) {
    return runGuarded(() async {
      await _repository.delete(userId, task.id);
      _tasks = await _repository.fetchAll(userId);
    }, failureMessage: 'Failed to delete task');
  }
}
