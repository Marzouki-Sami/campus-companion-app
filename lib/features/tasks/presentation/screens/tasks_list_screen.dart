import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/presentation/screens/task_edit_screen.dart';

class TasksListScreen extends StatefulWidget {
  static const routeName = '/tasks';

  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  bool? _filterByDone;
  bool? _filterByOverdue;
  String _searchQuery = '';
  bool _searchStartsWith = true;

  List<Task> _getFilteredTasks(List<Task> all) {
    var filtered = List<Task>.from(all);

    if (_filterByDone != null) {
      filtered = filtered.where((t) => t.isDone == _filterByDone).toList();
    }

    if (_filterByOverdue != null) {
      filtered = filtered.where((t) => t.isOverdue == _filterByOverdue).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        final title = t.title.toLowerCase();
        return _searchStartsWith ? title.startsWith(query) : title.contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<TaskProvider>();
    final userId = auth.currentUser?.id;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to see tasks.')),
      );
    }

    final filteredTasks = _getFilteredTasks(provider.tasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('No tasks found.'),
                            if (_filterByDone != null || _filterByOverdue != null || _searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _filterByDone = null;
                                    _filterByOverdue = null;
                                    _searchQuery = '';
                                  });
                                },
                                child: const Text('Clear Filters'),
                              ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          if (_filterByDone != null || _filterByOverdue != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.grey.shade200,
                              child: Wrap(
                                spacing: 8,
                                children: [
                                  if (_filterByDone != null)
                                    Chip(
                                      label: Text(_filterByDone! ? 'Done' : 'Not Done'),
                                      onDeleted: () => setState(() => _filterByDone = null),
                                    ),
                                  if (_filterByOverdue != null)
                                    Chip(
                                      label: Text(_filterByOverdue! ? 'Overdue' : 'On Time'),
                                      onDeleted: () => setState(() => _filterByOverdue = null),
                                    ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final t = filteredTasks[index];
                                final isOverdue = t.isOverdue;
                                return ListTile(
                                  leading: Checkbox(
                                    value: t.isDone,
                                    onChanged: (_) {
                                      final updated = t.copyWith(isDone: !t.isDone);
                                      provider.addOrUpdateTask(userId, updated);
                                    },
                                  ),
                                  title: Text(
                                    t.title,
                                    style: TextStyle(
                                      color: isOverdue ? Colors.red : Colors.black,
                                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (t.description != null) Text(t.description!),
                                      if (t.dueDate != null)
                                        Text(
                                          'Due: ${t.dueDate!.toLocal().toString().split(' ')[0]}',
                                          style: TextStyle(
                                            color: isOverdue ? Colors.red : Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
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
                          ),
                        ],
                      ),
          ),
        ],
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

  void _showFilters(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<bool?>( initialValue: _filterByDone,
                decoration: const InputDecoration(labelText: 'Filter by Status'),
                items: const [
                  DropdownMenuItem<bool?>(value: null, child: Text('All Tasks')),
                  DropdownMenuItem<bool?>(value: false, child: Text('Not Done')),
                  DropdownMenuItem<bool?>(value: true, child: Text('Done')),
                ],
                onChanged: (value) {
                  setState(() => _filterByDone = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Due Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<bool?>( initialValue: _filterByOverdue,
                decoration: const InputDecoration(labelText: 'Filter by Due Date'),
                items: const [
                  DropdownMenuItem<bool?>(value: null, child: Text('All Tasks')),
                  DropdownMenuItem<bool?>(value: false, child: Text('On Time')),
                  DropdownMenuItem<bool?>(value: true, child: Text('Overdue')),
                ],
                onChanged: (value) {
                  setState(() => _filterByOverdue = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Search Type:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<bool>(
                initialValue: _searchStartsWith,
                decoration: const InputDecoration(labelText: 'Search Mode'),
                items: const [
                  DropdownMenuItem<bool>(value: true, child: Text('Starts with')),
                  DropdownMenuItem<bool>(value: false, child: Text('Contains')),
                ],
                onChanged: (value) {
                  setState(() => _searchStartsWith = value ?? true);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterByDone = null;
                _filterByOverdue = null;
                _searchQuery = '';
              });
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
