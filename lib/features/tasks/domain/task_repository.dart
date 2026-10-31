import 'package:campus_companion/features/tasks/domain/task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> fetchAll(String userId);

  /// Creates the task when [Task.id] is empty, otherwise updates it.
  Future<void> save(String userId, Task task);

  Future<void> delete(String userId, String taskId);
}
