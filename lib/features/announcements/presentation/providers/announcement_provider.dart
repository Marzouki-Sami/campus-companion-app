import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';

/// How many announcements each page holds.
const announcementPageSize = 20;

class AnnouncementProvider extends ChangeNotifier with LoadingStateMixin {
  AnnouncementProvider(this._repository);

  final AnnouncementRepository _repository;

  List<Announcement> _announcements = const [];
  List<Announcement> _events = const [];
  Set<String> _readIds = const {};
  int _unreadCount = 0;
  int _totalCount = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  /// The announcements loaded so far, pinned first and then newest first.
  List<Announcement> get announcements => _announcements;

  /// Events that have not finished yet, soonest first.
  List<Announcement> get upcomingEvents => _events;

  /// How many announcements exist, across every page.
  int get totalCount => _totalCount;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  bool isUnread(String id) => !_readIds.contains(id);

  /// Unread announcements across every page, not just the loaded ones.
  int get unreadCount => _unreadCount;

  /// Loads the first page again, together with events and read state.
  Future<bool> loadAnnouncements() {
    return runGuarded(_loadFirstPage,
        failureMessage: 'Failed to load announcements');
  }

  Future<void> _loadFirstPage() async {
    final results = await Future.wait<Object>([
      _repository.fetchPage(offset: 0, limit: announcementPageSize),
      _repository.fetchUpcomingEvents(now: DateTime.now()),
      _repository.fetchReadIds(),
      _repository.fetchUnreadCount(),
      _repository.fetchTotalCount(),
    ]);
    _announcements = results[0] as List<Announcement>;
    _events = results[1] as List<Announcement>;
    _readIds = results[2] as Set<String>;
    _unreadCount = results[3] as int;
    _totalCount = results[4] as int;
    _hasMore = _announcements.length == announcementPageSize;
  }

  /// Appends the next page. Failures are reported through [errorMessage] but
  /// keep what is already loaded.
  Future<bool> loadMore() async {
    if (!_hasMore || _isLoadingMore || isLoading) return true;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final next = await _repository.fetchPage(
        offset: _announcements.length,
        limit: announcementPageSize,
      );
      final known = {for (final a in _announcements) a.id};
      _announcements = [
        ..._announcements,
        for (final a in next)
          if (!known.contains(a.id)) a,
      ];
      _hasMore = next.length == announcementPageSize;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> addOrUpdateAnnouncement(
    Announcement announcement, {
    List<NewImage> newImages = const [],
  }) {
    return runGuarded(() async {
      await _repository.save(announcement, newImages: newImages);
      await _loadFirstPage();
    }, failureMessage: 'Failed to save announcement');
  }

  Future<bool> deleteAnnouncement(String announcementId) {
    return runGuarded(() async {
      await _repository.delete(announcementId);
      await _loadFirstPage();
    }, failureMessage: 'Failed to delete announcement');
  }

  /// Marks one announcement as read. Shown instantly; a failed save only means
  /// it will look unread again next time, so errors are not surfaced.
  Future<void> markRead(String id) async {
    if (_readIds.contains(id)) return;
    _readIds = {..._readIds, id};
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();
    try {
      await _repository.markRead([id]);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final previousReads = _readIds;
    final previousCount = _unreadCount;
    _readIds = {..._readIds, for (final a in _announcements) a.id};
    _unreadCount = 0;
    notifyListeners();
    try {
      await _repository.markAllRead();
      _readIds = await _repository.fetchReadIds();
      notifyListeners();
    } catch (_) {
      _readIds = previousReads;
      _unreadCount = previousCount;
      notifyListeners();
    }
  }
}
