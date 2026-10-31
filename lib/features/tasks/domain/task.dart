import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isDone;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isDone = false,
  });

  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isDone;

  factory Task.fromMap(String id, Map<String, dynamic> data) {
    final dynamic raw = data['dueDate'];
    DateTime? dueDate;
    if (raw is Timestamp) {
      dueDate = raw.toDate();
    } else if (raw is DateTime) {
      dueDate = raw;
    } else if (raw is String) {
      dueDate = DateTime.tryParse(raw);
    }

    return Task(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      dueDate: dueDate,
      isDone: data['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isDone': isDone,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
    );
  }
}


