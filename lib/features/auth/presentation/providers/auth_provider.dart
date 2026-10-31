import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/core/services/firestore_service.dart';

/// Simple ChangeNotifier for authentication state.
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseAuth.currentUser != null;

  AuthProvider() {
    // Listen to auth changes.
    _firebaseAuth.authStateChanges().listen((user) async {
      if (user == null) {
        _currentUser = null;
      } else {
        _currentUser =
            await _firestoreService.fetchUserProfile(user.uid, user.email ?? '');
      }
      notifyListeners();
    });
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
    String role,
  ) async {
    _setLoading(true);
    try {
      _errorMessage = null;
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      _currentUser = AppUser(
        id: user.uid,
        email: user.email ?? email,
        displayName: displayName,
        role: role,
      );
      await _firestoreService.saveUserProfile(_currentUser!);
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Registration failed';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _errorMessage = null;
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // After sign in, verify suspension status from Firestore.
      final fbUser = cred.user;
      if (fbUser != null) {
        final profile = await _firestoreService.fetchUserProfile(
          fbUser.uid,
          fbUser.email ?? email,
        );
        if (profile.isSuspended) {
          await _firebaseAuth.signOut();
          _errorMessage =
              'Your account has been suspended due to suspicious activity. If you believe this is a mistake, please contact support.';
        }
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Login failed';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  Future<void> updateProfile({String? displayName}) async {
    if (_firebaseAuth.currentUser == null) return;
    _setLoading(true);
    try {
      final user = _firebaseAuth.currentUser!;
      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      final updated = AppUser(
        id: user.uid,
        email: user.email ?? _currentUser?.email ?? '',
        displayName: displayName ?? _currentUser?.displayName,
        role: _currentUser?.role ?? 'student',
        isSuspended: _currentUser?.isSuspended ?? false,
      );
      await _firestoreService.saveUserProfile(updated);
      _currentUser = updated;
      _errorMessage = null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update profile';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


