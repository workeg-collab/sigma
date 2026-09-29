import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/analytical_item.dart';
import '../../domain/models/unit.dart';

class AnalyticalRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  AnalyticalRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  // Analytical Items
  Future<List<AnalyticalItem>> getAllAnalyticalItems({bool activeOnly = false, String? category, String? search}) async {
    final db = await _db;
    List<String> conditions = [];
    List<dynamic> args = [];

    if (activeOnly) conditions.add('is_active = 1');
    if (category != null && category.isNotEmpty && category != 'all') {
      conditions.add('category = ?');
      args.add(category);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      conditions.add('(code LIKE ? OR name LIKE ? OR category LIKE ?)');
      args.addAll([s, s, s]);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final res = await db.rawQuery('SELECT * FROM analytical_items $where ORDER BY code ASC', args);
    return res.map((e) => AnalyticalItem.fromMap(e)).toList();
  }

  Future<int> createAnalyticalItem(AnalyticalItem item) async {
    final db = await _db;
    return await db.insert('analytical_items', item.toMap());
  }

  Future<int> updateAnalyticalItem(AnalyticalItem item) async {
    final db = await _db;
    return await db.update('analytical_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  // Units
  Future<List<Unit>> getAllUnits({bool activeOnly = false}) async {
    final db = await _db;
    final where = activeOnly ? 'WHERE is_active = 1' : '';
    final res = await db.rawQuery('SELECT * FROM units $where ORDER BY code ASC');
    return res.map((e) => Unit.fromMap(e)).toList();
  }

  Future<int> createUnit(Unit unit) async {
    final db = await _db;
    return await db.insert('units', unit.toMap());
  }

  Future<int> updateUnit(Unit unit) async {
    final db = await _db;
    return await db.update('units', unit.toMap(), where: 'id = ?', whereArgs: [unit.id]);
  }
}
