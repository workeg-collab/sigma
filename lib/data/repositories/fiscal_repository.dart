import 'package:sqflite/sqflite.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/fiscal_year.dart';

class FiscalRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  FiscalRepository({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  Future<List<FiscalYear>> getAllFiscalYears() async {
    final db = await _db;
    final result = await db.query('fiscal_years', orderBy: 'start_date DESC');
    return result.map((e) => FiscalYear.fromMap(e)).toList();
  }

  Future<FiscalYear?> getActiveFiscalYear() async {
    final db = await _db;
    final result = await db.query('fiscal_years', where: 'is_closed = 0', orderBy: 'start_date DESC', limit: 1);
    if (result.isEmpty) return null;
    return FiscalYear.fromMap(result.first);
  }

  Future<List<AccountingPeriod>> getPeriodsForFiscalYear(int fiscalYearId) async {
    final db = await _db;
    final result = await db.query(
      'accounting_periods',
      where: 'fiscal_year_id = ?',
      whereArgs: [fiscalYearId],
      orderBy: 'period_number ASC',
    );
    return result.map((e) => AccountingPeriod.fromMap(e)).toList();
  }

  /// Validates whether a specific transaction date falls within an open accounting period
  Future<bool> isDateInOpenPeriod(String dateStr) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT p.id, p.is_closed, f.is_closed as fy_closed
      FROM accounting_periods p
      JOIN fiscal_years f ON p.fiscal_year_id = f.id
      WHERE ? >= p.start_date AND ? <= p.end_date
    ''', [dateStr, dateStr]);

    if (result.isEmpty) {
      // If no period covers this date, check if active fiscal year covers it
      final fyResult = await db.rawQuery('''
        SELECT id, is_closed FROM fiscal_years
        WHERE ? >= start_date AND ? <= end_date
      ''', [dateStr, dateStr]);
      if (fyResult.isEmpty) return false;
      return (fyResult.first['is_closed'] as int? ?? 0) == 0;
    }

    final pClosed = (result.first['is_closed'] as int? ?? 0) == 1;
    final fClosed = (result.first['fy_closed'] as int? ?? 0) == 1;

    return !pClosed && !fClosed;
  }

  Future<void> togglePeriodClosed(int periodId, bool close, {String? username}) async {
    final db = await _db;
    await db.update(
      'accounting_periods',
      {
        'is_closed': close ? 1 : 0,
        'closed_at': close ? DateTime.now().toIso8601String() : null,
        'closed_by': close ? username : null,
      },
      where: 'id = ?',
      whereArgs: [periodId],
    );
  }

  Future<void> toggleFiscalYearClosed(int fiscalYearId, bool close) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update(
        'fiscal_years',
        {'is_closed': close ? 1 : 0},
        where: 'id = ?',
        whereArgs: [fiscalYearId],
      );
      if (close) {
        // Also close all monthly periods in this fiscal year
        await txn.update(
          'accounting_periods',
          {
            'is_closed': 1,
            'closed_at': DateTime.now().toIso8601String(),
          },
          where: 'fiscal_year_id = ?',
          whereArgs: [fiscalYearId],
        );
      }
    });
  }

  Future<int> createFiscalYear(FiscalYear fy) async {
    final db = await _db;
    return await db.insert('fiscal_years', fy.toMap());
  }
}
