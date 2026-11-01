import 'package:campus_companion/core/offline/cached_fetch.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';
import 'package:campus_companion/features/announcements/data/announcement_json.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';

/// Wraps another repository and keeps an offline copy of what the home and
/// News screens show first: the newest page, upcoming events and read state.
/// Later pages and every change need a connection.
class CachingAnnouncementRepository implements AnnouncementRepository {
  CachingAnnouncementRepository(this._inner, this._cache, this._offline);

  final AnnouncementRepository _inner;
  final LocalCache _cache;
  final OfflineState _offline;

  @override
  Future<List<Announcement>> fetchPage({
    required int offset,
    required int limit,
  }) {
    Future<List<Announcement>> fetch() =>
        _inner.fetchPage(offset: offset, limit: limit);
    if (offset != 0) return fetch();
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'announcements.first',
      fetch: fetch,
      encode: announcementsToJson,
      decode: announcementsFromJson,
    );
  }

  @override
  Future<List<Announcement>> fetchUpcomingEvents({
    required DateTime now,
    int limit = 5,
  }) {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'announcements.events',
      fetch: () => _inner.fetchUpcomingEvents(now: now, limit: limit),
      encode: announcementsToJson,
      decode: announcementsFromJson,
    );
  }

  @override
  Future<int> fetchUnreadCount() {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'announcements.unread',
      fetch: _inner.fetchUnreadCount,
      encode: (count) => count,
      decode: (json) => json as int,
    );
  }

  @override
  Future<int> fetchTotalCount() {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'announcements.total',
      fetch: _inner.fetchTotalCount,
      encode: (count) => count,
      decode: (json) => json as int,
    );
  }

  @override
  Future<Set<String>> fetchReadIds() {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'announcements.reads',
      fetch: _inner.fetchReadIds,
      encode: (ids) => ids.toList(),
      decode: (json) => {...(json as List<dynamic>).cast<String>()},
    );
  }

  @override
  Future<void> save(
    Announcement announcement, {
    List<NewImage> newImages = const [],
  }) =>
      _inner.save(announcement, newImages: newImages);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<void> markRead(Iterable<String> ids) => _inner.markRead(ids);

  @override
  Future<void> markAllRead() => _inner.markAllRead();
}
