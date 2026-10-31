import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/presentation/loading_state_mixin.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';

/// Admin-facing list of all users.
class UsersProvider extends ChangeNotifier with LoadingStateMixin {
  UsersProvider(this._repository);

  final UserRepository _repository;

  List<AppUser> _users = const [];
  List<AppUser> get users => _users;

  Future<bool> loadUsers() {
    return runGuarded(() async {
      _users = await _repository.fetchAll();
    }, failureMessage: 'Failed to load users');
  }

  Future<bool> updateUser(AppUser user) {
    return runGuarded(() async {
      await _repository.save(user);
      _users = await _repository.fetchAll();
    }, failureMessage: 'Failed to update user');
  }
}
