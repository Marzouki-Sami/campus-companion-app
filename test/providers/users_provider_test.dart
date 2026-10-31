import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/admin/presentation/providers/users_provider.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';

import '../support/fakes.dart';

void main() {
  const alice = AppUser(id: 'a', email: 'alice@example.com');
  const bob = AppUser(id: 'b', email: 'bob@example.com');

  late FakeUserRepository repository;
  late UsersProvider provider;

  setUp(() async {
    repository = FakeUserRepository([alice, bob]);
    provider = UsersProvider(repository);
    await provider.loadUsers();
  });

  test('deleteUser removes the account from the list', () async {
    final ok = await provider.deleteUser('b');

    expect(ok, isTrue);
    expect(provider.users.map((u) => u.id), ['a']);
    expect(provider.errorMessage, isNull);
  });

  test('deleteUser keeps the list and surfaces the error on failure', () async {
    repository.deleteError =
        const AppException('Only administrators can delete accounts.');

    final ok = await provider.deleteUser('b');

    expect(ok, isFalse);
    expect(provider.users, hasLength(2));
    expect(provider.errorMessage, 'Only administrators can delete accounts.');
  });
}
