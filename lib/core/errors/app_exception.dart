/// Thrown when the signed-in account has been suspended while the app was open.
class AccountSuspendedException extends AppException {
  const AccountSuspendedException()
      : super(
          'Your account has been suspended. If you believe this is a mistake, '
          'please contact support.',
        );
}

/// An expected failure whose [message] is safe to show to the user.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
