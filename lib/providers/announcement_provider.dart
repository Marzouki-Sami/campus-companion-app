import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../services/firestore_service.dart';

/// Manages announcements list.
class AnnouncementProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAnnouncements() async {
    _setLoading(true);
    try {
      _announcements = await _firestoreService.fetchAnnouncements();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load announcements';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addOrUpdateAnnouncement(Announcement announcement) async {
    _setLoading(true);
    try {
      await _firestoreService.saveAnnouncement(announcement);
      await loadAnnouncements(); // Reload to get updated list
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to save announcement';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteAnnouncement(announcementId);
      await loadAnnouncements(); // Reload to get updated list
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to delete announcement';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


