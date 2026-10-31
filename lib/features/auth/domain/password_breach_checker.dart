/// Tells whether a password is known from public data breaches.
abstract interface class PasswordBreachChecker {
  /// `true` only when the password is known to be breached. Implementations
  /// must never block people because the check itself could not run.
  Future<bool> isBreached(String password);
}

/// A checker that never reports a breach (used in tests and as a safe default).
class NoPasswordBreachCheck implements PasswordBreachChecker {
  const NoPasswordBreachCheck();

  @override
  Future<bool> isBreached(String password) async => false;
}
