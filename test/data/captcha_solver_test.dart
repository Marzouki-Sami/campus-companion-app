import 'package:flutter_test/flutter_test.dart';

import 'package:campus_companion/features/auth/data/turnstile_captcha_solver.dart';
import 'package:campus_companion/features/auth/domain/captcha_solver.dart';

void main() {
  test('NoCaptcha is disabled and returns no token', () async {
    const captcha = NoCaptcha();

    expect(captcha.isEnabled, isFalse);
    expect(await captcha.solve(), isNull);
  });

  test('Turnstile solver is enabled and accepts a normal site key', () {
    expect(
        TurnstileCaptchaSolver('1x00000000000000000000AA').isEnabled, isTrue);
  });

  test('Turnstile solver rejects a site key that could break out of the page',
      () {
    expect(() => TurnstileCaptchaSolver("abc'); alert(1); ('"),
        throwsA(isA<AssertionError>()));
  });
}
