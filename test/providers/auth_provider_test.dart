import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/password_breach_checker.dart';
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
    await provider.register('a@b.c', 'Strong-Pass-9', 'Sami');

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

  group('refreshProfile', () {
    test('ends the session with a message when the account is suspended',
        () async {
      await provider.login('a@b.c', 'secret');
      repository.reloadError = const AccountSuspendedException();

      await provider.refreshProfile();

      expect(provider.currentUser, isNull);
      expect(provider.takeSessionEndedMessage(), contains('suspended'));
      expect(provider.takeSessionEndedMessage(), isNull);
    });

    test('ends the session when the account no longer exists', () async {
      await provider.login('a@b.c', 'secret');
      repository.reloadError = const AccountRemovedException();

      await provider.refreshProfile();

      expect(provider.currentUser, isNull);
      expect(provider.takeSessionEndedMessage(), contains('no longer exists'));
    });

    test('keeps the user when the check fails for a transient reason',
        () async {
      await provider.login('a@b.c', 'secret');
      repository.reloadError = const AppException('No connection.');

      await provider.refreshProfile();

      expect(provider.currentUser, isNotNull);
      expect(provider.takeSessionEndedMessage(), isNull);
    });

    test('does nothing when nobody is signed in', () async {
      await provider.refreshProfile();

      expect(provider.currentUser, isNull);
    });
  });

  group('registration with email verification', () {
    const strong = 'Strong-Pass-9';

    test('waits for the code when the project requires verification', () async {
      repository.requireVerification = true;

      final ok = await provider.register('a@b.c', strong, 'Sam');

      expect(ok, isTrue);
      expect(provider.currentUser, isNull);
      expect(provider.pendingVerificationEmail, 'a@b.c');
    });

    test('the code completes the sign-up', () async {
      repository.requireVerification = true;
      await provider.register('a@b.c', strong, 'Sam');

      final ok = await provider.verifyEmail('a@b.c', '123456');

      expect(ok, isTrue);
      expect(provider.currentUser?.email, 'a@b.c');
      expect(provider.pendingVerificationEmail, isNull);
    });

    test('a wrong code surfaces its message', () async {
      repository.error = const AppException('That code is wrong.');

      final ok = await provider.verifyEmail('a@b.c', '000000');

      expect(ok, isFalse);
      expect(provider.errorMessage, 'That code is wrong.');
    });

    test('signing in before verifying asks for the code and resends it',
        () async {
      repository.unverifiedEmails.add('a@b.c');

      final ok = await provider.login('a@b.c', strong);

      expect(ok, isFalse);
      expect(provider.pendingVerificationEmail, 'a@b.c');
      expect(repository.resendCalls, ['a@b.c']);
    });
  });

  group('password rules', () {
    test('weak passwords never reach the repository', () async {
      repository.requireVerification = true;

      final ok = await provider.register('a@b.c', 'weak', 'Sam');

      expect(ok, isFalse);
      expect(provider.errorMessage, contains('requirements'));
      expect(provider.pendingVerificationEmail, isNull);
    });

    test('breached passwords are refused with an explanation', () async {
      final guarded = AuthProvider(
        repository,
        passwordBreachChecker: _AlwaysBreached(),
      );
      addTearDown(guarded.dispose);

      final ok = await guarded.register('a@b.c', 'Strong-Pass-9', 'Sam');

      expect(ok, isFalse);
      expect(guarded.errorMessage, contains('data breach'));
    });
  });

  group('forgot password', () {
    test('requesting a code asks the repository to email it', () async {
      final ok = await provider.requestPasswordReset('a@b.c');

      expect(ok, isTrue);
      expect(repository.resetRequests, ['a@b.c']);
    });

    test('a valid code and password sign the user in', () async {
      final ok =
          await provider.resetPassword('a@b.c', '123456', 'Brand-New-Pass-1');

      expect(ok, isTrue);
      expect(provider.currentUser?.email, 'a@b.c');
    });

    test('the new password must follow the rules', () async {
      final ok = await provider.resetPassword('a@b.c', '123456', 'weak');

      expect(ok, isFalse);
      expect(provider.currentUser, isNull);
    });
  });
}

class _AlwaysBreached implements PasswordBreachChecker {
  @override
  Future<bool> isBreached(String password) async => true;
}
