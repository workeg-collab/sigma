import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../models/account.dart';
import '../models/project.dart';
import '../models/party.dart';
import '../models/report_models.dart';

class AccountingEngine {
  final DatabaseHelper _dbHelper;
  final Database? _overrideDb;

  AccountingEngine({DatabaseHelper? dbHelper, Database? overrideDb})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _overrideDb = overrideDb;

  Future<Database> get _db async => _overrideDb ?? await _dbHelper.database;

  // ==========================================
  // 1. ACCOUNT BALANCES & GENERAL LEDGER
  // ==========================================

  /// Calculates real-time balance for all accounts from posted journal entries and opening balances
  Future<List<Account>> getAccountsWithBalances({
    String? dateFrom,
    String? dateTo,
    int? projectId,
  }) async {
    final db = await _db;
    List<String> lineConditions = ["je.status = 'posted'"];
    List<dynamic> lineArgs = [];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      lineConditions.add("je.date >= ?");
      lineArgs.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      lineConditions.add("je.date <= ?");
      lineArgs.add(dateTo);
    }
    if (projectId != null && projectId > 0) {
      lineConditions.add("jl.project_id = ?");
      lineArgs.add(projectId);
    }

    final lineWhere = "WHERE ${lineConditions.join(' AND ')}";

    final accountsSql = '''
      SELECT a.*,
             COALESCE(mov.total_debit, 0.0) as mov_debit,
             COALESCE(mov.total_credit, 0.0) as mov_credit,
             COALESCE(op.op_debit, 0.0) as op_debit,
             COALESCE(op.op_credit, 0.0) as op_credit
      FROM accounts a
      LEFT JOIN (
        SELECT jl.account_id,
               SUM(jl.debit) as total_debit,
               SUM(jl.credit) as total_credit
        FROM journal_lines jl
        JOIN journal_entries je ON jl.journal_entry_id = je.id
        $lineWhere
        GROUP BY jl.account_id
      ) mov ON a.id = mov.account_id
      LEFT JOIN (
        SELECT account_id,
               SUM(debit) as op_debit,
               SUM(credit) as op_credit
        FROM opening_balances
        GROUP BY account_id
      ) op ON a.id = op.account_id
      WHERE a.is_active = 1
      ORDER BY a.code ASC
    ''';

    final result = await db.rawQuery(accountsSql, lineArgs);

    return result.map((row) {
      final acc = Account.fromMap(row);
      final movDebit = (row['mov_debit'] as num?)?.toDouble() ?? 0.0;
      final movCredit = (row['mov_credit'] as num?)?.toDouble() ?? 0.0;
      final opDebit = (row['op_debit'] as num?)?.toDouble() ?? 0.0;
      final opCredit = (row['op_credit'] as num?)?.toDouble() ?? 0.0;

      final totalDebit = opDebit + movDebit;
      final totalCredit = opCredit + movCredit;

      // Net balance according to normal balance nature
      final double balance = (acc.normalBalance == NormalBalance.debit)
          ? (totalDebit - totalCredit)
          : (totalCredit - totalDebit);

      return acc.copyWith(
        currentBalance: balance,
        totalDebit: totalDebit,
        totalCredit: totalCredit,
      );
    }).toList();
  }

  /// Generates the General Ledger statement for an account
  Future<List<LedgerRow>> getGeneralLedger({
    required int accountId,
    String? dateFrom,
    String? dateTo,
    int? projectId,
    int? analyticalItemId,
    int? contractorId,
  }) async {
    final db = await _db;

    // Fetch opening balance
    final opResult = await db.rawQuery('''
      SELECT SUM(debit) as op_debit, SUM(credit) as op_credit
      FROM opening_balances
      WHERE account_id = ?
    ''', [accountId]);

    double openingDebit = 0.0;
    double openingCredit = 0.0;
    if (opResult.isNotEmpty) {
      openingDebit = (opResult.first['op_debit'] as num?)?.toDouble() ?? 0.0;
      openingCredit = (opResult.first['op_credit'] as num?)?.toDouble() ?? 0.0;
    }

    final accResult = await db.query('accounts', where: 'id = ?', whereArgs: [accountId]);
    final normalBalance = accResult.isNotEmpty ? (accResult.first['normal_balance'] as String) : NormalBalance.debit;

    double runningBalance = (normalBalance == NormalBalance.debit)
        ? (openingDebit - openingCredit)
        : (openingCredit - openingDebit);

    List<LedgerRow> rows = [];

    // Add opening balance row if non-zero
    if (openingDebit > 0 || openingCredit > 0) {
      rows.add(LedgerRow(
        date: dateFrom ?? '2026-01-01',
        entryNumber: 'افتتاحي',
        description: 'الرصيد الافتتاحي لأول المدة',
        debit: openingDebit,
        credit: openingCredit,
        runningBalance: runningBalance,
      ));
    }

    // Build conditions for posted lines
    List<String> conditions = ["je.status = 'posted'", "jl.account_id = ?"];
    List<dynamic> args = [accountId];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add("je.date >= ?");
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add("je.date <= ?");
      args.add(dateTo);
    }
    if (projectId != null && projectId > 0) {
      conditions.add("jl.project_id = ?");
      args.add(projectId);
    }
    if (analyticalItemId != null && analyticalItemId > 0) {
      conditions.add("jl.analytical_item_id = ?");
      args.add(analyticalItemId);
    }
    if (contractorId != null && contractorId > 0) {
      conditions.add("jl.contractor_id = ?");
      args.add(contractorId);
    }

    final query = '''
      SELECT jl.*, je.date, je.entry_number, je.id as entry_id,
             p.name as project_name,
             an.name as analytical_name,
             u.name as unit_name,
             c.name as contractor_name,
             s.name as supplier_name,
             cust.name as customer_name
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      LEFT JOIN projects p ON jl.project_id = p.id
      LEFT JOIN analytical_items an ON jl.analytical_item_id = an.id
      LEFT JOIN units u ON jl.unit_id = u.id
      LEFT JOIN contractors c ON jl.contractor_id = c.id
      LEFT JOIN suppliers s ON jl.supplier_id = s.id
      LEFT JOIN customers cust ON jl.customer_id = cust.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY je.date ASC, je.id ASC, jl.line_number ASC
    ''';

    final lines = await db.rawQuery(query, args);

    for (var line in lines) {
      final debit = (line['debit'] as num?)?.toDouble() ?? 0.0;
      final credit = (line['credit'] as num?)?.toDouble() ?? 0.0;

      if (normalBalance == NormalBalance.debit) {
        runningBalance += (debit - credit);
      } else {
        runningBalance += (credit - debit);
      }

      rows.add(LedgerRow(
        journalEntryId: line['entry_id'] as int?,
        date: line['date'] as String? ?? '',
        entryNumber: line['entry_number'] as String? ?? '',
        description: line['description'] as String? ?? '',
        projectName: line['project_name'] as String?,
        analyticalName: line['analytical_name'] as String?,
        unitName: line['unit_name'] as String?,
        quantity: (line['quantity'] as num?)?.toDouble() ?? 0.0,
        unitPrice: (line['unit_price'] as num?)?.toDouble() ?? 0.0,
        debit: debit,
        credit: credit,
        runningBalance: runningBalance,
        contractorName: line['contractor_name'] as String?,
        supplierName: line['supplier_name'] as String?,
        customerName: line['customer_name'] as String?,
      ));
    }

    return rows;
  }

  // ==========================================
  // 2. TRIAL BALANCE
  // ==========================================

  /// Computes Trial Balance by Totals & by Balances
  Future<TrialBalanceReport> getTrialBalance({
    String? dateFrom,
    String? dateTo,
    int? projectId,
  }) async {
    final db = await _db;
    List<String> conditions = ["je.status = 'posted'"];
    List<dynamic> args = [];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add("je.date >= ?");
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add("je.date <= ?");
      args.add(dateTo);
    }
    if (projectId != null && projectId > 0) {
      conditions.add("jl.project_id = ?");
      args.add(projectId);
    }

    final where = "WHERE ${conditions.join(' AND ')}";

    final query = '''
      SELECT a.*,
             COALESCE(op.op_debit, 0.0) as op_debit,
             COALESCE(op.op_credit, 0.0) as op_credit,
             COALESCE(mov.mov_debit, 0.0) as mov_debit,
             COALESCE(mov.mov_credit, 0.0) as mov_credit
      FROM accounts a
      LEFT JOIN (
        SELECT account_id, SUM(debit) as op_debit, SUM(credit) as op_credit
        FROM opening_balances
        GROUP BY account_id
      ) op ON a.id = op.account_id
      LEFT JOIN (
        SELECT jl.account_id,
               SUM(jl.debit) as mov_debit,
               SUM(jl.credit) as mov_credit
        FROM journal_lines jl
        JOIN journal_entries je ON jl.journal_entry_id = je.id
        $where
        GROUP BY jl.account_id
      ) mov ON a.id = mov.account_id
      WHERE (COALESCE(op.op_debit, 0) > 0 OR COALESCE(op.op_credit, 0) > 0 OR
             COALESCE(mov.mov_debit, 0) > 0 OR COALESCE(mov.mov_credit, 0) > 0)
      ORDER BY a.code ASC
    ''';

    final result = await db.rawQuery(query, args);

    List<TrialBalanceItem> items = [];
    double totalOpDebit = 0.0;
    double totalOpCredit = 0.0;
    double totalMovDebit = 0.0;
    double totalMovCredit = 0.0;
    double totalCloseDebit = 0.0;
    double totalCloseCredit = 0.0;

    for (var row in result) {
      final account = Account.fromMap(row);
      final opDebit = (row['op_debit'] as num?)?.toDouble() ?? 0.0;
      final opCredit = (row['op_credit'] as num?)?.toDouble() ?? 0.0;
      final movDebit = (row['mov_debit'] as num?)?.toDouble() ?? 0.0;
      final movCredit = (row['mov_credit'] as num?)?.toDouble() ?? 0.0;

      final netMovement = (opDebit + movDebit) - (opCredit + movCredit);

      double closeDebit = 0.0;
      double closeCredit = 0.0;
      if (netMovement > 0) {
        closeDebit = netMovement;
      } else if (netMovement < 0) {
        closeCredit = netMovement.abs();
      }

      totalOpDebit += opDebit;
      totalOpCredit += opCredit;
      totalMovDebit += movDebit;
      totalMovCredit += movCredit;
      totalCloseDebit += closeDebit;
      totalCloseCredit += closeCredit;

      items.add(TrialBalanceItem(
        account: account,
        openingDebit: opDebit,
        openingCredit: opCredit,
        movementDebit: movDebit,
        movementCredit: movCredit,
        closingDebit: closeDebit,
        closingCredit: closeCredit,
      ));
    }

    final isBalanced = (totalCloseDebit - totalCloseCredit).abs() < 0.01;

    return TrialBalanceReport(
      items: items,
      totalOpeningDebit: totalOpDebit,
      totalOpeningCredit: totalOpCredit,
      totalMovementDebit: totalMovDebit,
      totalMovementCredit: totalMovCredit,
      totalClosingDebit: totalCloseDebit,
      totalClosingCredit: totalCloseCredit,
      isBalanced: isBalanced,
    );
  }

  // ==========================================
  // 3. CONTRACTOR ACCOUNTING
  // ==========================================

  /// Calculates Contractor Statement and running balance
  Future<List<ContractorLedgerRow>> getContractorStatement(int contractorId, {String? dateFrom, String? dateTo}) async {
    final db = await _db;

    // Fetch opening balance
    final cRes = await db.query('contractors', where: 'id = ?', whereArgs: [contractorId]);
    if (cRes.isEmpty) return [];

    final contractor = Contractor.fromMap(cRes.first);
    double runningBalance = contractor.openingBalance; // Creditor nature (مستحق للمقاول)

    List<ContractorLedgerRow> rows = [];
    if (contractor.openingBalance > 0) {
      rows.add(ContractorLedgerRow(
        date: dateFrom ?? '2026-01-01',
        entryNumber: 'افتتاحي',
        description: 'رصيد أول المدة المستحق للمقاول',
        debit: 0.0,
        credit: contractor.openingBalance,
        runningBalance: runningBalance,
      ));
    }

    List<String> conditions = ["je.status = 'posted'", "jl.contractor_id = ?"];
    List<dynamic> args = [contractorId];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add("je.date >= ?");
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add("je.date <= ?");
      args.add(dateTo);
    }

    final query = '''
      SELECT jl.*, je.date, je.entry_number, je.id as entry_id, p.name as project_name
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      LEFT JOIN projects p ON jl.project_id = p.id
      WHERE ${conditions.join(' AND ')}
      ORDER BY je.date ASC, je.id ASC
    ''';

    final lines = await db.rawQuery(query, args);

    for (var line in lines) {
      final debit = (line['debit'] as num?)?.toDouble() ?? 0.0;   // مدفوعات نقدية/بنكية للمقاول
      final credit = (line['credit'] as num?)?.toDouble() ?? 0.0; // مستخلصات ومستحقات المقاول

      // For contractor: Credit increases what we owe him, Debit decreases it
      runningBalance += (credit - debit);

      rows.add(ContractorLedgerRow(
        journalEntryId: line['entry_id'] as int?,
        date: line['date'] as String? ?? '',
        entryNumber: line['entry_number'] as String? ?? '',
        description: line['description'] as String? ?? '',
        projectName: line['project_name'] as String?,
        debit: debit,
        credit: credit,
        runningBalance: runningBalance,
      ));
    }

    return rows;
  }

  /// Calculates balances for all contractors
  Future<List<Contractor>> getAllContractorsWithBalances() async {
    final db = await _db;
    final contractors = await db.rawQuery('''
      SELECT c.*,
             COALESCE(SUM(jl.debit), 0.0) as total_debit,
             COALESCE(SUM(jl.credit), 0.0) as total_credit
      FROM contractors c
      LEFT JOIN journal_lines jl ON c.id = jl.contractor_id
      LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id AND je.status = 'posted'
      GROUP BY c.id
      ORDER BY c.code ASC
    ''');

    return contractors.map((row) {
      final c = Contractor.fromMap(row);
      final debit = (row['total_debit'] as num?)?.toDouble() ?? 0.0;
      final credit = (row['total_credit'] as num?)?.toDouble() ?? 0.0;
      final currentBalance = c.openingBalance + credit - debit;

      return c.copyWith(
        totalDebit: debit,
        totalCredit: credit,
        currentBalance: currentBalance,
      );
    }).toList();
  }

  // ==========================================
  // 4. PROJECT COST ACCOUNTING & DRILL-DOWN
  // ==========================================

  /// Computes detailed cost and profitability analysis for a project
  Future<ProjectCostReport> getProjectCostReport(int projectId) async {
    final db = await _db;

    final pRes = await db.query('projects', where: 'id = ?', whereArgs: [projectId]);
    if (pRes.isEmpty) {
      throw Exception('المشروع غير موجود.');
    }
    final project = Project.fromMap(pRes.first);

    // 1. Revenue
    final revRes = await db.rawQuery('''
      SELECT SUM(jl.credit - jl.debit) as total_revenue
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE je.status = 'posted' AND jl.project_id = ? AND a.account_type = 'revenue'
    ''', [projectId]);
    final revenue = (revRes.first['total_revenue'] as num?)?.toDouble() ?? 0.0;

    // 2. Costs breakdown by Analytical Item & Subcontractor
    final analyticalCostsRes = await db.rawQuery('''
      SELECT an.name as item_name, an.category, jl.contractor_id,
             SUM(jl.debit - jl.credit) as cost
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      LEFT JOIN analytical_items an ON jl.analytical_item_id = an.id
      WHERE je.status = 'posted' AND jl.project_id = ? AND a.account_type = 'expense'
      GROUP BY an.id, jl.contractor_id
    ''', [projectId]);

    Map<String, double> costByAnalytical = {};
    double directMaterials = 0.0;
    double labor = 0.0;
    double equipment = 0.0;
    double subcontractors = 0.0;
    double transportation = 0.0;
    double maintenance = 0.0;
    double siteExpenses = 0.0;
    double generalExpenses = 0.0;
    double otherCosts = 0.0;

    for (var row in analyticalCostsRes) {
      final name = (row['item_name'] as String?) ?? 'غير محدد';
      final category = (row['category'] as String?) ?? '';
      final contractorId = row['contractor_id'] as int?;
      final cost = (row['cost'] as num?)?.toDouble() ?? 0.0;

      costByAnalytical[name] = (costByAnalytical[name] ?? 0.0) + cost;

      final normCat = category.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('ة', 'ه');
      final normName = name.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('ة', 'ه');

      if (contractorId != null || normCat.contains('مقاول') || normName.contains('مسلح') || normName.contains('خزان')) {
        subcontractors += cost;
      } else if (normCat.contains('مواد') || normName.contains('خرسان') || normName.contains('حديد') || normName.contains('طوب')) {
        directMaterials += cost;
      } else if (normCat.contains('عماله') || normName.contains('مرتب') || normName.contains('اجور')) {
        labor += cost;
      } else if (normCat.contains('معدات') || normName.contains('حفر') || normName.contains('احلال')) {
        equipment += cost;
      } else if (normName.contains('نقل')) {
        transportation += cost;
      } else if (normName.contains('صيان')) {
        maintenance += cost;
      } else if (normCat.contains('موقع') || normName.contains('كرفان')) {
        siteExpenses += cost;
      } else if (normCat.contains('عمومي') || normName.contains('نثريات')) {
        generalExpenses += cost;
      } else {
        otherCosts += cost;
      }
    }

    // 3. Cost breakdown by Account
    final accountCostsRes = await db.rawQuery('''
      SELECT a.name_ar as account_name,
             SUM(jl.debit - jl.credit) as cost
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      WHERE je.status = 'posted' AND jl.project_id = ? AND a.account_type = 'expense'
      GROUP BY a.id
    ''', [projectId]);

    Map<String, double> costByAccount = {};
    double totalCost = 0.0;
    for (var row in accountCostsRes) {
      final accName = (row['account_name'] as String?) ?? '';
      final cost = (row['cost'] as num?)?.toDouble() ?? 0.0;
      costByAccount[accName] = cost;
      totalCost += cost;
    }

    final grossProfit = revenue - totalCost;
    final profitMargin = (revenue > 0) ? ((grossProfit / revenue) * 100) : 0.0;

    return ProjectCostReport(
      projectId: projectId,
      projectCode: project.code,
      projectName: project.name,
      client: project.client,
      budget: project.budget,
      revenue: revenue,
      directMaterials: directMaterials,
      labor: labor,
      equipment: equipment,
      subcontractors: subcontractors,
      transportation: transportation,
      maintenance: maintenance,
      siteExpenses: siteExpenses,
      generalExpenses: generalExpenses,
      otherCosts: otherCosts,
      totalCost: totalCost,
      grossProfit: grossProfit,
      profitMargin: profitMargin,
      costByAnalyticalItem: costByAnalytical,
      costByAccount: costByAccount,
    );
  }

  /// Calculates summary financial metrics for all projects
  Future<List<Project>> getAllProjectsWithMetrics() async {
    final db = await _db;
    final projects = await db.query('projects', orderBy: 'code ASC');

    List<Project> list = [];
    for (var pMap in projects) {
      final p = Project.fromMap(pMap);
      final report = await getProjectCostReport(p.id!);

      // Also get contractor balances associated with this project
      final cRes = await db.rawQuery('''
        SELECT COALESCE(SUM(c.opening_balance), 0.0) as op,
               COALESCE(SUM(jl.credit - jl.debit), 0.0) as mov
        FROM contractors c
        LEFT JOIN journal_lines jl ON c.id = jl.contractor_id
        LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id AND je.status = 'posted'
        WHERE c.project_id = ?
      ''', [p.id]);

      double contractorBalance = 0.0;
      if (cRes.isNotEmpty) {
        final op = (cRes.first['op'] as num?)?.toDouble() ?? 0.0;
        final mov = (cRes.first['mov'] as num?)?.toDouble() ?? 0.0;
        contractorBalance = op + mov;
      }

      list.add(p.copyWith(
        totalRevenue: report.revenue,
        directCost: report.directMaterials + report.labor + report.subcontractors + report.equipment,
        indirectCost: report.siteExpenses + report.generalExpenses + report.transportation,
        totalCost: report.totalCost,
        grossProfit: report.grossProfit,
        profitMargin: report.profitMargin,
        contractorBalances: contractorBalance,
      ));
    }
    return list;
  }

  // ==========================================
  // 5. INCOME STATEMENT (قائمة الدخل)
  // ==========================================

  Future<IncomeStatementReport> getIncomeStatement({String? dateFrom, String? dateTo}) async {
    final db = await _db;
    List<String> conditions = ["je.status = 'posted'"];
    List<dynamic> args = [];

    if (dateFrom != null && dateFrom.isNotEmpty) {
      conditions.add("je.date >= ?");
      args.add(dateFrom);
    }
    if (dateTo != null && dateTo.isNotEmpty) {
      conditions.add("je.date <= ?");
      args.add(dateTo);
    }

    final where = "WHERE ${conditions.join(' AND ')}";

    // Revenue accounts
    final revRes = await db.rawQuery('''
      SELECT a.name_ar, a.code,
             SUM(jl.credit - jl.debit) as amount
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      $where AND a.account_type = 'revenue'
      GROUP BY a.id
    ''', args);

    double grossSales = 0.0;
    double salesReturns = 0.0;
    Map<String, double> revenueDetails = {};
    for (var r in revRes) {
      final name = r['name_ar'] as String;
      final amt = (r['amount'] as num?)?.toDouble() ?? 0.0;
      revenueDetails[name] = amt;
      if (name.contains('مردود')) {
        salesReturns += amt.abs();
      } else {
        grossSales += amt;
      }
    }
    final netSales = grossSales - salesReturns;

    // Expenses & Cost of Sales
    final expRes = await db.rawQuery('''
      SELECT a.name_ar, a.code, a.sub_type,
             SUM(jl.debit - jl.credit) as amount
      FROM journal_lines jl
      JOIN journal_entries je ON jl.journal_entry_id = je.id
      JOIN accounts a ON jl.account_id = a.id
      $where AND a.account_type = 'expense'
      GROUP BY a.id
    ''', args);

    double purchases = 0.0;
    double purchaseReturns = 0.0;
    double directProjectCosts = 0.0;
    double generalAdminExpenses = 0.0;
    double siteExpenses = 0.0;
    double operatingExpenses = 0.0;
    double depreciation = 0.0;
    double taxExpense = 0.0;

    Map<String, double> costDetails = {};
    Map<String, double> expenseDetails = {};

    for (var e in expRes) {
      final name = e['name_ar'] as String;
      final subType = e['sub_type'] as String;
      final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;

      if (subType == AccountSubType.directCost) {
        costDetails[name] = amt;
        if (name.contains('مشتريات')) {
          purchases += amt;
        } else if (name.contains('مردود')) {
          purchaseReturns += amt.abs();
        } else {
          directProjectCosts += amt;
        }
      } else {
        expenseDetails[name] = amt;
        if (subType == AccountSubType.siteExpense) {
          siteExpenses += amt;
        } else if (subType == AccountSubType.administrativeExpense) {
          generalAdminExpenses += amt;
        } else if (subType == AccountSubType.depreciation) {
          depreciation += amt;
        } else if (subType == AccountSubType.taxExpense) {
          taxExpense += amt;
        } else {
          operatingExpenses += amt;
        }
      }
    }

    final costOfSales = (purchases - purchaseReturns) + directProjectCosts;
    final grossProfit = netSales - costOfSales;
    final totalOperatingExpenses = generalAdminExpenses + operatingExpenses + siteExpenses;
    final operatingProfit = grossProfit - totalOperatingExpenses;
    final profitBeforeTax = operatingProfit - depreciation;
    final netProfit = profitBeforeTax - taxExpense;

    return IncomeStatementReport(
      grossSales: grossSales,
      salesReturns: salesReturns,
      netSales: netSales,
      openingInventory: 0.0,
      purchases: purchases,
      purchaseReturns: purchaseReturns,
      directProjectCosts: directProjectCosts,
      costOfSales: costOfSales,
      grossProfit: grossProfit,
      generalAdminExpenses: generalAdminExpenses,
      operatingExpenses: operatingExpenses,
      siteExpenses: siteExpenses,
      totalOperatingExpenses: totalOperatingExpenses,
      operatingProfit: operatingProfit,
      otherIncome: 0.0,
      depreciationExpense: depreciation,
      profitBeforeTax: profitBeforeTax,
      taxExpense: taxExpense,
      netProfit: netProfit,
      revenueDetails: revenueDetails,
      costDetails: costDetails,
      expenseDetails: expenseDetails,
    );
  }

  // ==========================================
  // 6. BALANCE SHEET (الميزانية العمومية)
  // ==========================================

  Future<BalanceSheetReport> getBalanceSheet({String? asOfDate}) async {
    // 1. Get net profit from income statement up to asOfDate
    final incomeStatement = await getIncomeStatement(dateTo: asOfDate);
    final currentYearProfit = incomeStatement.netProfit;

    // 2. Get accounts with real-time balances
    final accounts = await getAccountsWithBalances(dateTo: asOfDate);

    List<BalanceSheetSectionItem> currentAssets = [];
    List<BalanceSheetSectionItem> fixedAssets = [];
    List<BalanceSheetSectionItem> currentLiabilities = [];
    List<BalanceSheetSectionItem> longTermLiabilities = [];

    double totalCurrentAssets = 0.0;
    double totalFixedAssets = 0.0;
    double accumulatedDepreciation = 0.0;
    double totalCurrentLiabilities = 0.0;
    double contractorBalances = 0.0;
    double taxLiabilities = 0.0;
    double totalLongTermLiabilities = 0.0;

    double capital = 0.0;
    double partnerAccounts = 0.0;
    double retainedEarnings = 0.0;

    for (var acc in accounts) {
      final balance = acc.currentBalance;

      if (acc.accountType == AccountType.asset) {
        if (acc.subType == AccountSubType.currentAsset) {
          currentAssets.add(BalanceSheetSectionItem(code: acc.code, name: acc.nameAr, amount: balance));
          totalCurrentAssets += balance;
        } else if (acc.subType == AccountSubType.fixedAsset || acc.subType == AccountSubType.otherAsset) {
          fixedAssets.add(BalanceSheetSectionItem(code: acc.code, name: acc.nameAr, amount: balance));
          totalFixedAssets += balance;
        }
      } else if (acc.accountType == AccountType.liability) {
        if (acc.subType == AccountSubType.currentLiability) {
          currentLiabilities.add(BalanceSheetSectionItem(code: acc.code, name: acc.nameAr, amount: balance));
          totalCurrentLiabilities += balance;
          if (acc.code == '2102' || acc.nameAr.contains('مقاول')) {
            contractorBalances += balance;
          }
          if (acc.code.contains('2103') || acc.code.contains('2104') || acc.nameAr.contains('ضريب')) {
            taxLiabilities += balance;
          }
        } else {
          longTermLiabilities.add(BalanceSheetSectionItem(code: acc.code, name: acc.nameAr, amount: balance));
          totalLongTermLiabilities += balance;
        }
      } else if (acc.accountType == AccountType.equity) {
        if (acc.subType == AccountSubType.capital) {
          capital += balance;
        } else if (acc.subType == AccountSubType.partnerAccount) {
          partnerAccounts += balance;
        } else if (acc.subType == AccountSubType.retainedEarnings) {
          retainedEarnings += balance;
        }
      }
    }

    final netFixedAssets = totalFixedAssets - accumulatedDepreciation;
    final totalAssets = totalCurrentAssets + netFixedAssets;
    final totalLiabilities = totalCurrentLiabilities + totalLongTermLiabilities;
    final totalEquity = capital + partnerAccounts + retainedEarnings + currentYearProfit;
    final totalLiabilitiesAndEquity = totalLiabilities + totalEquity;

    final diff = (totalAssets - totalLiabilitiesAndEquity).abs();
    final isBalanced = diff < 0.01;

    return BalanceSheetReport(
      currentAssets: currentAssets,
      totalCurrentAssets: totalCurrentAssets,
      fixedAssets: fixedAssets,
      totalFixedAssets: totalFixedAssets,
      accumulatedDepreciation: accumulatedDepreciation,
      netFixedAssets: netFixedAssets,
      totalAssets: totalAssets,
      currentLiabilities: currentLiabilities,
      contractorBalances: contractorBalances,
      taxLiabilities: taxLiabilities,
      totalCurrentLiabilities: totalCurrentLiabilities,
      longTermLiabilities: longTermLiabilities,
      totalLongTermLiabilities: totalLongTermLiabilities,
      totalLiabilities: totalLiabilities,
      capital: capital,
      partnersCurrentAccounts: partnerAccounts,
      retainedEarnings: retainedEarnings,
      currentYearProfit: currentYearProfit,
      totalEquity: totalEquity,
      totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
      isBalanced: isBalanced,
      difference: diff,
    );
  }

  // ==========================================
  // 7. CASH & BANK MANAGEMENT
  // ==========================================

  Future<List<CashBankPositionItem>> getCashBankPosition() async {
    final db = await _db;
    final accounts = await db.rawQuery('''
      SELECT a.*,
             COALESCE(op.op_debit - op.op_credit, 0.0) as op_balance,
             COALESCE(mov.mov_debit, 0.0) as mov_debit,
             COALESCE(mov.mov_credit, 0.0) as mov_credit
      FROM accounts a
      LEFT JOIN (
        SELECT account_id, SUM(debit) as op_debit, SUM(credit) as op_credit
        FROM opening_balances
        GROUP BY account_id
      ) op ON a.id = op.account_id
      LEFT JOIN (
        SELECT jl.account_id,
               SUM(jl.debit) as mov_debit,
               SUM(jl.credit) as mov_credit
        FROM journal_lines jl
        JOIN journal_entries je ON jl.journal_entry_id = je.id
        WHERE je.status = 'posted'
        GROUP BY jl.account_id
      ) mov ON a.id = mov.account_id
      WHERE a.code IN ('1101', '1102') OR a.name_ar LIKE '%صندوق%' OR a.name_ar LIKE '%بنك%'
      ORDER BY a.code ASC
    ''');

    return accounts.map((row) {
      final op = (row['op_balance'] as num?)?.toDouble() ?? 0.0;
      final movDebit = (row['mov_debit'] as num?)?.toDouble() ?? 0.0;
      final movCredit = (row['mov_credit'] as num?)?.toDouble() ?? 0.0;
      final current = op + movDebit - movCredit;
      final code = row['code'] as String;
      final type = code == '1101' || (row['name_ar'] as String).contains('صندوق') ? 'cash' : 'bank';

      return CashBankPositionItem(
        accountId: row['id'] as int,
        code: code,
        name: row['name_ar'] as String,
        type: type,
        openingBalance: op,
        debitMovement: movDebit,
        creditMovement: movCredit,
        currentBalance: current,
      );
    }).toList();
  }

  // ==========================================
  // 8. DASHBOARD KPI & ALERTS
  // ==========================================

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    final income = await getIncomeStatement();
    final balanceSheet = await getBalanceSheet();
    final cashBank = await getCashBankPosition();

    double totalCash = 0.0;
    double totalBank = 0.0;
    for (var cb in cashBank) {
      if (cb.type == 'cash') totalCash += cb.currentBalance;
      if (cb.type == 'bank') totalBank += cb.currentBalance;
    }

    // Receivables (Customers 1103) & Payables (Suppliers 2101)
    double receivables = 0.0;
    double payables = 0.0;
    for (var ca in balanceSheet.currentAssets) {
      if (ca.code == '1103' || ca.name.contains('عملاء')) receivables += ca.amount;
    }
    for (var cl in balanceSheet.currentLiabilities) {
      if (cl.code == '2101' || cl.name.contains('مورد')) payables += cl.amount;
    }

    // Accounting Alerts
    final db = await _db;
    final draftCountRes = await db.rawQuery("SELECT COUNT(*) as count FROM journal_entries WHERE status = 'draft'");
    final draftCount = Sqflite.firstIntValue(draftCountRes) ?? 0;

    final closedPeriodCheckRes = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM journal_entries je
      JOIN accounting_periods p ON je.date >= p.start_date AND je.date <= p.end_date
      WHERE je.status = 'posted' AND p.is_closed = 1
    ''');
    final closedPeriodViolations = Sqflite.firstIntValue(closedPeriodCheckRes) ?? 0;

    return {
      'totalRevenue': income.netSales,
      'totalExpenses': income.costOfSales + income.totalOperatingExpenses,
      'grossProfit': income.grossProfit,
      'netProfit': income.netProfit,
      'cashBalance': totalCash,
      'bankBalance': totalBank,
      'totalLiquidity': totalCash + totalBank,
      'receivables': receivables,
      'payables': payables,
      'contractorBalance': balanceSheet.contractorBalances,
      'isBalanceSheetBalanced': balanceSheet.isBalanced,
      'draftEntriesCount': draftCount,
      'closedPeriodViolations': closedPeriodViolations,
    };
  }
}
