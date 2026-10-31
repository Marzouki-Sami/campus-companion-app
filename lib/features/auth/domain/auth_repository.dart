import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';

abstract interface class UserRepository {
  /// Returns the stored profile. Profiles are created by the database when an
  /// account is created, so a missing profile is an error.
  Future<AppUser> fetchById(String id);

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

  /// Re-reads the signed-in user's profile. Throws [AccountSuspendedException]
  /// (after signing out) when the account has been suspended in the meantime.
  Future<AppUser> reloadCurrentUser();

  Future<AppUser> updateDisplayName(AppUser user, String displayName);
}
