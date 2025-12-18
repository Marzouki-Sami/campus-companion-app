import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/task.dart';
import '../models/announcement.dart';

/// Simple wrapper around Cloud Firestore calls used in the app.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<AppUser> fetchUserProfile(String uid, String emailFallback) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    final user = AppUser(id: uid, email: emailFallback);
    await saveUserProfile(user);
    return user;
  }

  Future<void> saveUserProfile(AppUser user) {
    return _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<List<Task>> fetchTasks(String userId) async {
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('title')
        .get();
    return snap.docs
        .map((d) => Task.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTask(String userId, Task task) async {
    final ref = _db.collection('users').doc(userId).collection('tasks');
    if (task.id.isEmpty) {
      await ref.add(task.toMap());
    } else {
      await ref.doc(task.id).set(task.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteTask(String userId, String taskId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Future<List<Announcement>> fetchAnnouncements() async {
    final snap = await _db.collection('announcements').orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => Announcement.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }
}


