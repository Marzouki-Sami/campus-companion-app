import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/user_role.dart';
import 'package:campus_companion/features/auth/presentation/providers/auth_provider.dart';
import '../support/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthProvider provider;

  setUp(() {
    repository = FakeAuthRepository();
    provider = AuthProvider(repository);
  });

  tearDown(() => provider.dispose());

  test('login stores the signed-in user', () async {
    expect(await provider.login('a@b.c', 'secret'), isTrue);
    expect(provider.currentUser?.email, 'a@b.c');
    expect(provider.isLoggedIn, isTrue);
  });

  test('login surfaces AppException messages as-is', () async {
    repository.error = invalidCredentials;

    expect(await provider.login('a@b.c', 'bad'), isFalse);
    expect(provider.errorMessage, 'Invalid email or password');
    expect(provider.currentUser, isNull);
  });

  test('login hides unexpected error details', () async {
    repository.error = StateError('stack trace details');

    await provider.login('a@b.c', 'x');

    expect(provider.errorMessage, 'Login failed');
  });

  test('registered users are students', () async {
    await provider.register('a@b.c', 'secret', 'Sami');

    expect(provider.currentUser?.role, UserRole.student);
    expect(provider.currentUser?.displayName, 'Sami');
  });

  test('follows auth state changes', () async {
    repository.emit(const AppUser(id: '1', email: 'x@y.z'));
    await Future<void>.delayed(Duration.zero);
    expect(provider.currentUser?.id, '1');

    await provider.logout();
    await Future<void>.delayed(Duration.zero);
    expect(provider.currentUser, isNull);
  });

  test('updateDisplayName requires a signed-in user', () async {
    expect(await provider.updateDisplayName('Nobody'), isFalse);

    await provider.login('a@b.c', 'secret');
    expect(await provider.updateDisplayName('Sami'), isTrue);
    expect(provider.currentUser?.displayName, 'Sami');
  });
}
