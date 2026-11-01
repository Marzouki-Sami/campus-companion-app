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

  Set<String> _readIds = const {};

  bool isUnread(String id) => !_readIds.contains(id);

  int get unreadCount =>
      _announcements.where((a) => !_readIds.contains(a.id)).length;

  Future<bool> loadAnnouncements() {
    return runGuarded(() async {
      _announcements = await _repository.fetchAll();
      _readIds = await _repository.fetchReadIds();
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

  /// Marks one announcement as read. Shown instantly; a failed save only means
  /// it will look unread again next time, so errors are not surfaced.
  Future<void> markRead(String id) => _markRead([id]);

  Future<void> markAllRead() =>
      _markRead([for (final a in _announcements) a.id]);

  Future<void> _markRead(List<String> ids) async {
    final fresh = ids.where((id) => !_readIds.contains(id)).toList();
    if (fresh.isEmpty) return;
    _readIds = {..._readIds, ...fresh};
    notifyListeners();
    try {
      await _repository.markRead(fresh);
    } catch (_) {}
  }
}
