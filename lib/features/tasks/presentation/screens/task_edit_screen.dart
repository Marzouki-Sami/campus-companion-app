import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';

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
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _dueDate;

  Task? get _existing => widget.args?.task;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _existing?.title ?? '');
    _description = TextEditingController(text: _existing?.description ?? '');
    _dueDate = _existing?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final current = _dueDate ?? today;
    final earliest = current.isBefore(today) ? current : today;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(earliest.year, earliest.month, earliest.day),
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
    if (date != null) setState(() => _dueDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    final provider = context.read<TaskProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final description = _description.text.trim();

    final task = Task(
      id: _existing?.id ?? '',
      title: _title.text.trim(),
      description: description.isEmpty ? null : description,
      dueDate: _dueDate,
      isDone: _existing?.isDone ?? false,
    );

    final ok = await provider.addOrUpdateTask(userId, task);
    if (ok) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Failed to save task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<TaskProvider, bool>((p) => p.isLoading);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'New task' : 'Edit task'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: _title,
                autofocus: _existing == null,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due date (optional)',
                    prefixIcon: const Icon(Icons.event),
                    suffixIcon: _dueDate == null
                        ? null
                        : IconButton(
                            tooltip: 'Clear due date',
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _dueDate = null),
                          ),
                  ),
                  child: Text(
                    _dueDate == null ? 'No due date' : formatDate(_dueDate!),
                    style: TextStyle(
                      color: _dueDate == null ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: isLoading ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
