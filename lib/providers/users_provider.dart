import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/firestore_service.dart';

class UsersProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<AppUser> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AppUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _setLoading(true);
    try {
      _users = await _firestoreService.fetchAllUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load users';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUser(AppUser user) async {
    _setLoading(true);
    try {
      await _firestoreService.saveUserProfile(user);
      await loadUsers();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to update user';
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
