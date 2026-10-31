import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/errors/database_errors.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';

AppUser profileFromRow(Map<String, dynamic> row) {
  return AppUser(
    id: row['id'] as String,
    email: row['email'] as String? ?? '',
    displayName: row['display_name'] as String?,
    role: UserRole.parse(row['role'] as String?),
    isSuspended: row['is_suspended'] == true,
  );
}

class SupabaseUserRepository implements UserRepository {
  SupabaseUserRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AppUser> fetchById(String id) {
    return guardDb(() async {
      final row =
          await _client.from('profiles').select().eq('id', id).maybeSingle();
      if (row == null) {
        throw const AppException(
          'Your profile could not be found. Please sign out and sign in again.',
        );
      }
      return profileFromRow(row);
    });
  }

  @override
  Future<List<AppUser>> fetchAll() {
    return guardDb(() async {
      final rows = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: true);
      return rows.map(profileFromRow).toList();
    });
  }

  @override
  Future<void> save(AppUser user) {
    return guardDb(() async {
      final updated = await _client
          .from('profiles')
          .update({
            'display_name': user.displayName,
            'role': user.role.name,
            'is_suspended': user.isSuspended,
          })
          .eq('id', user.id)
          .select('id');
      // Row Level Security hides rows you may not touch instead of failing.
      if (updated.isEmpty) {
        throw const AppException('You do not have permission to do that.');
      }
    });
  }
}
