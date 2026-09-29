import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/role_permission.dart';
import '../../domain/models/user.dart';

class UserRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  UserRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<User?> authenticate(String username, String password) async {
    final db = await _db;
    final pwdHash = hashPassword(password);

    final res = await db.rawQuery('''
      SELECT u.*, r.name as role_name
      FROM users u
      JOIN roles r ON u.role_id = r.id
      WHERE LOWER(u.username) = LOWER(?) AND u.password_hash = ? AND u.is_active = 1
    ''', [username.trim(), pwdHash]);

    if (res.isEmpty) return null;

    final userMap = res.first;
    final userId = userMap['id'] as int;
    final roleId = userMap['role_id'] as int;

    // Fetch permissions
    final permRes = await db.query(
      'permissions',
      where: 'role_id = ? AND is_granted = 1',
      whereArgs: [roleId],
    );
    final perms = permRes.map((p) => p['permission_key'] as String).toList();

    // Update last login
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );

    return User.fromMap(userMap, permissions: perms);
  }

  Future<List<User>> getAllUsers() async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT u.*, r.name as role_name
      FROM users u
      JOIN roles r ON u.role_id = r.id
      ORDER BY u.id ASC
    ''');
    return res.map((e) => User.fromMap(e)).toList();
  }

  Future<int> createUser(User user, String rawPassword) async {
    final db = await _db;
    final map = user.toMap();
    map['password_hash'] = hashPassword(rawPassword);
    return await db.insert('users', map);
  }

  Future<int> updateUser(User user, {String? newRawPassword}) async {
    final db = await _db;
    final map = user.toMap();
    if (newRawPassword != null && newRawPassword.trim().isNotEmpty) {
      map['password_hash'] = hashPassword(newRawPassword.trim());
    }
    return await db.update('users', map, where: 'id = ?', whereArgs: [user.id]);
  }

  Future<List<Role>> getAllRoles() async {
    final db = await _db;
    final res = await db.query('roles', orderBy: 'id ASC');
    return res.map((e) => Role.fromMap(e)).toList();
  }

  Future<List<String>> getPermissionsForRole(int roleId) async {
    final db = await _db;
    final res = await db.query(
      'permissions',
      where: 'role_id = ? AND is_granted = 1',
      whereArgs: [roleId],
    );
    return res.map((e) => e['permission_key'] as String).toList();
  }

  Future<void> updateRolePermissions(int roleId, List<String> grantedKeys) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('permissions', where: 'role_id = ?', whereArgs: [roleId]);
      for (final key in grantedKeys) {
        await txn.insert('permissions', {
          'role_id': roleId,
          'permission_key': key,
          'is_granted': 1,
        });
      }
    });
  }
}
