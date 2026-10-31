import 'package:campus_companion/features/auth/domain/app_user.dart';

abstract interface class UserRepository {
  /// Returns the stored profile, creating a default one when it does not exist.
  Future<AppUser> fetchOrCreate(String uid, String email);

  Future<List<AppUser>> fetchAll();

  Future<void> save(AppUser user);
}

abstract interface class AuthRepository {
  /// Emits the signed-in user (with profile) or `null` when signed out.
  Stream<AppUser?> authStateChanges();

  bool get isSignedIn;

  Future<AppUser> signIn({required String email, required String password});

  /// New accounts are always created with the student role.
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> signOut();

  Future<AppUser> updateDisplayName(AppUser user, String displayName);
}
