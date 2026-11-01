/// Proves that a real person (not a script) is behind a sign-in or sign-up.
///
/// Supabase can require a captcha token on its auth endpoints. When no captcha
/// is configured the app uses [NoCaptcha] and sends no token.
abstract interface class CaptchaSolver {
  /// Whether a challenge will be shown before protected requests.
  bool get isEnabled;

  /// Returns a one-time token, or `null` when captcha is disabled.
  /// Throws an `AppException` if the user dismisses the challenge or it fails.
  Future<String?> solve();
}

class NoCaptcha implements CaptchaSolver {
  const NoCaptcha();

  @override
  bool get isEnabled => false;

  @override
  Future<String?> solve() async => null;
}
