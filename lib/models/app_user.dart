class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String role; // 'student', 'professor', 'admin'

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.role = 'student',
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      role: data['role'] as String? ?? 'student',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
    };
  }
}


