import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campus_companion/core/utils/firestore_dates.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';
import 'package:campus_companion/features/categories/domain/category_repository.dart';

class FirestoreCategoryRepository implements CategoryRepository {
  FirestoreCategoryRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection('categories');

  @override
  Future<List<AnnouncementCategory>> fetchAll() async {
    final snap = await _collection.orderBy('name').get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
  }

  @override
  Future<void> save(AnnouncementCategory category) async {
    final data = {
      'name': category.name,
      'createdAt': Timestamp.fromDate(category.createdAt),
    };
    if (category.id.isEmpty) {
      await _collection.add(data);
    } else {
      await _collection.doc(category.id).set(data, SetOptions(merge: true));
    }
  }

  @override
  Future<void> delete(String id) => _collection.doc(id).delete();

  AnnouncementCategory _fromDoc(String id, Map<String, dynamic> data) {
    return AnnouncementCategory(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: readDate(data['createdAt']) ?? DateTime.now(),
    );
  }
}
