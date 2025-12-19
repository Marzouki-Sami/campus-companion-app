import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';
import '../models/task.dart';
import 'task_edit_screen.dart';

class TasksListScreen extends StatefulWidget {
  static const routeName = '/tasks';

  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  bool? _filterByDone; // null = all, true = done only, false = not done only
  String? _filterByCategory;

  List<Task> _getFilteredTasks(List<Task> all) {
    var filtered = List<Task>.from(all);

    if (_filterByDone != null) {
      filtered = filtered.where((t) => t.isDone == _filterByDone).toList();
    }

    if (_filterByCategory != null && _filterByCategory!.isNotEmpty) {
      filtered = filtered.where((t) => t.category == _filterByCategory).toList();
    }

    return filtered;
  }

  List<String> _getUniqueCategories(List<Task> tasks) {
    final categories = tasks.map((t) => t.category).toSet().toList();
    categories.sort();
    return categories;
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
    final uniqueCategories = _getUniqueCategories(provider.tasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilters(context, uniqueCategories),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No tasks found.'),
                      if (_filterByDone != null || _filterByCategory != null)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filterByDone = null;
                              _filterByCategory = null;
                            });
                          },
                          child: const Text('Clear Filters'),
                        ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Active filters display
                    if (_filterByDone != null || _filterByCategory != null)
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
                            if (_filterByCategory != null)
                              Chip(
                                label: Text(_filterByCategory!),
                                onDeleted: () => setState(() => _filterByCategory = null),
                              ),
                          ],
                        ),
                      ),
                    // Tasks list
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final t = filteredTasks[index];
                          return ListTile(
                            leading: Checkbox(
                              value: t.isDone,
                              onChanged: (_) {
                                final updated = t.copyWith(isDone: !t.isDone);
                                provider.addOrUpdateTask(userId, updated);
                              },
                            ),
                            title: Text(t.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (t.description != null) Text(t.description!),
                                Text('Category: ${t.category}'),
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

  void _showFilters(BuildContext context, List<String> categories) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Tasks'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Completion status filter
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<bool?>(
                value: _filterByDone,
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
              // Category filter
              const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _filterByCategory,
                decoration: const InputDecoration(labelText: 'Filter by Category'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...categories.map((c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      )),
                ],
                onChanged: (value) {
                  setState(() => _filterByCategory = value);
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
                _filterByCategory = null;
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
