import 'package:flutter/material.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/announcement_gallery.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/event_summary.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.categories,
    required this.onTap,
    this.isUnread = false,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final Announcement announcement;
  final List<AnnouncementCategory> categories;
  final VoidCallback onTap;
  final bool isUnread;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final names = [
      for (final id in announcement.categories)
        for (final c in categories)
          if (c.id == id) c.name,
    ];

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (announcement.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 7,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetworkPhoto(
                      url: announcement.images.first.url,
                      cacheWidth: 800,
                    ),
                    if (announcement.images.length > 1)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined,
                                    size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '${announcement.images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUnread)
                        Padding(
                          padding: const EdgeInsets.only(top: 7, right: 8),
                          child: Semantics(
                            label: 'Unread',
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          announcement.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (announcement.isPinned) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.push_pin,
                            size: 16,
                            semanticLabel: 'Pinned',
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        formatRelativeDate(announcement.createdAt),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    announcement.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (announcement.isEvent) ...[
                    const SizedBox(height: 10),
                    EventSummary(announcement: announcement, compact: true),
                  ],
                  if (names.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final name in names)
                          Chip(
                            label: Text(name),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                            backgroundColor: scheme.secondaryContainer,
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
