import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/audit_log.dart';

class AuditRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  AuditRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  Future<void> log({
    int? userId,
    required String username,
    required String action,
    required String recordType,
    String? recordId,
    String? details,
    String? oldValues,
    String? newValues,
  }) async {
    final db = await _db;
    await db.insert('audit_logs', {
      'user_id': userId,
      'username': username,
      'action': action,
      'record_type': recordType,
      'record_id': recordId,
      'details': details,
      'old_values': oldValues,
      'new_values': newValues,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AuditLog>> getLogs({String? recordType, String? action, String? search, int limit = 100}) async {
    final db = await _db;
    List<String> conditions = [];
    List<dynamic> args = [];

    if (recordType != null && recordType.isNotEmpty && recordType != 'all') {
      conditions.add('record_type = ?');
      args.add(recordType);
    }
    if (action != null && action.isNotEmpty && action != 'all') {
      conditions.add('action = ?');
      args.add(action);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      conditions.add('(username LIKE ? OR details LIKE ? OR record_id LIKE ?)');
      args.addAll([s, s, s]);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final res = await db.rawQuery('''
      SELECT * FROM audit_logs $where ORDER BY created_at DESC LIMIT ?
    ''', [...args, limit]);

    return res.map((e) => AuditLog.fromMap(e)).toList();
  }
}
