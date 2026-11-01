const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats a date as `31 Oct 2026`.
String formatDate(DateTime date) {
  final d = date.toLocal();
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

/// Short relative description such as `Today`, `Yesterday` or `3 days ago`,
/// falling back to [formatDate] for older dates.
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;

  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff > 1 && diff < 7) return '$diff days ago';
  return formatDate(date);
}

/// Describes a due date relative to now, e.g. `Due today` or `3 days overdue`.
String formatDue(DateTime due, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final day = DateTime(due.year, due.month, due.day);
  final diff = day.difference(today).inDays;

  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  if (diff > 1) return 'Due ${formatDate(due)}';
  if (diff == -1) return '1 day overdue';
  return '${-diff} days overdue';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _two(int n) => n.toString().padLeft(2, '0');

/// Formats a time as `14:05`.
String formatTime(DateTime date) {
  final d = date.toLocal();
  return '${_two(d.hour)}:${_two(d.minute)}';
}

/// Formats a date with its weekday, e.g. `Sat 8 Nov`.
String formatWeekdayDate(DateTime date) {
  final d = date.toLocal();
  return '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

/// Describes when an event happens, e.g. Sat 8 Nov, 14:00 to 16:00.
String formatEventWhen(DateTime start, DateTime? end) {
  final s = start.toLocal();
  final e = end?.toLocal();
  final first = '${formatWeekdayDate(s)} \u00B7 ${formatTime(s)}';
  if (e == null) return first;
  final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
  if (sameDay) return '$first\u2013${formatTime(e)}';
  return '$first \u2013 ${formatWeekdayDate(e)} \u00B7 ${formatTime(e)}';
}
