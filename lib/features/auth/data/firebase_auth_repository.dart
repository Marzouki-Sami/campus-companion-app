import 'package:firebase_auth/firebase_auth.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._users);

  final FirebaseAuth _auth;
  final UserRepository _users;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _users.fetchOrCreate(user.uid, user.email ?? '');
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _guard(
      () => _auth.signInWithEmailAndPassword(email: email, password: password),
      fallback: 'Login failed',
    );
    final user = cred.user!;
    final profile = await _users.fetchOrCreate(user.uid, user.email ?? email);
    if (profile.isSuspended) {
      await _auth.signOut();
      throw const AppException(
        'Your account has been suspended. If you believe this is a mistake, '
        'please contact support.',
      );
    }
    return profile;
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _guard(
      () => _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ),
      fallback: 'Registration failed',
    );
    final user = AppUser(
      id: cred.user!.uid,
      email: cred.user!.email ?? email,
      displayName: displayName.isEmpty ? null : displayName,
    );
    await _users.save(user);
    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> updateDisplayName(AppUser user, String displayName) async {
    await _guard(
      () => _auth.currentUser!.updateDisplayName(displayName),
      fallback: 'Failed to update profile',
    );
    final updated = user.copyWith(displayName: displayName);
    await _users.save(updated);
    return updated;
  }

  Future<T> _guard<T>(Future<T> Function() action,
      {required String fallback}) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AppException(e.message ?? fallback);
    }
  }
}
