import 'package:flutter/foundation.dart';

import 'package:campus_companion/core/errors/app_exception.dart';

/// Shared loading/error handling for [ChangeNotifier]-based providers.
mixin LoadingStateMixin on ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Runs [action] while exposing loading and error state.
  ///
  /// Returns `true` on success. [AppException] messages are surfaced as-is;
  /// any other error is replaced by [failureMessage].
  @protected
  Future<bool> runGuarded(
    Future<void> Function() action, {
    required String failureMessage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = failureMessage;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
