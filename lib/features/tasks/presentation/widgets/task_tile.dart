import 'package:flutter/material.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onDelete,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final overdue = task.isOverdue;
    final due = task.dueDate;

    return Card(
      margin: margin,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 8, right: 4),
        onTap: onTap,
        leading: Checkbox(
          value: task.isDone,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
        ),
        title: Text(
          task.title,
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? scheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: (task.description == null && due == null)
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null) Text(task.description!),
                  if (due != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            overdue ? Icons.error_outline : Icons.event,
                            size: 16,
                            color: overdue ? scheme.error : scheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.isDone ? formatDate(due) : formatDue(due),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: overdue
                                  ? scheme.error
                                  : scheme.onSurfaceVariant,
                              fontWeight:
                                  overdue ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'Delete task',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
      ),
    );
  }
}
