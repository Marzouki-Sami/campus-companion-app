import 'package:campus_companion/core/offline/cached_fetch.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';

/// Wraps another repository and keeps the signed-in user's own profile for
/// offline use, so the app still knows who you are without a connection.
/// A profile that no longer exists or is suspended is still reported as soon
/// as the server can be reached.
class CachingUserRepository implements UserRepository {
  CachingUserRepository(this._inner, this._cache, this._offline);

  final UserRepository _inner;
  final LocalCache _cache;
  final OfflineState _offline;

  @override
  Future<AppUser> fetchById(String id) {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'profile.$id',
      fetch: () => _inner.fetchById(id),
      encode: (u) => {
        'id': u.id,
        'email': u.email,
        'displayName': u.displayName,
        'role': u.role.name,
        'isSuspended': u.isSuspended,
      },
      decode: (json) {
        final map = json as Map<String, dynamic>;
        return AppUser(
          id: map['id'] as String,
          email: map['email'] as String,
          displayName: map['displayName'] as String?,
          role: UserRole.parse(map['role'] as String?),
          isSuspended: map['isSuspended'] == true,
        );
      },
    );
  }

  @override
  Future<List<AppUser>> fetchAll() => _inner.fetchAll();

  @override
  Future<void> save(AppUser user) => _inner.save(user);

  @override
  Future<void> delete(String id) => _inner.delete(id);
}
