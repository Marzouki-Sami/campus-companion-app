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
      try {
        return await _users.fetchOrCreate(user.uid, user.email ?? '');
      } catch (_) {
        // A profile that cannot be loaded must not crash the auth stream.
        return null;
      }
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
      throw AppException(_friendlyMessage(e) ?? fallback);
    }
  }

  /// Plain-language messages for the errors users are likely to hit.
  String? _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your internet and try again.';
      default:
        return null;
    }
  }
}
