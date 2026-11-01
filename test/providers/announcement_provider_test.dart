import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/presentation/providers/announcement_provider.dart';

import '../support/fakes.dart';

Announcement _a(String id) => Announcement(
      id: id,
      title: id,
      body: 'x',
      createdAt: DateTime(2030),
    );

void main() {
  late FakeAnnouncementRepository repository;
  late AnnouncementProvider provider;

  setUp(() async {
    repository = FakeAnnouncementRepository(
      [_a('a'), _a('b'), _a('c')],
      read: {'a'},
    );
    provider = AnnouncementProvider(repository);
    await provider.loadAnnouncements();
  });

  test('announcements that were not opened yet are unread', () {
    expect(provider.isUnread('a'), isFalse);
    expect(provider.isUnread('b'), isTrue);
    expect(provider.unreadCount, 2);
  });

  test('markRead updates the count at once and is saved', () async {
    await provider.markRead('b');

    expect(provider.isUnread('b'), isFalse);
    expect(provider.unreadCount, 1);
    expect(repository.readIds, {'a', 'b'});
  });

  test('markAllRead clears every unread announcement', () async {
    await provider.markAllRead();

    expect(provider.unreadCount, 0);
    expect(repository.readIds, {'a', 'b', 'c'});
  });

  test('already read announcements are not sent again', () async {
    var calls = 0;
    final counting = _CountingRepository(repository, () => calls++);
    final p = AnnouncementProvider(counting);
    await p.loadAnnouncements();

    await p.markRead('a');

    expect(calls, 0);
  });

  test('a failed save does not surface an error', () async {
    repository.failMarkRead = true;

    await provider.markRead('b');

    expect(provider.errorMessage, isNull);
  });
  group('pagination', () {
    late FakeAnnouncementRepository many;
    late AnnouncementProvider paged;

    setUp(() async {
      many = FakeAnnouncementRepository([
        for (var i = 0; i < 45; i++) _a('n$i'),
      ]);
      paged = AnnouncementProvider(many);
      await paged.loadAnnouncements();
    });

    test('loads one page first and knows there is more', () {
      expect(paged.announcements, hasLength(announcementPageSize));
      expect(paged.hasMore, isTrue);
    });

    test('loadMore appends the next pages until the end', () async {
      await paged.loadMore();
      expect(paged.announcements, hasLength(40));
      expect(paged.hasMore, isTrue);

      await paged.loadMore();
      expect(paged.announcements, hasLength(45));
      expect(paged.hasMore, isFalse);
      expect(paged.announcements.map((a) => a.id).toSet(), hasLength(45));
    });

    test('loadMore does nothing once everything is loaded', () async {
      await paged.loadMore();
      await paged.loadMore();
      final requests = many.pageRequests;

      await paged.loadMore();

      expect(many.pageRequests, requests);
    });

    test('a failed page keeps what is already loaded', () async {
      many.offline = true;

      final ok = await paged.loadMore();

      expect(ok, isFalse);
      expect(paged.announcements, hasLength(announcementPageSize));
      expect(paged.isLoadingMore, isFalse);
    });

    test('the unread and total counts cover every page', () {
      expect(paged.unreadCount, 45);
      expect(paged.totalCount, 45);
    });

    test('mark all as read clears the count for unloaded pages too', () async {
      await paged.markAllRead();

      expect(paged.unreadCount, 0);
      expect(paged.isUnread('n44'), isFalse);
    });
  });

  test('a failed mark-all restores the previous state', () async {
    repository.offline = true;

    await provider.markAllRead();

    expect(provider.unreadCount, 2);
    expect(provider.isUnread('b'), isTrue);
  });
}

class _CountingRepository extends FakeAnnouncementRepository {
  _CountingRepository(FakeAnnouncementRepository base, this.onMarkRead)
      : super(base.items, read: base.readIds);

  final void Function() onMarkRead;

  @override
  Future<void> markRead(Iterable<String> ids) {
    onMarkRead();
    return super.markRead(ids);
  }
}
