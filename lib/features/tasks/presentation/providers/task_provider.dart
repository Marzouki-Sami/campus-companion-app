import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/tasks/domain/reminder_service.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';

class TaskProvider extends ChangeNotifier with LoadingStateMixin {
  TaskProvider(
    this._repository, {
    ReminderService reminders = const NoReminders(),
  }) : _reminders = reminders;

  final TaskRepository _repository;
  final ReminderService _reminders;

  List<Task> _tasks = const [];
  List<Task> get tasks => _tasks;

  Future<bool> loadTasks(String userId) {
    return runGuarded(() async {
      _tasks = await _repository.fetchAll(userId);
      _syncReminders();
    }, failureMessage: 'Failed to load tasks');
  }

  /// Asks for notification permission; used when a reminder is first chosen.
  Future<bool> allowReminders() => _reminders.requestPermission();

  /// Forgets the signed-in user's tasks and their reminders.
  Future<void> clear() async {
    _tasks = const [];
    notifyListeners();
    await _reminders.cancelAll();
  }

  /// Reminders are a convenience: a scheduling failure must not break tasks.
  void _syncReminders() {
    _reminders.sync(_tasks).catchError((Object _) {});
  }

  Future<bool> addOrUpdateTask(String userId, Task task) {
    return runGuarded(() async {
      await _repository.save(userId, task);
      _tasks = await _repository.fetchAll(userId);
      _syncReminders();
    }, failureMessage: 'Failed to save task');
  }

  Future<bool> deleteTask(String userId, Task task) {
    return runGuarded(() async {
      await _repository.delete(userId, task.id);
      _tasks = await _repository.fetchAll(userId);
      _syncReminders();
    }, failureMessage: 'Failed to delete task');
  }
}
