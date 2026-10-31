import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campus_companion/core/utils/firestore_dates.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tasks(String userId) =>
      _db.collection('users').doc(userId).collection('tasks');

  @override
  Future<List<Task>> fetchAll(String userId) async {
    final snap = await _tasks(userId).orderBy('title').get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
  }

  @override
  Future<void> save(String userId, Task task) async {
    final data = {
      'title': task.title,
      'description': task.description,
      'dueDate':
          task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
      'isDone': task.isDone,
    };
    if (task.id.isEmpty) {
      await _tasks(userId).add(data);
    } else {
      await _tasks(userId).doc(task.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String userId, String taskId) =>
      _tasks(userId).doc(taskId).delete();

  Task _fromDoc(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      dueDate: readDate(data['dueDate']),
      isDone: data['isDone'] as bool? ?? false,
    );
  }
}
