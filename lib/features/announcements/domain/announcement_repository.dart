import 'package:campus_companion/features/announcements/domain/announcement.dart';

abstract interface class AnnouncementRepository {
  /// Newest first.
  Future<List<Announcement>> fetchAll();

  /// Creates the announcement when [Announcement.id] is empty, otherwise updates it.
  Future<void> save(Announcement announcement);

  Future<void> delete(String id);
}
