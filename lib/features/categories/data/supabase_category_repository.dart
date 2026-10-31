import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/errors/database_errors.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';
import 'package:campus_companion/features/categories/domain/category_repository.dart';

AnnouncementCategory categoryFromRow(Map<String, dynamic> row) {
  return AnnouncementCategory(
    id: row['id'] as String,
    name: row['name'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AnnouncementCategory>> fetchAll() {
    return guardDb(() async {
      final rows = await _client
          .from('categories')
          .select()
          .order('name', ascending: true);
      return rows.map(categoryFromRow).toList();
    });
  }

  @override
  Future<void> save(AnnouncementCategory category) {
    return guardDb(() async {
      try {
        if (category.id.isEmpty) {
          await _client.from('categories').insert({'name': category.name});
          return;
        }
        final updated = await _client
            .from('categories')
            .update({'name': category.name})
            .eq('id', category.id)
            .select('id');
        if (updated.isEmpty) {
          throw const AppException('You do not have permission to do that.');
        }
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw const AppException(
            'A category with this name already exists.',
          );
        }
        rethrow;
      }
    });
  }

  @override
  Future<void> delete(String id) {
    return guardDb(() async {
      final deleted =
          await _client.from('categories').delete().eq('id', id).select('id');
      if (deleted.isEmpty) {
        throw const AppException('You do not have permission to do that.');
      }
    });
  }
}
