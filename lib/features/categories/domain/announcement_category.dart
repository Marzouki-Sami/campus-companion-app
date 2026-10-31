class AnnouncementCategory {
  const AnnouncementCategory({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;

  AnnouncementCategory copyWith({String? id, String? name, DateTime? createdAt}) {
    return AnnouncementCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
