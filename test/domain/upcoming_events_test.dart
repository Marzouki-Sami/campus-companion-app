import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/upcoming_events.dart';

Announcement _a(String id, {DateTime? start, DateTime? end}) => Announcement(
      id: id,
      title: id,
      body: 'x',
      createdAt: DateTime(2030),
      eventStart: start,
      eventEnd: end,
    );

void main() {
  final now = DateTime(2030, 6, 10, 12);

  test('keeps only events that have not finished, soonest first', () {
    final result = UpcomingEvents.upcoming(
      [
        _a('plain'),
        _a('later', start: DateTime(2030, 6, 20)),
        _a('past', start: DateTime(2030, 6, 1)),
        _a('soon', start: DateTime(2030, 6, 11)),
        _a(
          'running',
          start: DateTime(2030, 6, 10, 9),
          end: DateTime(2030, 6, 10, 18),
        ),
      ],
      now: now,
    );

    expect(result.map((e) => e.id), ['running', 'soon', 'later']);
  });

  test('respects the limit', () {
    final many = [
      for (var i = 1; i <= 8; i++) _a('e$i', start: DateTime(2030, 7, i)),
    ];

    expect(UpcomingEvents.upcoming(many, now: now, limit: 3), hasLength(3));
  });
}
