enum UserRole {
  student,
  professor,
  admin;

  String get label => switch (this) {
        UserRole.student => 'Student',
        UserRole.professor => 'Professor',
        UserRole.admin => 'Admin',
      };

  bool get isAdmin => this == UserRole.admin;

  bool get canManageAnnouncements =>
      this == UserRole.professor || this == UserRole.admin;

  static UserRole parse(String? value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.student,
      );
}
