import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

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

  Future<void> register(String email, String password, String displayName) async {
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
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Listener will populate _currentUser.
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


