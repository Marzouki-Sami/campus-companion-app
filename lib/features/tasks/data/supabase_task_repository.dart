import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/errors/database_errors.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';

Task taskFromRow(Map<String, dynamic> row) {
  final due = row['due_date'] as String?;
  return Task(
    id: row['id'] as String,
    title: row['title'] as String? ?? '',
    description: row['description'] as String?,
    dueDate: due == null ? null : DateTime.parse(due).toLocal(),
    isDone: row['is_done'] as bool? ?? false,
  );
}

class SupabaseTaskRepository implements TaskRepository {
  SupabaseTaskRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Task>> fetchAll(String userId) {
    return guardDb(() async {
      final rows = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return rows.map(taskFromRow).toList();
    });
  }

  @override
  Future<void> save(String userId, Task task) {
    return guardDb(() async {
      final values = {
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate?.toUtc().toIso8601String(),
        'is_done': task.isDone,
      };
      if (task.id.isEmpty) {
        await _client.from('tasks').insert({...values, 'user_id': userId});
        return;
      }
      final updated = await _client
          .from('tasks')
          .update(values)
          .eq('id', task.id)
          .eq('user_id', userId)
          .select('id');
      if (updated.isEmpty) {
        throw const AppException('That task no longer exists.');
      }
    });
  }

  @override
  Future<void> delete(String userId, String taskId) {
    return guardDb(() async {
      await _client
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', userId);
    });
  }
}
