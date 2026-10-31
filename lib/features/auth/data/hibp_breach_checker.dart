import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:campus_companion/features/auth/domain/password_breach_checker.dart';

/// Checks a password against the Have I Been Pwned range API.
///
/// Only the first five characters of the password's SHA-1 hash leave the
/// device (k-anonymity), and padding hides how many results match. If the
/// service cannot be reached the check passes, so sign-up never depends on it.
class HibpBreachChecker implements PasswordBreachChecker {
  HibpBreachChecker(
      {http.Client? client, this.timeout = const Duration(seconds: 4)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  static final _endpoint = Uri.parse('https://api.pwnedpasswords.com/range/');

  @override
  Future<bool> isBreached(String password) async {
    final hash = sha1.convert(utf8.encode(password)).toString().toUpperCase();
    final prefix = hash.substring(0, 5);
    final suffix = hash.substring(5);

    try {
      final response = await _client.get(
        _endpoint.resolve(prefix),
        headers: const {'Add-Padding': 'true'},
      ).timeout(timeout);
      if (response.statusCode != 200) return false;
      return containsSuffix(response.body, suffix);
    } catch (_) {
      return false;
    }
  }

  /// Parses a `SUFFIX:COUNT` list. Padded entries have a count of zero.
  static bool containsSuffix(String body, String suffix) {
    for (final line in const LineSplitter().convert(body)) {
      final parts = line.trim().split(':');
      if (parts.length != 2) continue;
      if (parts[0] == suffix) return (int.tryParse(parts[1]) ?? 0) > 0;
    }
    return false;
  }
}
