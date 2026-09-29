import 'package:flutter/foundation.dart';
import '../../domain/models/report_models.dart';
import '../../domain/services/accounting_engine.dart';

class ReportProvider extends ChangeNotifier {
  final AccountingEngine _engine;

  ReportProvider({AccountingEngine? engine}) : _engine = engine ?? AccountingEngine();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Trial Balance
  TrialBalanceReport? _trialBalance;
  TrialBalanceReport? get trialBalance => _trialBalance;

  // General Ledger
  List<LedgerRow> _ledgerRows = [];
  List<LedgerRow> get ledgerRows => _ledgerRows;

  // Project Cost
  ProjectCostReport? _projectCostReport;
  ProjectCostReport? get projectCostReport => _projectCostReport;

  // Contractor Statement
  List<ContractorLedgerRow> _contractorRows = [];
  List<ContractorLedgerRow> get contractorRows => _contractorRows;

  // Financial Statements
  IncomeStatementReport? _incomeStatement;
  IncomeStatementReport? get incomeStatement => _incomeStatement;

  BalanceSheetReport? _balanceSheet;
  BalanceSheetReport? get balanceSheet => _balanceSheet;

  // Cash & Bank
  List<CashBankPositionItem> _cashBankItems = [];
  List<CashBankPositionItem> get cashBankItems => _cashBankItems;

  Future<void> loadTrialBalance({String? from, String? to, int? projectId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _trialBalance = await _engine.getTrialBalance(dateFrom: from, dateTo: to, projectId: projectId);
    } catch (e) {
      debugPrint('Error loading trial balance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadGeneralLedger({
    required int accountId,
    String? from,
    String? to,
    int? projectId,
    int? analyticalItemId,
    int? contractorId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _ledgerRows = await _engine.getGeneralLedger(
        accountId: accountId,
        dateFrom: from,
        dateTo: to,
        projectId: projectId,
        analyticalItemId: analyticalItemId,
        contractorId: contractorId,
      );
    } catch (e) {
      debugPrint('Error loading general ledger: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProjectCost(int projectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _projectCostReport = await _engine.getProjectCostReport(projectId);
    } catch (e) {
      debugPrint('Error loading project cost: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadContractorStatement(int contractorId, {String? from, String? to}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _contractorRows = await _engine.getContractorStatement(contractorId, dateFrom: from, dateTo: to);
    } catch (e) {
      debugPrint('Error loading contractor statement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadIncomeStatement({String? from, String? to}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _incomeStatement = await _engine.getIncomeStatement(dateFrom: from, dateTo: to);
    } catch (e) {
      debugPrint('Error loading income statement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBalanceSheet({String? asOfDate}) async {
    _isLoading = true;
    notifyListeners();
    try {
      _balanceSheet = await _engine.getBalanceSheet(asOfDate: asOfDate);
    } catch (e) {
      debugPrint('Error loading balance sheet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCashBankPosition() async {
    _isLoading = true;
    notifyListeners();
    try {
      _cashBankItems = await _engine.getCashBankPosition();
    } catch (e) {
      debugPrint('Error loading cash/bank position: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
