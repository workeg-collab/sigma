import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/account.dart';

class AccountRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  AccountRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  Future<List<Account>> getAllAccounts({bool activeOnly = false, String? search}) async {
    final db = await _db;
    String whereClause = activeOnly ? 'WHERE is_active = 1' : '';
    List<dynamic> args = [];

    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      if (whereClause.isEmpty) {
        whereClause = 'WHERE (code LIKE ? OR name LIKE ? OR name_ar LIKE ?)';
      } else {
        whereClause += ' AND (code LIKE ? OR name LIKE ? OR name_ar LIKE ?)';
      }
      args.addAll([s, s, s]);
    }

    final result = await db.rawQuery(
      'SELECT * FROM accounts $whereClause ORDER BY code ASC',
      args,
    );

    return result.map((e) => Account.fromMap(e)).toList();
  }

  Future<Account?> getAccountById(int id) async {
    final db = await _db;
    final result = await db.query('accounts', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Account.fromMap(result.first);
  }

  Future<Account?> getAccountByCode(String code) async {
    final db = await _db;
    final result = await db.query('accounts', where: 'code = ?', whereArgs: [code]);
    if (result.isEmpty) return null;
    return Account.fromMap(result.first);
  }

  Future<int> createAccount(Account account) async {
    final db = await _db;
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(Account account) async {
    final db = await _db;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Checks if account has any posted or draft journal transactions
  Future<bool> hasTransactions(int accountId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_lines WHERE account_id = ?',
      [accountId],
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  /// Deactivates account (soft delete)
  Future<void> deactivateAccount(int accountId) async {
    final db = await _db;
    await db.update('accounts', {'is_active': 0}, where: 'id = ?', whereArgs: [accountId]);
  }

  /// Activates account
  Future<void> activateAccount(int accountId) async {
    final db = await _db;
    await db.update('accounts', {'is_active': 1}, where: 'id = ?', whereArgs: [accountId]);
  }

  /// Deletes account only if no transactions exist; otherwise throws an exception
  Future<void> deleteAccount(int accountId) async {
    final hasTx = await hasTransactions(accountId);
    if (hasTx) {
      throw Exception('لا يمكن حذف الحساب نظراً لوجود قيود وحركات مالية مسجلة عليه. تم تعطيل الحساب بدلاً من ذلك.');
    }
    final db = await _db;
    await db.delete('accounts', where: 'id = ?', whereArgs: [accountId]);
  }

  Future<List<AccountGroup>> getAllGroups() async {
    final db = await _db;
    final result = await db.query('account_groups', orderBy: 'code ASC');
    return result.map((e) => AccountGroup.fromMap(e)).toList();
  }
}
