import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';

const _offlineMessage = 'No connection. Check your internet and try again.';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client, this._users);

  final SupabaseClient _client;
  final UserRepository _users;

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
    final response = await _guard(
      () => _auth.signInWithPassword(email: email, password: password),
      fallback: 'Login failed',
    );
    final user = response.user;
    if (user == null) throw const AppException('Login failed');

    final profile = await _users.fetchById(user.id);
    if (profile.isSuspended) {
      await _signOutQuietly();
      throw const AccountSuspendedException();
    }
    return profile;
  }

  @override
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _guard(
      () => _auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      ),
      fallback: 'Registration failed',
    );
    final user = response.user;
    if (user == null || response.session == null) {
      throw const AppException('Registration failed');
    }
    return _users.fetchById(user.id);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> reloadCurrentUser() async {
    final id = _auth.currentUser?.id;
    if (id == null) throw const AppException('You are signed out.');
    final profile = await _users.fetchById(id);
    if (profile.isSuspended) {
      await _signOutQuietly();
      throw const AccountSuspendedException();
    }
    return profile;
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
  }) async {
    try {
      return await action();
    } on AuthRetryableFetchException {
      throw const AppException(_offlineMessage);
    } on SocketException {
      throw const AppException(_offlineMessage);
    } on AuthException catch (e) {
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
        return 'Choose a stronger password.';
      case 'email_not_confirmed':
        return 'Please confirm your email address first.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'signup_disabled':
        return 'Sign-ups are currently disabled.';
      default:
        return null;
    }
  }
}
