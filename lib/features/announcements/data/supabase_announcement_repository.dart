import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/errors/database_errors.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';

const _columns =
    'id, title, body, created_at, announcement_categories(category_id)';

Announcement announcementFromRow(Map<String, dynamic> row) {
  final links = row['announcement_categories'] as List<dynamic>? ?? const [];
  return Announcement(
    id: row['id'] as String,
    title: row['title'] as String? ?? '',
    body: row['body'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    categories: [
      for (final link in links)
        (link as Map<String, dynamic>)['category_id'] as String,
    ],
  );
}

class SupabaseAnnouncementRepository implements AnnouncementRepository {
  SupabaseAnnouncementRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Announcement>> fetchAll() {
    return guardDb(() async {
      final rows = await _client
          .from('announcements')
          .select(_columns)
          .order('created_at', ascending: false);
      return rows.map(announcementFromRow).toList();
    });
  }

  @override
  Future<void> save(Announcement announcement) {
    return guardDb(() async {
      await _client.rpc<dynamic>(
        'save_announcement',
        params: {
          'p_id': announcement.id.isEmpty ? null : announcement.id,
          'p_title': announcement.title,
          'p_body': announcement.body,
          'p_category_ids': announcement.categories,
        },
      );
    });
  }

  @override
  Future<void> delete(String id) {
    return guardDb(() async {
      final deleted = await _client
          .from('announcements')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw const AppException('You do not have permission to do that.');
      }
    });
  }
}
