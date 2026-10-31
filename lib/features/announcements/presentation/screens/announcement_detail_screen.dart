import 'package:flutter/material.dart';

import 'package:campus_companion/features/announcements/domain/announcement.dart';

class AnnouncementDetailArgs {
  final Announcement announcement;

  AnnouncementDetailArgs({required this.announcement});
}

class AnnouncementDetailScreen extends StatelessWidget {
  static const routeName = '/announcement-detail';

  final AnnouncementDetailArgs args;

  const AnnouncementDetailScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final a = args.announcement;
    return Scaffold(
      appBar: AppBar(title: Text(a.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Hero(
          tag: 'announcement_${a.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(a.body),
          ),
        ),
      ),
    );
  }
}
