import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/announcement.dart';
import '../models/category.dart' show AnnouncementCategory;
import '../providers/announcement_provider.dart';
import '../providers/category_provider.dart';

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
  String _title = '';
  String _body = '';
  List<String> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    final a = widget.args?.announcement;
    if (a != null) {
      _title = a.title;
      _body = a.body;
      _selectedCategoryIds = List.from(a.categories);
    }
    // Load categories if not already loaded
    context.read<CategoryProvider>().loadCategories();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final provider = context.read<AnnouncementProvider>();
    
    final existing = widget.args?.announcement;
    final announcement = existing?.copyWith(
          title: _title,
          body: _body,
          categories: _selectedCategoryIds,
        ) ??
        Announcement(
          id: '',
          title: _title,
          body: _body,
          createdAt: DateTime.now(),
          categories: _selectedCategoryIds,
        );

    await provider.addOrUpdateAnnouncement(announcement);
    if (mounted) {
      if (provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add / Edit Announcement')),
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
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _body,
                  decoration: const InputDecoration(labelText: 'Body'),
                  onSaved: (v) => _body = v ?? '',
                  maxLines: 5,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please enter announcement body' : null,
                ),
                const SizedBox(height: 16),
                // Category selection (multi-select)
                const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (categoryProvider.isLoading)
                  const CircularProgressIndicator()
                else if (categoryProvider.categories.isEmpty)
                  const Text('No categories available. Admin must create categories first.',
                      style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryProvider.categories.map<Widget>((category) {
                      final isSelected = _selectedCategoryIds.contains(category.id);
                      return FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                      );
                    }).toList(),
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
