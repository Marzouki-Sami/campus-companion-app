import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads a Firestore date field that may be stored as a [Timestamp],
/// a [DateTime] or an ISO-8601 string.
DateTime? readDate(Object? raw) {
  return switch (raw) {
    Timestamp t => t.toDate(),
    DateTime d => d,
    String s => DateTime.tryParse(s),
    _ => null,
  };
}
