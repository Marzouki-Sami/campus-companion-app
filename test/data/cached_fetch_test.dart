import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/offline/cached_fetch.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';

void main() {
  late MemoryCache cache;
  late OfflineState offline;

  Future<List<int>> run(Future<List<int>> Function() fetch) => fetchWithCache(
        cache: cache,
        offline: offline,
        key: 'numbers',
        fetch: fetch,
        encode: (v) => v,
        decode: (json) => (json as List<dynamic>).cast<int>(),
      );

  setUp(() {
    cache = MemoryCache();
    offline = OfflineState();
  });

  test('returns fresh data and remembers it', () async {
    final result = await run(() async => [1, 2]);

    expect(result, [1, 2]);
    expect(cache.read('numbers'), '[1,2]');
    expect(offline.isOffline, isFalse);
  });

  test('falls back to the saved copy when offline', () async {
    await run(() async => [1, 2]);

    final result = await run(() async => throw const OfflineException());

    expect(result, [1, 2]);
    expect(offline.isOffline, isTrue);
  });

  test('going back online clears the offline flag', () async {
    await run(() async => [1]);
    await run(() async => throw const OfflineException());

    await run(() async => [3]);

    expect(offline.isOffline, isFalse);
  });

  test('offline with nothing saved still fails', () async {
    expect(
      () => run(() async => throw const OfflineException()),
      throwsA(isA<OfflineException>()),
    );
  });

  test('other errors are never hidden behind stale data', () async {
    await run(() async => [1, 2]);

    expect(
      () => run(() async => throw const AppException('Not allowed')),
      throwsA(isA<AppException>()),
    );
    expect(offline.isOffline, isFalse);
  });

  test('clearing the cache forgets saved data', () async {
    await run(() async => [1, 2]);
    await cache.clear();

    expect(cache.read('numbers'), isNull);
  });
}
