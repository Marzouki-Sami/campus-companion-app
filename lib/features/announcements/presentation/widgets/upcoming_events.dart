import 'package:flutter/material.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';

/// The next few events as a horizontally scrolling strip of cards.
class UpcomingEvents extends StatelessWidget {
  const UpcomingEvents({
    super.key,
    required this.events,
    required this.onOpen,
  });

  final List<Announcement> events;
  final ValueChanged<Announcement> onOpen;

  /// Events that have not finished yet, soonest first.
  static List<Announcement> upcoming(
    List<Announcement> all, {
    required DateTime now,
    int limit = 5,
  }) {
    final events = all
        .where((a) => a.isEvent && !a.eventOver!.isBefore(now))
        .toList()
      ..sort((a, b) => a.eventStart!.compareTo(b.eventStart!));
    return events.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Let the next card peek past the page padding, up to the screen edge.
        clipBehavior: Clip.none,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _EventCard(
          event: events[i],
          onTap: () => onOpen(events[i]),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final Announcement event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = event.eventStart!.toLocal();
    final place = event.location;

    return SizedBox(
      width: 280,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 56,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${start.day}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        formatWeekdayDate(start).split(' ').last.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimaryContainer,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatWeekdayDate(start).split(' ').first} · '
                        '${formatTime(start)}'
                        '${place != null && place.isNotEmpty ? ' · $place' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
