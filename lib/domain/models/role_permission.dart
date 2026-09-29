class Role {
  final int? id;
  final String code;
  final String name;
  final String? description;
  final bool isSystem;

  Role({
    this.id,
    required this.code,
    required this.name,
    this.description,
    this.isSystem = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'is_system': isSystem ? 1 : 0,
    };
  }

  factory Role.fromMap(Map<String, dynamic> map) {
    return Role(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      isSystem: (map['is_system'] as int? ?? 0) == 1,
    );
  }
}

class Permission {
  final int? id;
  final int roleId;
  final String permissionKey;
  final bool isGranted;

  Permission({
    this.id,
    required this.roleId,
    required this.permissionKey,
    this.isGranted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role_id': roleId,
      'permission_key': permissionKey,
      'is_granted': isGranted ? 1 : 0,
    };
  }

  factory Permission.fromMap(Map<String, dynamic> map) {
    return Permission(
      id: map['id'] as int?,
      roleId: map['role_id'] as int? ?? 0,
      permissionKey: map['permission_key'] as String? ?? '',
      isGranted: (map['is_granted'] as int? ?? 1) == 1,
    );
  }
}
