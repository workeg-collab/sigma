import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/party.dart';

class PartyRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  PartyRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  // Suppliers
  Future<List<Supplier>> getAllSuppliers({bool activeOnly = false, String? search}) async {
    final db = await _db;
    String where = activeOnly ? 'WHERE is_active = 1' : '';
    List<dynamic> args = [];
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      where += where.isEmpty ? 'WHERE ' : ' AND ';
      where += '(code LIKE ? OR name LIKE ? OR phone LIKE ?)';
      args.addAll([s, s, s]);
    }
    final res = await db.rawQuery('SELECT * FROM suppliers $where ORDER BY code ASC', args);
    return res.map((e) => Supplier.fromMap(e)).toList();
  }

  Future<int> createSupplier(Supplier s) async {
    final db = await _db;
    return await db.insert('suppliers', s.toMap());
  }

  Future<int> updateSupplier(Supplier s) async {
    final db = await _db;
    return await db.update('suppliers', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  // Customers
  Future<List<Customer>> getAllCustomers({bool activeOnly = false, String? search}) async {
    final db = await _db;
    String where = activeOnly ? 'WHERE is_active = 1' : '';
    List<dynamic> args = [];
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      where += where.isEmpty ? 'WHERE ' : ' AND ';
      where += '(code LIKE ? OR name LIKE ? OR phone LIKE ?)';
      args.addAll([s, s, s]);
    }
    final res = await db.rawQuery('SELECT * FROM customers $where ORDER BY code ASC', args);
    return res.map((e) => Customer.fromMap(e)).toList();
  }

  Future<int> createCustomer(Customer c) async {
    final db = await _db;
    return await db.insert('customers', c.toMap());
  }

  Future<int> updateCustomer(Customer c) async {
    final db = await _db;
    return await db.update('customers', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }
}
