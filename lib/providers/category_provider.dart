import 'package:flutter/foundation.dart';

import '../models/category.dart';
import '../services/firestore_service.dart';

/// Manages categories (admin only).
class CategoryProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<AnnouncementCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AnnouncementCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _setLoading(true);
    try {
      _categories = await _firestoreService.fetchCategories();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load categories';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addOrUpdateCategory(AnnouncementCategory category) async {
    _setLoading(true);
    try {
      await _firestoreService.saveCategory(category);
      await loadCategories(); // Reload to get updated list
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to save category';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteCategory(categoryId);
      await loadCategories(); // Reload to get updated list
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to delete category';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}

