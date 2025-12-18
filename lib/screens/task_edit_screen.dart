import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/auth_provider.dart';

class TaskEditArgs {
  final Task? task;
  TaskEditArgs({required this.task});
}

class TaskEditScreen extends StatefulWidget {
  static const routeName = '/task-edit';

  final TaskEditArgs? args;

  const TaskEditScreen({super.key, this.args});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _category = 'General';

  @override
  void initState() {
    super.initState();
    final t = widget.args?.task;
    if (t != null) {
      _title = t.title;
      _description = t.description ?? '';
      _category = t.category;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final existing = widget.args?.task;
    final task = (existing ?? Task(id: '', title: _title))
        .copyWith(title: _title, description: _description, category: _category);

    await context.read<TaskProvider>().addOrUpdateTask(userId, task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add / Edit Task')),
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: provider.isLoading ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onSaved: (v) => _title = v ?? '',
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter a title' : null,
                ),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (v) => _description = v ?? '',
                  maxLines: 3,
                ),
                TextFormField(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  onSaved: (v) => _category = v ?? 'General',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.isLoading ? null : _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


