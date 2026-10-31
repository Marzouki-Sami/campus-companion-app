import 'package:flutter/foundation.dart';

import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/core/services/firestore_service.dart';

/// Manages the list of tasks for the current user.
class TaskProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTasks(String userId) async {
    _setLoading(true);
    try {
      _tasks = await _firestoreService.fetchTasks(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load tasks';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addOrUpdateTask(String userId, Task task) async {
    _setLoading(true);
    try {
      await _firestoreService.saveTask(userId, task);
      await loadTasks(userId);
    } catch (e) {
      _errorMessage = 'Failed to save task';
      _setLoading(false);
    }
  }

  Future<void> deleteTask(String userId, Task task) async {
    _setLoading(true);
    try {
      await _firestoreService.deleteTask(userId, task.id);
      await loadTasks(userId);
    } catch (e) {
      _errorMessage = 'Failed to delete task';
      _setLoading(false);
    }
  }

  /// Simple “AI-like” suggestion based on category.
  /// This is optional and purely rule-based for demonstration.
  String suggestTaskByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'exam':
        return 'Review lecture notes and solve 3 past paper questions.';
      case 'assignment':
        return 'Break assignment into smaller subtasks and finish one today.';
      case 'personal':
        return 'Take a short walk and plan your week for 10 minutes.';
      default:
        return 'Start with the smallest, easiest task to build momentum.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


