import 'package:campus_companion/features/tasks/domain/task.dart';

/// Converts tasks to and from JSON for the offline copy.
List<Object?> tasksToJson(List<Task> tasks) => [
      for (final t in tasks)
        {
          'id': t.id,
          'title': t.title,
          'description': t.description,
          'dueDate': t.dueDate?.toUtc().toIso8601String(),
          'isDone': t.isDone,
          'remindDaysBefore': t.remindDaysBefore,
        },
    ];

List<Task> tasksFromJson(Object? json) => [
      for (final item in (json as List<dynamic>))
        Task(
          id: (item as Map<String, dynamic>)['id'] as String,
          title: item['title'] as String,
          description: item['description'] as String?,
          dueDate: item['dueDate'] == null
              ? null
              : DateTime.parse(item['dueDate'] as String).toLocal(),
          isDone: item['isDone'] == true,
          remindDaysBefore: item['remindDaysBefore'] as int?,
        ),
    ];
