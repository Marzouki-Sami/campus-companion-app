import 'package:flutter/foundation.dart';

/// Whether the screens are currently showing saved data because the network
/// is unreachable. Repositories flip it; the UI shows a banner.
class OfflineState extends ChangeNotifier {
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  void markOffline() => _set(true);

  void markOnline() => _set(false);

  void _set(bool value) {
    if (value == _isOffline) return;
    _isOffline = value;
    notifyListeners();
  }
}
