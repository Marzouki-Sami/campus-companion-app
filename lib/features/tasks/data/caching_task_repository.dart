import 'package:campus_companion/core/offline/cached_fetch.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';
import 'package:campus_companion/features/tasks/data/task_json.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';

/// Wraps another repository and keeps an offline copy of the user's tasks.
/// Changes still need a connection.
class CachingTaskRepository implements TaskRepository {
  CachingTaskRepository(this._inner, this._cache, this._offline);

  final TaskRepository _inner;
  final LocalCache _cache;
  final OfflineState _offline;

  @override
  Future<List<Task>> fetchAll(String userId) {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'tasks.$userId',
      fetch: () => _inner.fetchAll(userId),
      encode: tasksToJson,
      decode: tasksFromJson,
    );
  }

  @override
  Future<void> save(String userId, Task task) => _inner.save(userId, task);

  @override
  Future<void> delete(String userId, String taskId) =>
      _inner.delete(userId, taskId);
}
