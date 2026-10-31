/// The rules a new password must satisfy. The same rules are enforced by the
/// server (see `supabase/config.toml`), so this only exists to give instant,
/// friendly feedback.
enum PasswordRule {
  length('At least 8 characters'),
  lowercase('A lowercase letter'),
  uppercase('An uppercase letter'),
  digit('A number'),
  symbol('A special character');

  const PasswordRule(this.label);

  final String label;
}

abstract final class PasswordPolicy {
  static const minLength = 8;

  /// bcrypt, which the backend uses, ignores everything after 72 bytes.
  static const maxLength = 72;

  static const _symbols = r'''!@#$%^&*()_+-=[]{};':"|<>?,./`~\''';

  static bool satisfies(PasswordRule rule, String password) {
    return switch (rule) {
      PasswordRule.length => password.length >= minLength,
      PasswordRule.lowercase => password.contains(RegExp('[a-z]')),
      PasswordRule.uppercase => password.contains(RegExp('[A-Z]')),
      PasswordRule.digit => password.contains(RegExp('[0-9]')),
      PasswordRule.symbol => password.split('').any(_symbols.contains),
    };
  }

  static List<PasswordRule> unmet(String password) => [
        for (final rule in PasswordRule.values)
          if (!satisfies(rule, password)) rule,
      ];

  static bool isValid(String password) =>
      password.length <= maxLength && unmet(password).isEmpty;

  /// A message for form validators, or `null` when the password is acceptable.
  static String? validate(String? password) {
    if (password == null || password.isEmpty) return 'Please enter password';
    if (password.length > maxLength) {
      return 'Use at most $maxLength characters';
    }
    return unmet(password).isEmpty
        ? null
        : 'Password does not meet the requirements';
  }

  /// 0 (nothing) to 1 (all rules met and comfortably long).
  static double strength(String password) {
    if (password.isEmpty) return 0;
    final met = PasswordRule.values.length - unmet(password).length;
    final rules = met / PasswordRule.values.length;
    return rules * 0.85 + (password.length >= 12 ? 0.15 : 0.0);
  }
}
