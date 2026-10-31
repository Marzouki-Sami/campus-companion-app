import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';
import 'package:campus_companion/features/admin/presentation/providers/users_provider.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart'
    show AnnouncementCategory;
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';

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
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.currentUser?.role.isAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Access denied. This area is restricted to administrators.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
              // Users management section
              const Text(
                'User Management',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const UsersManagementSection(),
              const SizedBox(height: 24),
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
  State<CategoryManagementSection> createState() =>
      _CategoryManagementSectionState();
}

class UsersManagementSection extends StatefulWidget {
  const UsersManagementSection({super.key});

  @override
  State<UsersManagementSection> createState() => _UsersManagementSectionState();
}

class _UsersManagementSectionState extends State<UsersManagementSection> {
  @override
  void initState() {
    super.initState();
    context.read<UsersProvider>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final usersProvider = context.watch<UsersProvider>();

    if (usersProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (usersProvider.errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(usersProvider.errorMessage!),
        ),
      );
    }
    if (usersProvider.users.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No users found.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: usersProvider.users.length,
      itemBuilder: (context, index) {
        final user = usersProvider.users[index];
        return Card(
          child: ListTile(
            title: Text(user.displayName?.isNotEmpty == true
                ? user.displayName!
                : '(no name)'),
            subtitle: Text(
                '${user.email}\nRole: ${user.role.label}${user.isSuspended ? ' (Suspended)' : ''}'),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit name',
                  onPressed: () => _editName(context, user),
                ),
                _RoleDropdown(
                    user: user,
                    onChanged: (updated) {
                      context.read<UsersProvider>().updateUser(updated);
                    }),
                IconButton(
                  tooltip: user.isSuspended ? 'Unsuspend user' : 'Suspend user',
                  icon: Icon(
                    user.isSuspended ? Icons.lock_open : Icons.lock,
                    color: user.isSuspended ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    context.read<UsersProvider>().updateUser(
                        user.copyWith(isSuspended: !user.isSuspended));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editName(BuildContext context, AppUser user) {
    final controller = TextEditingController(text: user.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              context
                  .read<UsersProvider>()
                  .updateUser(user.copyWith(displayName: name));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final AppUser user;
  final ValueChanged<AppUser> onChanged;
  const _RoleDropdown({required this.user, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<UserRole>(
      value: user.role,
      items: [
        for (final role in UserRole.values)
          DropdownMenuItem(value: role, child: Text(role.label)),
      ],
      onChanged: (value) {
        if (value == null) return;
        onChanged(user.copyWith(role: value));
      },
    );
  }
}

class _CategoryManagementSectionState extends State<CategoryManagementSection> {
  String _categorySearchQuery = '';
  bool _categorySearchStartsWith = true;

  @override
  void initState() {
    super.initState();
    context.read<CategoryProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    // Filter categories based on search
    final filteredCategories =
        _getFilteredCategories(categoryProvider.categories);

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddCategoryDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Category'),
        ),
        const SizedBox(height: 8),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search categories...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              suffixIcon: PopupMenuButton<bool>(
                onSelected: (value) =>
                    setState(() => _categorySearchStartsWith = value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: true,
                    child: Row(
                      children: [
                        Icon(_categorySearchStartsWith
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                        const SizedBox(width: 8),
                        const Text('Starts with'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: false,
                    child: Row(
                      children: [
                        Icon(!_categorySearchStartsWith
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked),
                        const SizedBox(width: 8),
                        const Text('Contains'),
                      ],
                    ),
                  ),
                ],
                child: Text(
                  _categorySearchStartsWith ? 'Starts' : 'Contains',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            onChanged: (value) => setState(() => _categorySearchQuery = value),
          ),
        ),
        const SizedBox(height: 16),
        if (categoryProvider.errorMessage != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                categoryProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        if (categoryProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (filteredCategories.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No categories found.'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) {
              final category = filteredCategories[index];
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

  List<AnnouncementCategory> _getFilteredCategories(
      List<AnnouncementCategory> categories) {
    if (_categorySearchQuery.isEmpty) {
      return categories;
    }

    final query = _categorySearchQuery.toLowerCase();
    return categories.where((c) {
      final name = c.name.toLowerCase();
      return _categorySearchStartsWith
          ? name.startsWith(query)
          : name.contains(query);
    }).toList();
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

  void _confirmDeleteCategory(
      BuildContext context, AnnouncementCategory category) {
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
