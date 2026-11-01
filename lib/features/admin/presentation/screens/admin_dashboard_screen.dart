import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/widgets/empty_state.dart';
import 'package:campus_companion/features/admin/presentation/providers/users_provider.dart';
import 'package:campus_companion/features/admin/presentation/widgets/categories_tab.dart';
import 'package:campus_companion/features/admin/presentation/widgets/users_tab.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  static const routeName = '/admin-dashboard';

  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthProvider, bool>(
      (a) => a.currentUser?.role.isAdmin ?? false,
    );

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin dashboard')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: 'Access denied',
          message: 'This area is restricted to administrators.',
        ),
      );
    }

    final users = context.watch<UsersProvider>().users.length;
    final announcements = context.watch<AnnouncementProvider>().totalCount;
    final categories = context.watch<CategoryProvider>().categories.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Users'),
              Tab(icon: Icon(Icons.label_outline), text: 'Categories'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _Stat(label: 'Users', value: users),
                  const SizedBox(width: 12),
                  _Stat(label: 'News', value: announcements),
                  const SizedBox(width: 12),
                  _Stat(label: 'Categories', value: categories),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [UsersTab(), CategoriesTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Expanded(
      child: Card(
        color: scheme.primaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
