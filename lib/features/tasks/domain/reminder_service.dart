import 'package:campus_companion/features/tasks/domain/task.dart';

/// Schedules local notifications for tasks that have a reminder.
abstract interface class ReminderService {
  /// Asks the user to allow notifications. Returns whether they are allowed.
  Future<bool> requestPermission();

  /// Replaces every scheduled reminder with the ones [tasks] call for.
  Future<void> sync(List<Task> tasks);

  /// Removes every scheduled reminder, e.g. when the user signs out.
  Future<void> cancelAll();
}

class NoReminders implements ReminderService {
  const NoReminders();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync(List<Task> tasks) async {}

  @override
  Future<void> cancelAll() async {}
}
