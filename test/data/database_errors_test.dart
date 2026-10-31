import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/core/errors/database_errors.dart';

Future<void> _failWith(Object error) => guardDb<void>(() async => throw error);

Matcher _appExceptionWith(Matcher message) =>
    throwsA(isA<AppException>().having((e) => e.message, 'message', message));

void main() {
  test('policy violations become a permission message', () {
    expect(
      _failWith(const PostgrestException(message: 'rls', code: '42501')),
      _appExceptionWith(equals('You do not have permission to do that.')),
    );
  });

  test('unique violations are reported as already existing', () {
    expect(
      _failWith(const PostgrestException(message: 'dup', code: '23505')),
      _appExceptionWith(equals('That already exists.')),
    );
  });

  test('unknown database errors never leak their details', () {
    expect(
      _failWith(
        const PostgrestException(message: 'select * from secret', code: 'XX'),
      ),
      _appExceptionWith(isNot(contains('secret'))),
    );
  });

  test('network failures ask the user to check their connection', () {
    expect(
      _failWith(const SocketException('no route')),
      _appExceptionWith(contains('No connection')),
    );
  });

  test('successful calls pass their result through', () async {
    expect(await guardDb(() async => 42), 42);
  });
}
