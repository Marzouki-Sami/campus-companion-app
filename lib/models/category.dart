import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementCategory {
  final String id;
  final String name;
  final DateTime createdAt;

  AnnouncementCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory AnnouncementCategory.fromMap(String id, Map<String, dynamic> data) {
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

    return AnnouncementCategory(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AnnouncementCategory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return AnnouncementCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

