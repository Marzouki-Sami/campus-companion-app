import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';

abstract interface class AnnouncementRepository {
  /// Pinned first, then newest first. Pages are [offset, offset + limit).
  Future<List<Announcement>> fetchPage({
    required int offset,
    required int limit,
  });

  /// Events that have not finished yet, soonest first.
  Future<List<Announcement>> fetchUpcomingEvents({
    required DateTime now,
    int limit = 5,
  });

  /// How many announcements the signed-in user has not opened, across all pages.
  Future<int> fetchUnreadCount();

  /// How many announcements exist in total.
  Future<int> fetchTotalCount();

  /// Marks every announcement as read.
  Future<void> markAllRead();

  /// Creates the announcement when [Announcement.id] is empty, otherwise updates it.
  ///
  /// [Announcement.images] lists the stored photos to keep, in order; any other
  /// stored photo is removed. [newImages] are uploaded and appended after them.
  Future<void> save(
    Announcement announcement, {
    List<NewImage> newImages = const [],
  });

  Future<void> delete(String id);

  /// Ids of the announcements the signed-in user has already opened.
  Future<Set<String>> fetchReadIds();

  Future<void> markRead(Iterable<String> ids);
}
