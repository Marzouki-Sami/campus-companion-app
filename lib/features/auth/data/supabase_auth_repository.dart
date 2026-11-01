import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/auth/domain/captcha_solver.dart';

const _offlineMessage = 'No connection. Check your internet and try again.';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._client,
    this._users, {
    CaptchaSolver captcha = const NoCaptcha(),
  }) : _captcha = captcha;

  final SupabaseClient _client;
  final UserRepository _users;
  final CaptchaSolver _captcha;

  GoTrueClient get _auth => _client.auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.onAuthStateChange
        .where(
      (state) =>
          state.event == AuthChangeEvent.initialSession ||
          state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.signedOut ||
          state.event == AuthChangeEvent.userUpdated,
    )
        .asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      try {
        final profile = await _users.fetchById(user.id);
        if (profile.isSuspended) {
          await _signOutQuietly();
          return null;
        }
        return profile;
      } on AccountRemovedException {
        await _signOutQuietly();
        return null;
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
    final captchaToken = await _captcha.solve();
    final response = await _guard(
      () => _auth.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,
      ),
      fallback: 'Login failed',
      email: email,
    );
    final user = response.user;
    if (user == null) throw const AppException('Login failed');

    return _activeProfile(user);
  }

  @override
  Future<AppUser?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final captchaToken = await _captcha.solve();
    final response = await _guard(
      () => _auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
        captchaToken: captchaToken,
      ),
      fallback: 'Registration failed',
    );
    final user = response.user;
    if (user == null) throw const AppException('Registration failed');
    // No session means the project requires email verification first.
    if (response.session == null) return null;
    return _activeProfile(user);
  }

  @override
  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _guard(
      () => _auth.verifyOTP(type: OtpType.signup, email: email, token: code),
      fallback: 'Verification failed',
    );
    return _activeProfile(response.user);
  }

  @override
  Future<void> resendVerification(String email) async {
    final captchaToken = await _captcha.solve();
    return _guard(
      () => _auth.resend(
        type: OtpType.signup,
        email: email,
        captchaToken: captchaToken,
      ),
      fallback: 'Could not send a new code',
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final captchaToken = await _captcha.solve();
    return _guard(
      () => _auth.resetPasswordForEmail(email, captchaToken: captchaToken),
      fallback: 'Could not send a reset code',
    );
  }

  @override
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _guard(
      () => _auth.verifyOTP(type: OtpType.recovery, email: email, token: code),
      fallback: 'Could not reset the password',
    );
    await _guard(
      () => _auth.updateUser(UserAttributes(password: newPassword)),
      fallback: 'Could not reset the password',
    );
    return _activeProfile(response.user);
  }

  Future<AppUser> _activeProfile(User? user) async {
    if (user == null) throw const AppException('Something went wrong.');
    return _activeProfileById(user.id);
  }

  /// Loads a profile for a signed-in session, ending the session (and telling
  /// the caller why) when the account is suspended or no longer exists.
  Future<AppUser> _activeProfileById(String id) async {
    try {
      final profile = await _users.fetchById(id);
      if (profile.isSuspended) {
        await _signOutQuietly();
        throw const AccountSuspendedException();
      }
      return profile;
    } on AccountRemovedException {
      await _signOutQuietly();
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> reloadCurrentUser() async {
    final id = _auth.currentUser?.id;
    if (id == null) throw const AppException('You are signed out.');
    return _activeProfileById(id);
  }

  @override
  Future<AppUser> updateDisplayName(AppUser user, String displayName) async {
    final updated = user.copyWith(displayName: displayName);
    await _users.save(updated);
    return updated;
  }

  Future<void> _signOutQuietly() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Already signed out or offline: the local session is cleared anyway.
    }
  }

  Future<T> _guard<T>(
    Future<T> Function() action, {
    required String fallback,
    String? email,
  }) async {
    try {
      return await action();
    } on AuthRetryableFetchException {
      throw const AppException(_offlineMessage);
    } on SocketException {
      throw const AppException(_offlineMessage);
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed' && email != null) {
        throw EmailNotVerifiedException(email);
      }
      throw AppException(_friendlyMessage(e) ?? fallback);
    }
  }

  /// Plain-language messages for the errors users are likely to hit.
  String? _friendlyMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'validation_failed':
        return 'Please enter a valid email address.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists.';
      case 'weak_password':
        return 'That password does not meet the requirements.';
      case 'same_password':
        return 'Choose a password you have not used before.';
      case 'otp_expired':
        return 'That code is wrong or has expired. Request a new one.';
      case 'email_not_confirmed':
        return 'Please confirm your email address first.';
      case 'over_email_send_rate_limit':
        return 'Please wait a minute before requesting another code.';
      case 'over_request_rate_limit':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'signup_disabled':
        return 'Sign-ups are currently disabled.';
      default:
        return null;
    }
  }
}
