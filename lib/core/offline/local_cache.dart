import 'package:shared_preferences/shared_preferences.dart';

/// A small key/value store for data kept on the device for offline use.
abstract interface class LocalCache {
  String? read(String key);

  Future<void> write(String key, String value);

  /// Forgets everything, e.g. when someone signs out of a shared phone.
  Future<void> clear();
}

class SharedPreferencesCache implements LocalCache {
  SharedPreferencesCache(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'cache.';

  @override
  String? read(String key) => _prefs.getString('$_prefix$key');

  @override
  Future<void> write(String key, String value) =>
      _prefs.setString('$_prefix$key', value);

  @override
  Future<void> clear() async {
    for (final key in _prefs.getKeys().where((k) => k.startsWith(_prefix))) {
      await _prefs.remove(key);
    }
  }
}

/// Keeps data in memory only. Used by tests and as a no-op default.
class MemoryCache implements LocalCache {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> clear() async => _values.clear();
}
