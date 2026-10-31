import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_detail_screen.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/announcement_card.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';
import 'package:campus_companion/features/tasks/domain/task_filter.dart';
import 'package:campus_companion/features/tasks/presentation/providers/task_provider.dart';
import 'package:campus_companion/features/tasks/presentation/screens/task_edit_screen.dart';
import 'package:campus_companion/features/tasks/presentation/widgets/task_tile.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({
    super.key,
    required this.onSeeAllTasks,
    required this.onSeeAllAnnouncements,
  });

  final VoidCallback onSeeAllTasks;
  final VoidCallback onSeeAllAnnouncements;

  Future<void> _refresh(BuildContext context) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final tasks = context.read<TaskProvider>();
    final announcements = context.read<AnnouncementProvider>();
    final categories = context.read<CategoryProvider>();
    await Future.wait([
      if (userId != null) tasks.loadTasks(userId),
      announcements.loadAnnouncements(),
      categories.loadCategories(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().currentUser;
    final userId = user?.id;
    final tasks = context.watch<TaskProvider>();
    final announcements = context.watch<AnnouncementProvider>();
    final categories = context.watch<CategoryProvider>().categories;

    final now = DateTime.now();
    final open = applyTaskFilter(
      tasks.tasks,
      status: TaskStatusFilter.open,
      now: now,
    );
    final overdue = open.where((t) => t.isOverdueAt(now)).length;
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = announcements.announcements
        .where((a) => a.createdAt.isAfter(weekAgo))
        .length;
    final latest = announcements.announcements.take(3).toList();

    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim().split(' ').first
        : 'there';

    return Scaffold(
      appBar: AppBar(title: const Text('Campus Companion')),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Hello, $name',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              formatDate(now),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatCard(
                  icon: Icons.check_circle_outline,
                  value: open.length,
                  label: 'Open tasks',
                  onTap: onSeeAllTasks,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.warning_amber_rounded,
                  value: overdue,
                  label: 'Overdue',
                  highlight: overdue > 0,
                  onTap: onSeeAllTasks,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.campaign_outlined,
                  value: recent,
                  label: 'New this week',
                  onTap: onSeeAllAnnouncements,
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'Up next', onSeeAll: onSeeAllTasks),
            if (userId == null)
              const _Hint('Sign in to see your tasks.')
            else if (open.isEmpty)
              const _Hint('Nothing due. Enjoy the free time!')
            else
              for (final t in open.take(3))
                TaskTile(
                  task: t,
                  margin: EdgeInsets.zero,
                  onToggle: () => tasks.addOrUpdateTask(
                    userId,
                    t.copyWith(isDone: true),
                  ),
                  onTap: () => Navigator.pushNamed(
                    context,
                    TaskEditScreen.routeName,
                    arguments: TaskEditArgs(task: t),
                  ),
                ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Latest announcements',
              onSeeAll: onSeeAllAnnouncements,
            ),
            if (latest.isEmpty)
              const _Hint('No announcements yet.')
            else
              for (final a in latest)
                AnnouncementCard(
                  announcement: a,
                  categories: categories,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AnnouncementDetailScreen.routeName,
                    arguments: AnnouncementDetailArgs(announcement: a),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background =
        highlight ? scheme.errorContainer : scheme.primaryContainer;
    final foreground =
        highlight ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    return Expanded(
      child: Card(
        color: background,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(height: 12),
                Text(
                  '$value',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
