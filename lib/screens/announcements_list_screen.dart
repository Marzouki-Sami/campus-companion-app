import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/announcement_provider.dart';
import '../models/announcement.dart';
import 'announcement_detail_screen.dart';

class AnnouncementsListScreen extends StatelessWidget {
  static const routeName = '/announcements';

  const AnnouncementsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnnouncementProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Announcement> items = provider.announcements;
    if (items.isEmpty) {
      return const Center(child: Text('No announcements yet.'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final a = items[index];
        return Hero(
          tag: 'announcement_${a.id}',
          child: Card(
            child: ListTile(
              title: Text(a.title),
              subtitle: Text(
                a.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AnnouncementDetailScreen.routeName,
                  arguments: AnnouncementDetailArgs(announcement: a),
                );
              },
            ),
          ),
        );
      },
    );
  }
}


