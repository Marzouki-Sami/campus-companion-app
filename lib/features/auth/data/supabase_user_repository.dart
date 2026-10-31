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
        throw const AccountRemovedException();
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

  @override
  Future<void> delete(String id) {
    return guardDb(() async {
      try {
        await _client.functions
            .invoke('admin-delete-user', body: {'user_id': id});
      } on FunctionException catch (e) {
        throw AppException(_deleteFailureMessage(e));
      }
    });
  }

  String _deleteFailureMessage(FunctionException e) {
    switch (e.status) {
      case 403:
        return 'Only administrators can delete accounts.';
      case 404:
        return 'That account no longer exists.';
      case 400:
        final details = e.details;
        if (details is Map && details['error'] is String) {
          return details['error'] as String;
        }
    }
    return 'Could not delete the account. Please try again.';
  }
}
