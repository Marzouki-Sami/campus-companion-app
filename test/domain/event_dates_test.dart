import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/core/utils/date_format.dart';

void main() {
  group('event dates', () {
    final start = DateTime(2030, 11, 9, 14); // a Saturday

    test('formatTime pads hours and minutes', () {
      expect(formatTime(DateTime(2030, 1, 1, 7, 5)), '07:05');
    });

    test('formatWeekdayDate includes the weekday', () {
      expect(formatWeekdayDate(start), 'Sat 9 Nov');
    });

    test('an event without an end shows just the start', () {
      expect(formatEventWhen(start, null), 'Sat 9 Nov · 14:00');
    });

    test('an event ending the same day shows a time range', () {
      expect(
        formatEventWhen(start, DateTime(2030, 11, 9, 16, 30)),
        'Sat 9 Nov · 14:00–16:30',
      );
    });

    test('an event ending another day shows both dates', () {
      expect(
        formatEventWhen(start, DateTime(2030, 11, 10, 10)),
        'Sat 9 Nov · 14:00 – Sun 10 Nov · 10:00',
      );
    });
  });
}
