import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:campus_companion/core/utils/date_format.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_companion/features/announcements/presentation/screens/announcement_edit_screen.dart';
import 'package:campus_companion/features/announcements/presentation/widgets/announcement_gallery.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_companion/features/categories/presentation/providers/category_provider.dart';

class AnnouncementDetailArgs {
  final Announcement announcement;

  AnnouncementDetailArgs({required this.announcement});
}

class AnnouncementDetailScreen extends StatelessWidget {
  static const routeName = '/announcement-detail';

  final AnnouncementDetailArgs args;

  const AnnouncementDetailScreen({super.key, required this.args});

  Future<void> _delete(BuildContext context, Announcement a) async {
    final provider = context.read<AnnouncementProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This cannot be undone.'),
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
    if (confirmed != true) return;
    if (await provider.deleteAnnouncement(a.id)) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = context.watch<AnnouncementProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final canManage = context.select<AuthProvider, bool>(
      (a) => a.currentUser?.role.canManageAnnouncements ?? false,
    );

    // Prefer the live copy so edits are reflected when returning here.
    final a = provider.announcements.firstWhere(
      (x) => x.id == args.announcement.id,
      orElse: () => args.announcement,
    );
    final names = [
      for (final id in a.categories)
        for (final c in categories)
          if (c.id == id) c.name,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        actions: [
          if (canManage) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.pushNamed(
                context,
                AnnouncementEditScreen.routeName,
                arguments: AnnouncementEditArgs(announcement: a),
              ),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, a),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.title,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              formatDate(a.createdAt),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final name in names)
                    Chip(
                      label: Text(name),
                      side: BorderSide.none,
                      backgroundColor: scheme.secondaryContainer,
                      labelStyle: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            if (a.images.isNotEmpty) ...[
              AnnouncementGallery(images: a.images),
              const SizedBox(height: 24),
            ],
            SelectableText(a.body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
