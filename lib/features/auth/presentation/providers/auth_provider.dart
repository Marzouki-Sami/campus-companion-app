import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';

class AuthProvider extends ChangeNotifier with LoadingStateMixin {
  AuthProvider(this._repository) {
    _subscription = _repository.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _repository.isSignedIn;

  Future<bool> login(String email, String password) {
    return runGuarded(() async {
      _currentUser = await _repository.signIn(email: email, password: password);
    }, failureMessage: 'Login failed');
  }

  Future<bool> register(String email, String password, String displayName) {
    return runGuarded(() async {
      _currentUser = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
    }, failureMessage: 'Registration failed');
  }

  Future<void> logout() => _repository.signOut();

  String? _sessionEndedMessage;

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
    } on AccountSuspendedException catch (e) {
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
