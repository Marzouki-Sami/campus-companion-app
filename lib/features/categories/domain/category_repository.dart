import 'package:campus_companion/features/categories/domain/announcement_category.dart';

abstract interface class CategoryRepository {
  /// Sorted by name.
  Future<List<AnnouncementCategory>> fetchAll();

  /// Creates the category when [AnnouncementCategory.id] is empty, otherwise updates it.
  Future<void> save(AnnouncementCategory category);

  Future<void> delete(String id);
}
