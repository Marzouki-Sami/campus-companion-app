import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';

class AnnouncementEditArgs {
  final Announcement? announcement;
  AnnouncementEditArgs({required this.announcement});
}

class AnnouncementEditScreen extends StatefulWidget {
  static const routeName = '/announcement-edit';

  final AnnouncementEditArgs? args;

  const AnnouncementEditScreen({super.key, this.args});

  @override
  State<AnnouncementEditScreen> createState() => _AnnouncementEditScreenState();
}

class _AnnouncementEditScreenState extends State<AnnouncementEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final Set<String> _selectedCategoryIds;

  Announcement? get _existing => widget.args?.announcement;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: _existing?.title ?? '');
    _body = TextEditingController(text: _existing?.body ?? '');
    _selectedCategoryIds = {...?_existing?.categories};
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AnnouncementProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final existing = _existing;
    final announcement = existing != null
        ? existing.copyWith(
            title: _title.text.trim(),
            body: _body.text.trim(),
            categories: _selectedCategoryIds.toList(),
          )
        : Announcement(
            id: '',
            title: _title.text.trim(),
            body: _body.text.trim(),
            createdAt: DateTime.now(),
            categories: _selectedCategoryIds.toList(),
          );

    final ok = await provider.addOrUpdateAnnouncement(announcement);
    if (ok) {
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save announcement'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading =
        context.select<AnnouncementProvider, bool>((p) => p.isLoading);
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      appBar: AppBar(
        title:
            Text(_existing == null ? 'New announcement' : 'Edit announcement'),
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
                controller: _body,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: 10,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter a message'
                    : null,
              ),
              const SizedBox(height: 24),
              Text('Categories', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                Text(
                  'No categories yet. An admin can create them from the admin dashboard.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in categories)
                      FilterChip(
                        label: Text(c.name),
                        selected: _selectedCategoryIds.contains(c.id),
                        onSelected: (selected) => setState(() {
                          selected
                              ? _selectedCategoryIds.add(c.id)
                              : _selectedCategoryIds.remove(c.id);
                        }),
                      ),
                  ],
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
                    : const Text('Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
