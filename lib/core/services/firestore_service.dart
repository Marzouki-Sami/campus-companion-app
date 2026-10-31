import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart' show AnnouncementCategory;

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
        .map((d) => Task.fromMap(d.id, d.data()))
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
        .map((d) => Announcement.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> saveAnnouncement(Announcement announcement) async {
    final ref = _db.collection('announcements');
    if (announcement.id.isEmpty) {
      await ref.add(announcement.toMap());
    } else {
      await ref.doc(announcement.id).set(announcement.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteAnnouncement(String announcementId) {
    return _db.collection('announcements').doc(announcementId).delete();
  }

  // Category management (admin only)
  Future<List<AnnouncementCategory>> fetchCategories() async {
    final snap = await _db.collection('categories').orderBy('name').get();
    return snap.docs
        .map((d) => AnnouncementCategory.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> saveCategory(AnnouncementCategory category) async {
    final ref = _db.collection('categories');
    if (category.id.isEmpty) {
      await ref.add(category.toMap());
    } else {
      await ref.doc(category.id).set(category.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteCategory(String categoryId) {
    return _db.collection('categories').doc(categoryId).delete();
  }

  // Fetch all users (for admin dashboard)
  Future<List<AppUser>> fetchAllUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .toList();
  }
}


