import 'package:campus_companion/features/auth/domain/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.role = UserRole.student,
    this.isSuspended = false,
  });

  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final bool isSuspended;

  AppUser copyWith({
    String? displayName,
    UserRole? role,
    bool? isSuspended,
  }) {
    return AppUser(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}
