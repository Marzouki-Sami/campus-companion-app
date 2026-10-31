import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';
import 'package:campus_companion/features/categories/domain/category_repository.dart';

class CategoryProvider extends ChangeNotifier with LoadingStateMixin {
  CategoryProvider(this._repository);

  final CategoryRepository _repository;

  List<AnnouncementCategory> _categories = const [];
  List<AnnouncementCategory> get categories => _categories;

  Future<bool> loadCategories() {
    return runGuarded(() async {
      _categories = await _repository.fetchAll();
    }, failureMessage: 'Failed to load categories');
  }

  Future<bool> addOrUpdateCategory(AnnouncementCategory category) {
    return runGuarded(() async {
      await _repository.save(category);
      _categories = await _repository.fetchAll();
    }, failureMessage: 'Failed to save category');
  }

  Future<bool> deleteCategory(String categoryId) {
    return runGuarded(() async {
      await _repository.delete(categoryId);
      _categories = await _repository.fetchAll();
    }, failureMessage: 'Failed to delete category');
  }
}
