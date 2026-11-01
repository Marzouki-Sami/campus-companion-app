import 'dart:async';

import 'package:campus_companion/core/errors/app_exception.dart';
import 'package:campus_companion/features/announcements/domain/announcement.dart';
import 'package:campus_companion/features/announcements/domain/announcement_image.dart';
import 'package:campus_companion/features/announcements/domain/announcement_repository.dart';
import 'package:campus_companion/features/auth/domain/app_user.dart';
import 'package:campus_companion/features/auth/domain/auth_repository.dart';
import 'package:campus_companion/features/tasks/domain/task.dart';
import 'package:campus_companion/features/tasks/domain/task_repository.dart';

class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository(this.items, {Set<String> read = const {}})
      : readIds = {...read};

  final List<Announcement> items;
  final Set<String> readIds;
  bool failMarkRead = false;

  @override
  Future<List<Announcement>> fetchAll() async => List.of(items);

  @override
  Future<void> save(
    Announcement announcement, {
    List<NewImage> newImages = const [],
  }) async {}

  @override
  Future<void> delete(String id) async => items.removeWhere((a) => a.id == id);

  @override
  Future<Set<String>> fetchReadIds() async => {...readIds};

  @override
  Future<void> markRead(Iterable<String> ids) async {
    if (failMarkRead) throw const AppException('offline');
    readIds.addAll(ids);
  }
}

class FakeUserRepository implements UserRepository {
  FakeUserRepository(List<AppUser> users) : users = List.of(users);

  final List<AppUser> users;
  AppException? deleteError;

  @override
  Future<AppUser> fetchById(String id) async =>
      users.firstWhere((u) => u.id == id);

  @override
  Future<List<AppUser>> fetchAll() async => List.of(users);

  @override
  Future<void> save(AppUser user) async {
    final i = users.indexWhere((u) => u.id == user.id);
    users[i] = user;
  }

  @override
  Future<void> delete(String id) async {
    if (deleteError != null) throw deleteError!;
    users.removeWhere((u) => u.id == id);
  }
}

class FakeTaskRepository implements TaskRepository {
  final Map<String, List<Task>> _store = {};
  bool shouldFail = false;
  int _nextId = 1;

  void _check() {
    if (shouldFail) throw StateError('backend down');
  }

  @override
  Future<List<Task>> fetchAll(String userId) async {
    _check();
    return List.unmodifiable(_store[userId] ?? const []);
  }

  @override
  Future<void> save(String userId, Task task) async {
    _check();
    final tasks = _store.putIfAbsent(userId, () => []);
    if (task.id.isEmpty) {
      tasks.add(task.copyWith(id: 't${_nextId++}'));
      return;
    }
    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
  }

  @override
  Future<void> delete(String userId, String taskId) async {
    _check();
    _store[userId]?.removeWhere((t) => t.id == taskId);
  }
}

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;
  Object? error;

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;

  @override
  bool get isSignedIn => _user != null;

  void emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    if (unverifiedEmails.contains(email)) {
      throw EmailNotVerifiedException(email);
    }
    return _user = AppUser(id: 'u1', email: email);
  }

  /// When true, sign-up behaves like a project that requires email
  /// verification: no session until [verifyEmail] succeeds.
  bool requireVerification = false;

  /// Emails that sign-in rejects as unverified.
  final unverifiedEmails = <String>{};

  final resendCalls = <String>[];
  final resetRequests = <String>[];

  @override
  Future<AppUser?> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (error != null) throw error!;
    if (requireVerification) {
      unverifiedEmails.add(email);
      return null;
    }
    return _user = AppUser(id: 'u2', email: email, displayName: displayName);
  }

  @override
  Future<AppUser> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (error != null) throw error!;
    unverifiedEmails.remove(email);
    return _user = AppUser(id: 'u3', email: email);
  }

  @override
  Future<void> resendVerification(String email) async {
    resendCalls.add(email);
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    resetRequests.add(email);
  }

  @override
  Future<AppUser> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    if (error != null) throw error!;
    return _user = AppUser(id: 'u4', email: email);
  }

  @override
  Future<void> signOut() async {
    emit(null);
  }

  /// Set to make [reloadCurrentUser] behave like a suspended or offline account.
  Object? reloadError;

  @override
  Future<AppUser> reloadCurrentUser() async {
    if (reloadError != null) throw reloadError!;
    return _user!;
  }

  @override
  Future<AppUser> updateDisplayName(AppUser user, String displayName) async {
    return _user = user.copyWith(displayName: displayName);
  }
}

AppException get invalidCredentials =>
    const AppException('Invalid email or password');
