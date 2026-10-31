import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';

abstract interface class UserRepository {
  /// Returns the stored profile. Profiles are created by the database when an
  /// account is created, so a missing profile is an error.
  Future<AppUser> fetchById(String id);

  Future<List<AppUser>> fetchAll();

  Future<void> save(AppUser user);

  /// Permanently deletes an account together with its tasks. Administrators
  /// only; users cannot delete their own account.
  Future<void> delete(String id);
}

abstract interface class AuthRepository {
  /// Emits the signed-in user (with profile) or `null` when signed out.
  Stream<AppUser?> authStateChanges();

  bool get isSignedIn;

  Future<AppUser> signIn({required String email, required String password});

  /// New accounts are always created with the student role.
  ///
  /// Returns the signed-in user, or null when the email address must be
  /// verified first (a code has been emailed; see [verifyEmail]).
  Future<AppUser?> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Completes registration with the 6-digit code sent by email.
  Future<AppUser> verifyEmail({required String email, required String code});

  /// Sends a fresh verification code.
  Future<void> resendVerification(String email);

  /// Emails a password-reset code. Succeeds even for unknown addresses so that
  /// accounts cannot be discovered.
  Future<void> requestPasswordReset(String email);

  /// Sets a new password using the emailed code and signs the user in.
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  Future<void> signOut();

  /// Re-reads the signed-in user's profile. Throws [AccountSuspendedException]
  /// (after signing out) when the account has been suspended in the meantime.
  Future<AppUser> reloadCurrentUser();

  Future<AppUser> updateDisplayName(AppUser user, String displayName);
}
