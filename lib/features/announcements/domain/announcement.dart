import 'package:campus_companion/features/announcements/domain/announcement_image.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.categories = const [],
    this.images = const [],
    this.eventStart,
    this.eventEnd,
    this.location,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  /// IDs of the categories this announcement belongs to.
  final List<String> categories;

  /// Photos in display order; the first one is the cover.
  final List<AnnouncementImage> images;

  /// Set when the announcement describes an event. [eventEnd] and [location]
  /// are optional details of it.
  final DateTime? eventStart;
  final DateTime? eventEnd;
  final String? location;

  bool get isEvent => eventStart != null;

  /// The moment the event stops being relevant: its end, or its start.
  DateTime? get eventOver => eventEnd ?? eventStart;

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    List<String>? categories,
    List<AnnouncementImage>? images,
    DateTime? eventStart,
    DateTime? eventEnd,
    String? location,
    bool clearEvent = false,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      categories: categories ?? this.categories,
      images: images ?? this.images,
      eventStart: clearEvent ? null : eventStart ?? this.eventStart,
      eventEnd: clearEvent ? null : eventEnd ?? this.eventEnd,
      location: clearEvent ? null : location ?? this.location,
    );
  }
}
