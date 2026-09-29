import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../domain/models/journal_entry.dart';
import '../../domain/models/journal_line.dart';
import 'fiscal_repository.dart';

class JournalRepository {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;
  final FiscalRepository _fiscalRepo;

  JournalRepository({DatabaseHelper? dbHelper, Database? overrideDb, FiscalRepository? fiscalRepo})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb,
        _fiscalRepo = fiscalRepo ?? FiscalRepository(dbHelper: dbHelper, overrideDb: overrideDb);

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  /// Generates the next sequential entry number e.g. 10001, 10002...
  Future<String> getNextEntryNumber() async {
    final db = await _db;
    final res = await db.rawQuery('SELECT MAX(id) as max_id FROM journal_entries');
    final maxId = Sqflite.firstIntValue(res) ?? 0;
    final nextId = maxId + 1;
    return 'JE-${nextId.toString().padLeft(5, '0')}';
  }

  Future<List<JournalEntry>> getJournalEntries({
    String? dateFrom,
    String? dateTo,
    int? projectId,
    String? status,
    String? search,
    int limit = 200,
    int offset = 0,
  }) async {
    final db = await _db;
    List<String> conditions = [];
    List<dynamic> args = [];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add('je.date >= ?');
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add('je.date <= ?');
      args.add(dateTo);
    }
    if (projectId != null && projectId > 0) {
      conditions.add('je.project_id = ?');
      args.add(projectId);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      conditions.add('je.status = ?');
      args.add(status);
    }
    if (search != null && search.trim().isNotEmpty) {
      final s = '%${search.trim()}%';
      conditions.add('(je.entry_number LIKE ? OR je.description LIKE ? OR je.reference_number LIKE ?)');
      args.addAll([s, s, s]);
    }

    final where = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';
    final query = '''
      SELECT je.*, p.name as project_name
      FROM journal_entries je
      LEFT JOIN projects p ON je.project_id = p.id
      $where
      ORDER BY je.date DESC, je.id DESC
      LIMIT ? OFFSET ?
    ''';

    final result = await db.rawQuery(query, [...args, limit, offset]);

    List<JournalEntry> entries = [];
    for (var row in result) {
      final entryId = row['id'] as int;
      // Fetch lines for this entry
      final lines = await getLinesForEntry(entryId);
      entries.add(JournalEntry.fromMap(row, lines: lines));
    }

    return entries;
  }

  Future<List<JournalLine>> getLinesForEntry(int entryId) async {
    final db = await _db;
    final query = '''
      SELECT jl.*,
             a.code as account_code, a.name_ar as account_name_ar,
             p.name as project_name,
             an.name as analytical_name,
             u.name as unit_name,
             c.name as contractor_name,
             s.name as supplier_name,
             cust.name as customer_name
      FROM journal_lines jl
      LEFT JOIN accounts a ON jl.account_id = a.id
      LEFT JOIN projects p ON jl.project_id = p.id
      LEFT JOIN analytical_items an ON jl.analytical_item_id = an.id
      LEFT JOIN units u ON jl.unit_id = u.id
      LEFT JOIN contractors c ON jl.contractor_id = c.id
      LEFT JOIN suppliers s ON jl.supplier_id = s.id
      LEFT JOIN customers cust ON jl.customer_id = cust.id
      WHERE jl.journal_entry_id = ?
      ORDER BY jl.line_number ASC
    ''';
    final linesResult = await db.rawQuery(query, [entryId]);
    return linesResult.map((e) => JournalLine.fromMap(e)).toList();
  }

  Future<JournalEntry?> getJournalEntryById(int id) async {
    final db = await _db;
    final res = await db.rawQuery('''
      SELECT je.*, p.name as project_name
      FROM journal_entries je
      LEFT JOIN projects p ON je.project_id = p.id
      WHERE je.id = ?
    ''', [id]);

    if (res.isEmpty) return null;
    final lines = await getLinesForEntry(id);
    return JournalEntry.fromMap(res.first, lines: lines);
  }

  /// Creates a new journal entry with lines inside a single database transaction
  Future<int> createJournalEntry(JournalEntry entry) async {
    final db = await _db;

    // Check open period
    final isOpen = await _fiscalRepo.isDateInOpenPeriod(entry.date);
    if (!isOpen && entry.status == JournalStatus.posted) {
      throw Exception('لا يمكن ترحيل قيد في فترة مالية مغلقة أو خارج السنة المالية الحالية.');
    }

    if (entry.status == JournalStatus.posted) {
      _validateForPosting(entry);
    }

    return await db.transaction((txn) async {
      final entryMap = entry.toMap();
      if (entryMap['created_at'] == null || (entryMap['created_at'] as String).isEmpty) {
        entryMap['created_at'] = DateTime.now().toIso8601String();
      }

      final entryId = await txn.insert('journal_entries', entryMap);

      for (int i = 0; i < entry.lines.length; i++) {
        final line = entry.lines[i];
        final lineMap = line.toMap();
        lineMap['journal_entry_id'] = entryId;
        lineMap['line_number'] = i + 1;
        await txn.insert('journal_lines', lineMap);
      }

      return entryId;
    });
  }

  /// Updates an existing draft journal entry
  Future<void> updateDraftJournalEntry(JournalEntry entry) async {
    final db = await _db;

    final existing = await getJournalEntryById(entry.id!);
    if (existing == null) {
      throw Exception('قيد اليومية غير موجود.');
    }

    if (existing.status != JournalStatus.draft) {
      throw Exception('لا يمكن تعديل القيود بعد ترحيلها أو إلغائها.');
    }

    await db.transaction((txn) async {
      await txn.update(
        'journal_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );

      // Replace lines
      await txn.delete('journal_lines', where: 'journal_entry_id = ?', whereArgs: [entry.id]);

      for (int i = 0; i < entry.lines.length; i++) {
        final line = entry.lines[i];
        final lineMap = line.toMap();
        lineMap['journal_entry_id'] = entry.id;
        lineMap['line_number'] = i + 1;
        await txn.insert('journal_lines', lineMap);
      }
    });
  }

  /// Posts a draft journal entry (changes status to 'posted')
  Future<void> postJournalEntry(int entryId, {required String postedBy}) async {
    final entry = await getJournalEntryById(entryId);
    if (entry == null) {
      throw Exception('قيد اليومية غير موجود.');
    }

    if (entry.status == JournalStatus.posted) {
      throw Exception('هذا القيد مرحل بالفعل.');
    }

    if (entry.status == JournalStatus.cancelled) {
      throw Exception('لا يمكن ترحيل قيد ملغي.');
    }

    // Validate period
    final isOpen = await _fiscalRepo.isDateInOpenPeriod(entry.date);
    if (!isOpen) {
      throw Exception('لا يمكن ترحيل القيد لأن تاريخ المعاملة يقع في فترة مالية مغلقة.');
    }

    // Validate double-entry rules
    _validateForPosting(entry);

    final db = await _db;
    await db.update(
      'journal_entries',
      {
        'status': JournalStatus.posted,
        'posted_by': postedBy,
        'posted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Cancels a journal entry (soft cancel, retains audit trail, never deletes)
  Future<void> cancelJournalEntry(int entryId, {required String cancelledBy, required String reason}) async {
    final entry = await getJournalEntryById(entryId);
    if (entry == null) {
      throw Exception('قيد اليومية غير موجود.');
    }

    final db = await _db;
    await db.update(
      'journal_entries',
      {
        'status': JournalStatus.cancelled,
        'cancelled_by': cancelledBy,
        'cancelled_at': DateTime.now().toIso8601String(),
        'cancel_reason': reason,
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  /// Deletes a draft entry permanently (only drafts are allowed to be deleted)
  Future<void> deleteDraftEntry(int entryId) async {
    final entry = await getJournalEntryById(entryId);
    if (entry == null) return;

    if (entry.status != JournalStatus.draft) {
      throw Exception('لا يمكن حذف القيود المرحّلة إطلاقاً للحفاظ على سلامة الدفاتر المحاسبية. يمكنك إلغاء القيد بدلاً من ذلك.');
    }

    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('journal_lines', where: 'journal_entry_id = ?', whereArgs: [entryId]);
      await txn.delete('journal_entries', where: 'id = ?', whereArgs: [entryId]);
    });
  }

  void _validateForPosting(JournalEntry entry) {
    if (entry.lines.length < 2) {
      throw Exception('يجب أن يحتوي القيد على سطرين على الأقل للترحيل.');
    }

    if (!entry.isBalanced) {
      throw Exception('القيد غير متزن! إجمالي المدين (${entry.totalDebit}) لا يساوي إجمالي الدائن (${entry.totalCredit}). الفرق: ${entry.difference}');
    }

    for (int i = 0; i < entry.lines.length; i++) {
      final line = entry.lines[i];
      final lineNum = i + 1;

      if (line.accountId <= 0) {
        throw Exception('السطر رقم $lineNum: يجب اختيار حساب مالي.');
      }

      if (line.debit > 0 && line.credit > 0) {
        throw Exception('السطر رقم $lineNum: لا يمكن أن يحتوي السطر على مدين ودائن معاً أكبر من الصفر.');
      }

      if (line.debit <= 0 && line.credit <= 0) {
        throw Exception('السطر رقم $lineNum: يجب إدخال قيمة في المدين أو الدائن.');
      }

      if (line.debit < 0 || line.credit < 0) {
        throw Exception('السطر رقم $lineNum: لا يمكن إدخال مبالغ سالبة.');
      }
    }
  }
}
