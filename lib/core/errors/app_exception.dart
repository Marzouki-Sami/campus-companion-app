/// The signed-in session can no longer continue, and the user is told why.
class SessionEndedException extends AppException {
  const SessionEndedException(super.message);
}

/// Thrown when the signed-in account has been suspended while the app was open.
class AccountSuspendedException extends SessionEndedException {
  const AccountSuspendedException()
      : super(
          'Your account has been suspended. If you believe this is a mistake, '
          'please contact support.',
        );
}

/// Thrown when the signed-in account no longer exists (for example because an
/// administrator deleted it).
class AccountRemovedException extends SessionEndedException {
  const AccountRemovedException()
      : super('This account no longer exists. Please create a new one.');
}

/// Thrown when someone tries to sign in before confirming their email.
class EmailNotVerifiedException extends AppException {
  const EmailNotVerifiedException(this.email)
      : super('Please verify your email address to continue.');

  final String email;
}

/// An expected failure whose [message] is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
