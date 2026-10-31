import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campus_companion/core/utils/firestore_dates.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';

class FirestoreAnnouncementRepository implements AnnouncementRepository {
  FirestoreAnnouncementRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('announcements');

  @override
  Future<List<Announcement>> fetchAll() async {
    final snap = await _collection.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
  }

  @override
  Future<void> save(Announcement announcement) async {
    final data = {
      'title': announcement.title,
      'body': announcement.body,
      'createdAt': Timestamp.fromDate(announcement.createdAt),
      'categories': announcement.categories,
    };
    if (announcement.id.isEmpty) {
      await _collection.add(data);
    } else {
      await _collection.doc(announcement.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();

  Announcement _fromDoc(String id, Map<String, dynamic> data) {
    return Announcement(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
      categories: (data['categories'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
