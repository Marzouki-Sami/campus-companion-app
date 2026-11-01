import 'package:campus_companion/features/categories/domain/announcement_category.dart';

/// Converts categories to and from JSON for the offline copy.
List<Object?> categoriesToJson(List<AnnouncementCategory> categories) => [
      for (final c in categories)
        {
          'id': c.id,
          'name': c.name,
          'createdAt': c.createdAt.toUtc().toIso8601String(),
        },
    ];

List<AnnouncementCategory> categoriesFromJson(Object? json) => [
      for (final item in (json as List<dynamic>))
        AnnouncementCategory(
          id: (item as Map<String, dynamic>)['id'] as String,
          name: item['name'] as String,
          createdAt: DateTime.parse(item['createdAt'] as String).toLocal(),
        ),
    ];
