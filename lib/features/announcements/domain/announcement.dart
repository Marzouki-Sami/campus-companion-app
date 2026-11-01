import 'package:campus_companion/features/announcements/domain/announcement_image.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.categories = const [],
    this.images = const [],
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  /// IDs of the categories this announcement belongs to.
  final List<String> categories;

  /// Photos in display order; the first one is the cover.
  final List<AnnouncementImage> images;

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    List<String>? categories,
    List<AnnouncementImage>? images,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      categories: categories ?? this.categories,
      images: images ?? this.images,
    );
  }
}
