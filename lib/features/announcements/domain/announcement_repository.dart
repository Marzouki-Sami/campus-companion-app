import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';

abstract interface class AnnouncementRepository {
  /// Newest first.
  Future<List<Announcement>> fetchAll();

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
