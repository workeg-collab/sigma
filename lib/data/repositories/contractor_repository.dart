import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/party.dart';

class ContractorRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  ContractorRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  Future<List<Contractor>> getAllContractors({bool activeOnly = false, int? projectId, String? search}) async {
    final db = await _db;
    List<String> conditions = [];
    List<dynamic> args = [];

    if (activeOnly) {
      conditions.add('c.is_active = 1');
    }
    if (projectId != null && projectId > 0) {
      conditions.add('c.project_id = ?');
      args.add(projectId);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      conditions.add('(c.code LIKE ? OR c.name LIKE ? OR c.phone LIKE ?)');
      args.addAll([s, s, s]);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final result = await db.rawQuery('''
      SELECT c.*, p.name as project_name
      FROM contractors c
      LEFT JOIN projects p ON c.project_id = p.id
      $where
      ORDER BY c.code ASC
    ''', args);

    return result.map((e) => Contractor.fromMap(e)).toList();
  }

  Future<Contractor?> getContractorById(int id) async {
    final db = await _db;
    final result = await db.query('contractors', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Contractor.fromMap(result.first);
  }

  Future<int> createContractor(Contractor contractor) async {
    final db = await _db;
    return await db.insert('contractors', contractor.toMap());
  }

  Future<int> updateContractor(Contractor contractor) async {
    final db = await _db;
    return await db.update('contractors', contractor.toMap(), where: 'id = ?', whereArgs: [contractor.id]);
  }

  Future<void> deleteContractor(int id) async {
    final db = await _db;
    final res = await db.rawQuery('SELECT COUNT(*) as count FROM journal_lines WHERE contractor_id = ?', [id]);
    final count = Sqflite.firstIntValue(res) ?? 0;
    if (count > 0) {
      throw Exception('لا يمكن حذف المقاول لوجود معاملات مالية مسجلة له. يمكنك تعطيل حسابه بدلاً من ذلك.');
    }
    await db.delete('contractors', where: 'id = ?', whereArgs: [id]);
  }
}
