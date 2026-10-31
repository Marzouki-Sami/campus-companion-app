import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';

const _offlineMessage = 'No connection. Check your internet and try again.';

/// Runs a database call and converts transport and policy errors into
/// [AppException]s whose messages are safe to show to users.
Future<T> guardDb<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on PostgrestException catch (e) {
    throw AppException(_messageForPostgrest(e));
  } on SocketException {
    throw const AppException(_offlineMessage);
  } on TimeoutException {
    throw const AppException(_offlineMessage);
  } on AuthRetryableFetchException {
    throw const AppException(_offlineMessage);
  }
}

String _messageForPostgrest(PostgrestException e) {
  switch (e.code) {
    case '42501':
      return 'You do not have permission to do that.';
    case '23505':
      return 'That already exists.';
    case '23514':
      return 'Some values are empty or too long.';
    case 'P0002':
      return 'That item no longer exists.';
    default:
      final message = e.message.toLowerCase();
      if (message.contains('failed host lookup') ||
          message.contains('connection')) {
        return _offlineMessage;
      }
      return 'Something went wrong. Please try again.';
  }
}
