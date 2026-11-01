import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/errors/database_errors.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';

const imagesBucket = 'announcement-images';

const _columns =
    'id, title, body, created_at, event_start, event_end, location, is_pinned, '
    'announcement_categories(category_id), announcement_images(path, position)';

Announcement announcementFromRow(
  Map<String, dynamic> row, {
  String Function(String path)? imageUrl,
}) {
  final links = row['announcement_categories'] as List<dynamic>? ?? const [];
  final imageRows = [
    ...(row['announcement_images'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>(),
  ]..sort((a, b) => (a['position'] as int).compareTo(b['position'] as int));

  return Announcement(
    id: row['id'] as String,
    title: row['title'] as String? ?? '',
    body: row['body'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    categories: [
      for (final link in links)
        (link as Map<String, dynamic>)['category_id'] as String,
    ],
    eventStart: _parseDate(row['event_start']),
    eventEnd: _parseDate(row['event_end']),
    location: row['location'] as String?,
    isPinned: row['is_pinned'] == true,
    images: [
      for (final image in imageRows)
        AnnouncementImage(
          path: image['path'] as String,
          url: imageUrl?.call(image['path'] as String) ??
              image['path'] as String,
        ),
    ],
  );
}

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String).toLocal();

class SupabaseAnnouncementRepository implements AnnouncementRepository {
  SupabaseAnnouncementRepository(this._client);

  final SupabaseClient _client;

  StorageFileApi get _storage => _client.storage.from(imagesBucket);

  @override
  Future<List<Announcement>> fetchPage({
    required int offset,
    required int limit,
  }) {
    return guardDb(() async {
      final rows = await _client
          .from('announcements')
          .select(_columns)
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return [
        for (final row in rows)
          announcementFromRow(row, imageUrl: _storage.getPublicUrl),
      ];
    });
  }

  @override
  Future<List<Announcement>> fetchUpcomingEvents({
    required DateTime now,
    int limit = 5,
  }) {
    final cutoff = now.toUtc().toIso8601String();
    return guardDb(() async {
      final rows = await _client
          .from('announcements')
          .select(_columns)
          .not('event_start', 'is', null)
          .or('event_end.gte.$cutoff,and(event_end.is.null,event_start.gte.$cutoff)')
          .order('event_start', ascending: true)
          .limit(limit);
      return [
        for (final row in rows)
          announcementFromRow(row, imageUrl: _storage.getPublicUrl),
      ];
    });
  }

  @override
  Future<int> fetchUnreadCount() {
    return guardDb(() async {
      final count = await _client.rpc<int>('unread_announcement_count');
      return count;
    });
  }

  @override
  Future<int> fetchTotalCount() {
    return guardDb(
        () => _client.from('announcements').count(CountOption.exact));
  }

  @override
  Future<void> markAllRead() {
    return guardDb(() async {
      await _client.rpc<dynamic>('mark_all_announcements_read');
    });
  }

  @override
  Future<void> save(
    Announcement announcement, {
    List<NewImage> newImages = const [],
  }) {
    return guardDb(() async {
      final id = await _client.rpc<String>(
        'save_announcement',
        params: {
          'p_id': announcement.id.isEmpty ? null : announcement.id,
          'p_title': announcement.title,
          'p_body': announcement.body,
          'p_category_ids': announcement.categories,
          'p_event_start': announcement.eventStart?.toUtc().toIso8601String(),
          'p_event_end': announcement.eventEnd?.toUtc().toIso8601String(),
          'p_location': announcement.location,
          'p_pinned': announcement.isPinned,
        },
      );
      await _syncImages(id, announcement.images, newImages);
    });
  }

  Future<void> _syncImages(
    String id,
    List<AnnouncementImage> keep,
    List<NewImage> added,
  ) async {
    final keptPaths = [for (final image in keep) image.path];
    final stored = await _client
        .from('announcement_images')
        .select('path')
        .eq('announcement_id', id);
    final removed = [
      for (final row in stored)
        if (!keptPaths.contains(row['path'])) row['path'] as String,
    ];

    if (removed.isNotEmpty) {
      await _client
          .from('announcement_images')
          .delete()
          .inFilter('path', removed);
      await _removeFiles(removed);
    }

    for (var i = 0; i < keptPaths.length; i++) {
      await _client
          .from('announcement_images')
          .update({'position': i}).eq('path', keptPaths[i]);
    }

    for (var i = 0; i < added.length; i++) {
      final path = '$id/${_uniqueName(added[i].name)}';
      await _storage.uploadBinary(
        path,
        added[i].bytes,
        fileOptions: FileOptions(contentType: _contentType(path)),
      );
      try {
        await _client.from('announcement_images').insert({
          'announcement_id': id,
          'path': path,
          'position': keptPaths.length + i,
        });
      } catch (_) {
        await _removeFiles([path]);
        rethrow;
      }
    }
  }

  @override
  Future<void> delete(String id) {
    return guardDb(() async {
      final stored = await _client
          .from('announcement_images')
          .select('path')
          .eq('announcement_id', id);
      final deleted = await _client
          .from('announcements')
          .delete()
          .eq('id', id)
          .select('id');
      if (deleted.isEmpty) {
        throw const AppException('You do not have permission to do that.');
      }
      await _removeFiles([for (final row in stored) row['path'] as String]);
    });
  }

  @override
  Future<Set<String>> fetchReadIds() {
    return guardDb(() async {
      final rows =
          await _client.from('announcement_reads').select('announcement_id');
      return {for (final row in rows) row['announcement_id'] as String};
    });
  }

  @override
  Future<void> markRead(Iterable<String> ids) {
    return guardDb(() async {
      final rows = [
        for (final id in ids) {'announcement_id': id}
      ];
      if (rows.isEmpty) return;
      await _client.from('announcement_reads').upsert(rows,
          onConflict: 'user_id,announcement_id', ignoreDuplicates: true);
    });
  }

  /// Photos are cosmetic: a leftover file must never fail the user's action.
  Future<void> _removeFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _storage.remove(paths);
    } catch (_) {}
  }
}

final _random = Random.secure();

String _uniqueName(String original) {
  final suffix = List.generate(
    12,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  final dot = original.lastIndexOf('.');
  final extension = dot < 0 ? 'jpg' : original.substring(dot + 1).toLowerCase();
  const allowed = {'jpg', 'jpeg', 'png', 'webp'};
  return '$suffix.${allowed.contains(extension) ? extension : 'jpg'}';
}

String _contentType(String path) {
  final extension = path.substring(path.lastIndexOf('.') + 1);
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
