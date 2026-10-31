import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/auth/domain/password_policy.dart';

/// Builds a sample password from character classes, so each test says which
/// rule it exercises instead of relying on a magic string.
String sample({
  bool lower = true,
  bool upper = true,
  bool digit = true,
  bool symbol = true,
  int length = 12,
}) {
  final pool = [
    if (lower) 'k',
    if (upper) 'K',
    if (digit) '7',
    if (symbol) '#',
  ];
  if (pool.isEmpty) return '';
  return List.generate(length, (i) => pool[i % pool.length]).join();
}

void main() {
  group('PasswordPolicy', () {
    test('accepts a password that meets every rule', () {
      final password = sample();

      expect(PasswordPolicy.isValid(password), isTrue);
      expect(PasswordPolicy.validate(password), isNull);
    });

    test('reports exactly the rule that is missing', () {
      expect(PasswordPolicy.unmet(sample(lower: false)), [
        PasswordRule.lowercase,
      ]);
      expect(PasswordPolicy.unmet(sample(upper: false)), [
        PasswordRule.uppercase,
      ]);
      expect(PasswordPolicy.unmet(sample(digit: false)), [PasswordRule.digit]);
      expect(PasswordPolicy.unmet(sample(symbol: false)), [
        PasswordRule.symbol,
      ]);
      expect(PasswordPolicy.unmet(sample(length: 7)), [PasswordRule.length]);
    });

    test('reports several missing rules at once', () {
      expect(
        PasswordPolicy.unmet(sample(upper: false, digit: false, length: 3)),
        [PasswordRule.length, PasswordRule.uppercase, PasswordRule.digit],
      );
    });

    test('rejects passwords longer than the backend can hash', () {
      final tooLong = sample(length: PasswordPolicy.maxLength + 1);

      expect(PasswordPolicy.isValid(tooLong), isFalse);
      expect(PasswordPolicy.validate(tooLong), contains('at most'));
      expect(
        PasswordPolicy.isValid(sample(length: PasswordPolicy.maxLength)),
        isTrue,
      );
    });

    test('validator messages are friendly', () {
      expect(PasswordPolicy.validate(''), 'Please enter password');
      expect(PasswordPolicy.validate(null), 'Please enter password');
      expect(
        PasswordPolicy.validate(sample(symbol: false)),
        'Password does not meet the requirements',
      );
    });

    test('every symbol the backend accepts counts', () {
      for (final symbol in r'''!@#$%^&*()_+-=[]{};':"|<>?,./`~\'''.split('')) {
        expect(
          PasswordPolicy.satisfies(PasswordRule.symbol, 'k$symbol'),
          isTrue,
          reason: symbol,
        );
      }
      expect(
        PasswordPolicy.satisfies(PasswordRule.symbol, 'k K 7'),
        isFalse,
        reason: 'spaces are not symbols',
      );
    });

    test('strength grows as rules are met', () {
      expect(PasswordPolicy.strength(''), 0);
      expect(
        PasswordPolicy.strength(sample(length: 3, upper: false, symbol: false)),
        lessThan(PasswordPolicy.strength(sample(length: 8, symbol: false))),
      );
      expect(
        PasswordPolicy.strength(sample(length: 8)),
        lessThan(PasswordPolicy.strength(sample(length: 12))),
      );
      expect(PasswordPolicy.strength(sample(length: 12)), 1);
    });
  });
}
