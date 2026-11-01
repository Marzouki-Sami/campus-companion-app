import 'dart:convert';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';

/// Runs [fetch]; remembers its result on success, and when the network is
/// unreachable falls back to the last remembered result.
///
/// Only connectivity failures fall back. Permission errors and the like still
/// surface, so stale data never hides a real problem.
Future<T> fetchWithCache<T>({
  required LocalCache cache,
  required OfflineState offline,
  required String key,
  required Future<T> Function() fetch,
  required Object? Function(T value) encode,
  required T Function(Object? json) decode,
}) async {
  try {
    final value = await fetch();
    offline.markOnline();
    try {
      await cache.write(key, jsonEncode(encode(value)));
    } catch (_) {
      // Losing the offline copy is not worth failing a successful load.
    }
    return value;
  } on OfflineException {
    final saved = cache.read(key);
    if (saved == null) rethrow;
    offline.markOffline();
    return decode(jsonDecode(saved));
  }
}
