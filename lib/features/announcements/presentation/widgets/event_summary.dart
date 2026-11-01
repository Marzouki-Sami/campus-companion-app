import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';

/// When and where an event happens, as one or two icon rows.
class EventSummary extends StatelessWidget {
  const EventSummary({
    super.key,
    required this.announcement,
    this.compact = false,
  });

  final Announcement announcement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = announcement.eventStart;
    if (start == null) return const SizedBox.shrink();

    final style =
        (compact ? theme.textTheme.labelLarge : theme.textTheme.bodyLarge)
            ?.copyWith(
      color: scheme.onSurface,
      fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
    );
    final location = announcement.location;

    Widget row(IconData icon, String text) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: compact ? 18 : 22, color: scheme.primary),
            SizedBox(width: compact ? 8 : 12),
            Expanded(child: Text(text, style: style)),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(
          Icons.event_outlined,
          formatEventWhen(start, announcement.eventEnd),
        ),
        if (location != null && location.isNotEmpty) ...[
          SizedBox(height: compact ? 4 : 10),
          row(Icons.place_outlined, location),
        ],
      ],
    );
  }
}

/// Event details with an "Add to calendar" button, for the detail screen.
class EventPanel extends StatelessWidget {
  const EventPanel({super.key, required this.announcement});

  final Announcement announcement;

  Future<void> _addToCalendar(BuildContext context) async {
    final start = announcement.eventStart!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final opened = await Add2Calendar.addEvent2Cal(
        Event(
          title: announcement.title,
          description: announcement.body,
          location: announcement.location,
          startDate: start,
          endDate: announcement.eventEnd ?? start.add(const Duration(hours: 1)),
        ),
      );
      if (!opened) throw StateError('No calendar app');
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No calendar app could be opened.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventSummary(announcement: announcement),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _addToCalendar(context),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Add to calendar'),
          ),
        ],
      ),
    );
  }
}
