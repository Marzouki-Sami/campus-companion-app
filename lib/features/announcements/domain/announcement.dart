class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.categories = const [],
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  /// IDs of the categories this announcement belongs to.
  final List<String> categories;

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
