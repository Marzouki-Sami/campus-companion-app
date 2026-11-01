import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';

/// Converts announcements to and from JSON for the offline copy.
Map<String, Object?> announcementToJson(Announcement a) => {
      'id': a.id,
      'title': a.title,
      'body': a.body,
      'createdAt': a.createdAt.toUtc().toIso8601String(),
      'categories': a.categories,
      'images': [
        for (final image in a.images) {'path': image.path, 'url': image.url},
      ],
      'eventStart': a.eventStart?.toUtc().toIso8601String(),
      'eventEnd': a.eventEnd?.toUtc().toIso8601String(),
      'location': a.location,
      'isPinned': a.isPinned,
    };

Announcement announcementFromJson(Map<String, dynamic> json) {
  DateTime? date(Object? value) =>
      value == null ? null : DateTime.parse(value as String).toLocal();

  return Announcement(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    createdAt: date(json['createdAt'])!,
    categories: [...(json['categories'] as List<dynamic>).cast<String>()],
    images: [
      for (final image in (json['images'] as List<dynamic>))
        AnnouncementImage(
          path: (image as Map<String, dynamic>)['path'] as String,
          url: image['url'] as String,
        ),
    ],
    eventStart: date(json['eventStart']),
    eventEnd: date(json['eventEnd']),
    location: json['location'] as String?,
    isPinned: json['isPinned'] == true,
  );
}

List<Object?> announcementsToJson(List<Announcement> list) =>
    [for (final a in list) announcementToJson(a)];

List<Announcement> announcementsFromJson(Object? json) => [
      for (final item in (json as List<dynamic>))
        announcementFromJson(item as Map<String, dynamic>),
    ];
