import 'package:campus_companion/core/offline/cached_fetch.dart';
import 'package:campus_companion/core/offline/local_cache.dart';
import 'package:campus_companion/core/offline/offline_state.dart';
import 'package:campus_companion/features/categories/data/category_json.dart';
import 'package:campus_companion/features/categories/domain/announcement_category.dart';
import 'package:campus_companion/features/categories/domain/category_repository.dart';

/// Wraps another repository and keeps an offline copy of the categories.
class CachingCategoryRepository implements CategoryRepository {
  CachingCategoryRepository(this._inner, this._cache, this._offline);

  final CategoryRepository _inner;
  final LocalCache _cache;
  final OfflineState _offline;

  @override
  Future<List<AnnouncementCategory>> fetchAll() {
    return fetchWithCache(
      cache: _cache,
      offline: _offline,
      key: 'categories',
      fetch: _inner.fetchAll,
      encode: categoriesToJson,
      decode: categoriesFromJson,
    );
  }

  @override
  Future<void> save(AnnouncementCategory category) => _inner.save(category);

  @override
  Future<void> delete(String id) => _inner.delete(id);
}
