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
