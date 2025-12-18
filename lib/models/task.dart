class Task {
  final String id;
  final String title;
  final String? description;
  final String category;
  final bool isDone;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.category = 'General',
    this.isDone = false,
  });

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      category: data['category'] as String? ?? 'General',
      isDone: data['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'isDone': isDone,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
    );
  }
}


