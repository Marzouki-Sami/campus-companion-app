import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:campus_companion/core/errors/app_exception.dart';

/// Runs a database call and converts transport and policy errors into
/// [AppException]s whose messages are safe to show to users.
Future<T> guardDb<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on PostgrestException catch (e) {
    final message = _messageForPostgrest(e);
    throw message == null ? const OfflineException() : AppException(message);
  } on SocketException {
    throw const OfflineException();
  } on TimeoutException {
    throw const OfflineException();
  } on AuthRetryableFetchException {
    throw const OfflineException();
  }
}

/// A user-safe message, or null when the failure means we are offline.
String? _messageForPostgrest(PostgrestException e) {
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
        return null;
      }
      return 'Something went wrong. Please try again.';
  }
}
