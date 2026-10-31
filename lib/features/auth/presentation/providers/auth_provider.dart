import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/auth/domain/password_breach_checker.dart';
import 'package:campus_companion/features/auth/domain/password_policy.dart';

class AuthProvider extends ChangeNotifier with LoadingStateMixin {
  AuthProvider(
    this._repository, {
    PasswordBreachChecker passwordBreachChecker = const NoPasswordBreachCheck(),
  }) : _breachChecker = passwordBreachChecker {
    _subscription = _repository.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  final PasswordBreachChecker _breachChecker;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _currentUser;
  String? _pendingVerificationEmail;
  String? _sessionEndedMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _repository.isSignedIn;

  /// The address a verification code was sent to, while sign-up or sign-in is
  /// waiting for it.
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  Future<bool> login(String email, String password) {
    return runGuarded(() async {
      try {
        _currentUser = await _repository.signIn(
          email: email,
          password: password,
        );
        _pendingVerificationEmail = null;
      } on EmailNotVerifiedException catch (e) {
        _pendingVerificationEmail = e.email;
        // A fresh code is sent so people are never stuck without one.
        await _repository.resendVerification(e.email).catchError((_) {});
        rethrow;
      }
    }, failureMessage: 'Login failed');
  }

  Future<bool> register(String email, String password, String displayName) {
    return runGuarded(() async {
      await _checkNewPassword(password);
      final user = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = user;
      _pendingVerificationEmail = user == null ? email : null;
    }, failureMessage: 'Registration failed');
  }

  Future<bool> verifyEmail(String email, String code) {
    return runGuarded(() async {
      _currentUser = await _repository.verifyEmail(email: email, code: code);
      _pendingVerificationEmail = null;
    }, failureMessage: 'Verification failed');
  }

  Future<bool> resendVerification(String email) {
    return runGuarded(
      () => _repository.resendVerification(email),
      failureMessage: 'Could not send a new code',
    );
  }

  Future<bool> requestPasswordReset(String email) {
    return runGuarded(
      () => _repository.requestPasswordReset(email),
      failureMessage: 'Could not send a reset code',
    );
  }

  Future<bool> resetPassword(String email, String code, String newPassword) {
    return runGuarded(() async {
      await _checkNewPassword(newPassword);
      _currentUser = await _repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
    }, failureMessage: 'Could not reset the password');
  }

  /// Local rules first (instant), then the known-breach list.
  Future<void> _checkNewPassword(String password) async {
    final problem = PasswordPolicy.validate(password);
    if (problem != null) throw AppException(problem);
    if (await _breachChecker.isBreached(password)) {
      throw const AppException(
        'This password has appeared in a known data breach. '
        'Please choose a different one.',
      );
    }
  }

  void clearPendingVerification() {
    _pendingVerificationEmail = null;
    notifyListeners();
  }

  Future<void> logout() => _repository.signOut();

  /// Why the session was ended without the user asking (for example a
  /// suspension). Returns the message once, then clears it.
  String? takeSessionEndedMessage() {
    final message = _sessionEndedMessage;
    _sessionEndedMessage = null;
    return message;
  }

  /// Re-checks the account, e.g. when the app returns to the foreground.
  /// Transient failures (such as being offline) leave the current user as is.
  Future<void> refreshProfile() async {
    if (!_repository.isSignedIn || _currentUser == null) return;
    try {
      _currentUser = await _repository.reloadCurrentUser();
    } on SessionEndedException catch (e) {
      _sessionEndedMessage = e.message;
      _currentUser = null;
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  Future<bool> updateDisplayName(String displayName) {
    final user = _currentUser;
    if (user == null) return Future.value(false);
    return runGuarded(() async {
      _currentUser = await _repository.updateDisplayName(user, displayName);
    }, failureMessage: 'Failed to update profile');
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
