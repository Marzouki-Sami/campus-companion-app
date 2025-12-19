import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/category_provider.dart';
import '../models/category.dart' show AnnouncementCategory;

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({super.key});

  Future<Map<String, int>> _loadStats() async {
    final db = FirebaseFirestore.instance;

    final usersSnap = await db.collection('users').get();
    final announcementsSnap = await db.collection('announcements').get();

    return {
      'users': usersSnap.docs.length,
      'announcements': announcementsSnap.docs.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<Map<String, int>>(
        future: _loadStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading stats: ${snapshot.error}'),
            );
          }
          final data = snapshot.data ?? {'users': 0, 'announcements': 0};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats section
              const Text(
                'Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Total Users'),
                  trailing: Text('${data['users']}'),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: const Text('Total Announcements'),
                  trailing: Text('${data['announcements']}'),
                ),
              ),
              const SizedBox(height: 24),
              // Category management section
              const Text(
                'Category Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const CategoryManagementSection(),
            ],
          );
        },
      ),
    );
  }
}

class CategoryManagementSection extends StatefulWidget {
  const CategoryManagementSection({super.key});

  @override
  State<CategoryManagementSection> createState() => _CategoryManagementSectionState();
}

class _CategoryManagementSectionState extends State<CategoryManagementSection> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddCategoryDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
        const SizedBox(height: 16),
        if (categoryProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (categoryProvider.categories.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No categories yet. Add one to get started!'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categoryProvider.categories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.categories[index];
              return Card(
                child: ListTile(
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDeleteCategory(context, category),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g., Academic, Events, General',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final category = AnnouncementCategory(
                  id: '',
                  name: name,
                  createdAt: DateTime.now(),
                );
                context.read<CategoryProvider>().addOrUpdateCategory(category);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, AnnouncementCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryProvider>().deleteCategory(category.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
