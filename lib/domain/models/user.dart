class User {
  final int? id;
  final String username;
  final String fullName;
  final String? email;
  final String passwordHash;
  final int roleId;
  final bool isActive;
  final String? lastLoginAt;
  final String? roleName;
  final List<String> permissions;

  User({
    this.id,
    required this.username,
    required this.fullName,
    this.email,
    required this.passwordHash,
    required this.roleId,
    this.isActive = true,
    this.lastLoginAt,
    this.roleName,
    this.permissions = const [],
  });

  bool hasPermission(String permission) {
    if (roleName == 'Administrator') return true;
    return permissions.contains(permission);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'role_id': roleId,
      'is_active': isActive ? 1 : 0,
      'last_login_at': lastLoginAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map, {List<String> permissions = const []}) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      email: map['email'] as String?,
      passwordHash: map['password_hash'] as String? ?? '',
      roleId: map['role_id'] as int? ?? 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      lastLoginAt: map['last_login_at'] as String?,
      roleName: map['role_name'] as String?,
      permissions: permissions,
    );
  }
}
