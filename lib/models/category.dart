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
    return AnnouncementCategory(
      id: id,
      name: data['name'] as String? ?? '',
      createdAt: (data['createdAt'] as DateTime?) ??
          DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt.toIso8601String(),
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

