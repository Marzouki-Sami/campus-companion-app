import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final List<String> categories; // List of category IDs

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.categories = const [],
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> data) {
    final dynamic raw = data['createdAt'];
    DateTime createdAt;
    if (raw is Timestamp) {
      createdAt = raw.toDate();
    } else if (raw is DateTime) {
      createdAt = raw;
    } else if (raw is String) {
      createdAt = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return Announcement(
      id: id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: createdAt,
      categories: (data['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
      'categories': categories,
    };
  }

  Announcement copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    List<String>? categories,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      categories: categories ?? this.categories,
    );
  }
}


