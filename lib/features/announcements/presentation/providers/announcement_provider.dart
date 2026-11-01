import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';

class AnnouncementProvider extends ChangeNotifier with LoadingStateMixin {
  AnnouncementProvider(this._repository);

  final AnnouncementRepository _repository;

  List<Announcement> _announcements = const [];
  List<Announcement> get announcements => _announcements;

  Future<bool> loadAnnouncements() {
    return runGuarded(() async {
      _announcements = await _repository.fetchAll();
    }, failureMessage: 'Failed to load announcements');
  }

  Future<bool> addOrUpdateAnnouncement(
    Announcement announcement, {
    List<NewImage> newImages = const [],
  }) {
    return runGuarded(() async {
      await _repository.save(announcement, newImages: newImages);
      _announcements = await _repository.fetchAll();
    }, failureMessage: 'Failed to save announcement');
  }

  Future<bool> deleteAnnouncement(String announcementId) {
    return runGuarded(() async {
      await _repository.delete(announcementId);
      _announcements = await _repository.fetchAll();
    }, failureMessage: 'Failed to delete announcement');
  }
}
