import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:campus_companion/features/auth/data/hibp_breach_checker.dart';

String _sha1(String value) =>
    sha1.convert(value.codeUnits).toString().toUpperCase();

void main() {
  group('HibpBreachChecker', () {
    test('sends only the 5-character hash prefix', () async {
      Uri? requested;
      Map<String, String>? headers;
      final checker = HibpBreachChecker(
        client: MockClient((request) async {
          requested = request.url;
          headers = request.headers;
          return http.Response('', 200);
        }),
      );

      await checker.isBreached('password');

      final hash = _sha1('password');
      expect(requested!.path, '/range/${hash.substring(0, 5)}');
      expect(requested!.toString(), isNot(contains(hash.substring(5))));
      expect(headers!['Add-Padding'], 'true');
    });

    test('reports a breach when the suffix is listed with a count', () async {
      final hash = _sha1('password');
      final checker = HibpBreachChecker(
        client: MockClient(
          (_) async => http.Response(
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA:2\r\n${hash.substring(5)}:9545824',
            200,
          ),
        ),
      );

      expect(await checker.isBreached('password'), isTrue);
    });

    test('ignores padding entries with a zero count', () async {
      const unusual = 'zq-vx-jw-kd';
      final hash = _sha1(unusual);
      final checker = HibpBreachChecker(
        client: MockClient(
          (_) async => http.Response('${hash.substring(5)}:0', 200),
        ),
      );

      expect(await checker.isBreached(unusual), isFalse);
    });

    test('passes when the service errors or is unreachable', () async {
      final failing = HibpBreachChecker(
        client: MockClient((_) async => http.Response('nope', 503)),
      );
      final offline = HibpBreachChecker(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(await failing.isBreached('password'), isFalse);
      expect(await offline.isBreached('password'), isFalse);
    });
  });
}
