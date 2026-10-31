import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  @override
  Future<AppUser> fetchOrCreate(String uid, String email) async {
    final doc = await _users.doc(uid).get();
    if (doc.exists) return _fromDoc(doc.id, doc.data()!);
    final user = AppUser(id: uid, email: email);
    await save(user);
    return user;
  }

  @override
  Future<List<AppUser>> fetchAll() async {
    final snap = await _users.get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
  }

  @override
  Future<void> save(AppUser user) {
    return _users.doc(user.id).set({
      'email': user.email,
      'displayName': user.displayName,
      'role': user.role.name,
      'isSuspended': user.isSuspended,
    }, SetOptions(merge: true));
  }

  AppUser _fromDoc(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      role: UserRole.parse(data['role'] as String?),
      isSuspended: data['isSuspended'] == true,
    );
  }
}
