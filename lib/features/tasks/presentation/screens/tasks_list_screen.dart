import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/empty_state.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_filter.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import 'package:campus_companion/features/tasks/presentation/screens/task_edit_screen.dart';
import 'package:campus_companion/features/tasks/presentation/widgets/task_tile.dart';

class TasksListScreen extends StatefulWidget {
  static const routeName = '/tasks';

  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  TaskStatusFilter _status = TaskStatusFilter.all;
  bool _onlyOverdue = false;
  String _query = '';

  Future<void> _confirmDelete(String userId, Task task) async {
    final provider = context.read<TaskProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await provider.deleteTask(userId, task);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthProvider, String?>(
      (a) => a.currentUser?.id,
    );
    final provider = context.watch<TaskProvider>();

    if (userId == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Please sign in to see your tasks',
        ),
      );
    }

    final tasks = applyTaskFilter(
      provider.tasks,
      status: _status,
      onlyOverdue: _onlyOverdue,
      query: _query,
    );
    final hasFilters =
        _status != TaskStatusFilter.all || _onlyOverdue || _query.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(
          context,
          TaskEditScreen.routeName,
          arguments: TaskEditArgs(task: null),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search tasks',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SegmentedButton<TaskStatusFilter>(
                  showSelectedIcon: false,
                  segments: [
                    for (final s in TaskStatusFilter.values)
                      ButtonSegment(value: s, label: Text(s.label)),
                  ],
                  selected: {_status},
                  onSelectionChanged: (v) => setState(() => _status = v.first),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Overdue'),
                  selected: _onlyOverdue,
                  onSelected: (v) => setState(() => _onlyOverdue = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadTasks(userId),
              child: _buildBody(provider, userId, tasks, hasFilters),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    TaskProvider provider,
    String userId,
    List<Task> tasks,
    bool hasFilters,
  ) {
    if (provider.isLoading && provider.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (tasks.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: EmptyState(
              icon: hasFilters ? Icons.search_off : Icons.task_alt,
              title: hasFilters ? 'No matching tasks' : 'No tasks yet',
              message: hasFilters
                  ? 'Try a different search or clear the filters.'
                  : 'Tap "New task" to add your first one.',
              action: hasFilters
                  ? TextButton(
                      onPressed: () => setState(() {
                        _status = TaskStatusFilter.all;
                        _onlyOverdue = false;
                        _query = '';
                      }),
                      child: const Text('Clear filters'),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskTile(
          task: task,
          onToggle: () => provider.addOrUpdateTask(
            userId,
            task.copyWith(isDone: !task.isDone),
          ),
          onTap: () => Navigator.pushNamed(
            context,
            TaskEditScreen.routeName,
            arguments: TaskEditArgs(task: task),
          ),
          onDelete: () => _confirmDelete(userId, task),
        );
      },
    );
  }
}
