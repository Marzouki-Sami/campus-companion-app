import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart';
import 'task_edit_screen.dart';

class TasksListScreen extends StatelessWidget {
  static const routeName = '/tasks';

  const TasksListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<TaskProvider>();
    final userId = auth.currentUser?.id;

    if (userId == null) {
      return const Center(child: Text('Please login to see tasks.'));
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Task> tasks = provider.tasks;
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks yet. Add one!'));
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final t = tasks[index];
          return ListTile(
            leading: Checkbox(
              value: t.isDone,
              onChanged: (_) {
                final updated = t.copyWith(isDone: !t.isDone);
                provider.addOrUpdateTask(userId, updated);
              },
            ),
            title: Text(t.title),
            subtitle: Text(t.category),
            onTap: () {
              Navigator.pushNamed(
                context,
                TaskEditScreen.routeName,
                arguments: TaskEditArgs(task: t),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => provider.deleteTask(userId, t),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            TaskEditScreen.routeName,
            arguments: TaskEditArgs(task: null),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


