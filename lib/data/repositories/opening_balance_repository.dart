import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/opening_balance.dart';

class OpeningBalanceRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  OpeningBalanceRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  Future<List<OpeningBalance>> getOpeningBalances(int fiscalYearId) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT ob.*,
             a.code as account_code, a.name_ar as account_name_ar,
             p.name as project_name,
             an.name as analytical_name
      FROM opening_balances ob
      JOIN accounts a ON ob.account_id = a.id
      LEFT JOIN projects p ON ob.project_id = p.id
      LEFT JOIN analytical_items an ON ob.analytical_item_id = an.id
      WHERE ob.fiscal_year_id = ?
      ORDER BY a.code ASC
    ''', [fiscalYearId]);

    return res.map((e) => OpeningBalance.fromMap(e)).toList();
  }

  Future<void> saveOpeningBalances(int fiscalYearId, List<OpeningBalance> list) async {
    double totalDebit = 0.0;
    double totalCredit = 0.0;
    for (var item in list) {
      totalDebit += item.debit;
      totalCredit += item.credit;
    }

    if ((totalDebit - totalCredit).abs() > 0.0001) {
      throw Exception('الأرصدة الافتتاحية غير متزنة! إجمالي المدين ($totalDebit) لا يساوي إجمالي الدائن ($totalCredit).');
    }

    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('opening_balances', where: 'fiscal_year_id = ?', whereArgs: [fiscalYearId]);
      for (var item in list) {
        if (item.debit > 0 || item.credit > 0) {
          await txn.insert('opening_balances', item.toMap());
        }
      }
    });
  }
}
