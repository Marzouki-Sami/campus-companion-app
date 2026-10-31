import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/core/widgets/empty_state.dart';
import 'package:campus_companion/core/widgets/text_input_dialog.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CategoryProvider>().loadCategories();
    });
  }

  Future<void> _add() async {
    final provider = context.read<CategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final name = await showTextInputDialog(
      context,
      title: 'New category',
      label: 'Name',
      confirmLabel: 'Add',
      hint: 'e.g. Exams, Events, Campus life',
    );
    if (name == null || name.isEmpty) return;
    final exists = provider.categories.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      messenger.showSnackBar(
        SnackBar(content: Text('A category named "$name" already exists.')),
      );
      return;
    }
    await provider.addOrUpdateCategory(
      AnnouncementCategory(id: '', name: name, createdAt: DateTime.now()),
    );
  }

  Future<void> _delete(AnnouncementCategory category) async {
    final provider = context.read<CategoryProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('"${category.name}" will be removed.'),
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
    if (confirmed == true) await provider.deleteCategory(category.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final needle = _query.trim().toLowerCase();
    final categories = provider.categories
        .where((c) => needle.isEmpty || c.name.toLowerCase().contains(needle))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search categories',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Add category',
                onPressed: _add,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading && provider.categories.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : categories.isEmpty
                  ? EmptyState(
                      icon: Icons.label_outline,
                      title: needle.isEmpty
                          ? 'No categories yet'
                          : 'No categories found',
                      message: needle.isEmpty
                          ? 'Categories help people filter announcements.'
                          : null,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final c = categories[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.label_outline),
                            title: Text(c.name),
                            subtitle:
                                Text('Created ${formatDate(c.createdAt)}'),
                            trailing: IconButton(
                              tooltip: 'Delete category',
                              icon: Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _delete(c),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
