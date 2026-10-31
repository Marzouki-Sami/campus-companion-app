import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';

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
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    final t = widget.args?.task;
    if (t != null) {
      _title = t.title;
      _description = t.description ?? '';
      _dueDate = t.dueDate;
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
        .copyWith(title: _title, description: _description, dueDate: _dueDate);

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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _dueDate = date);
                    }
                  },
                  label: Text(
                    _dueDate != null
                        ? 'Due Date: ${_dueDate!.toLocal().toString().split(' ')[0]}'
                        : 'Set Due Date',
                  ),
                ),
                if (_dueDate != null)
                  TextButton(
                    onPressed: () => setState(() => _dueDate = null),
                    child: const Text('Clear Due Date'),
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
