import 'package:flutter/foundation.dart';
import '../../domain/models/account.dart';
import '../../domain/models/project.dart';
import '../../domain/models/party.dart';
import '../../domain/models/analytical_item.dart';
import '../../domain/models/unit.dart';
import '../../domain/models/fiscal_year.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../data/repositories/contractor_repository.dart';
import '../../data/repositories/party_repository.dart';
import '../../data/repositories/analytical_repository.dart';
import '../../data/repositories/fiscal_repository.dart';
import '../../domain/services/accounting_engine.dart';

class AccountingProvider extends ChangeNotifier {
  final AccountRepository _accountRepo;
  final ProjectRepository _projectRepo;
  final ContractorRepository _contractorRepo;
  final PartyRepository _partyRepo;
  final AnalyticalRepository _analyticalRepo;
  final FiscalRepository _fiscalRepo;
  final AccountingEngine _engine;

  AccountingProvider({
    AccountRepository? accountRepo,
    ProjectRepository? projectRepo,
    ContractorRepository? contractorRepo,
    PartyRepository? partyRepo,
    AnalyticalRepository? analyticalRepo,
    FiscalRepository? fiscalRepo,
    AccountingEngine? engine,
  })  : _accountRepo = accountRepo ?? AccountRepository(),
        _projectRepo = projectRepo ?? ProjectRepository(),
        _contractorRepo = contractorRepo ?? ContractorRepository(),
        _partyRepo = partyRepo ?? PartyRepository(),
        _analyticalRepo = analyticalRepo ?? AnalyticalRepository(),
        _fiscalRepo = fiscalRepo ?? FiscalRepository(),
        _engine = engine ?? AccountingEngine();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Account> _accounts = [];
  List<Account> get accounts => _accounts;

  List<Project> _projects = [];
  List<Project> get projects => _projects;

  List<Contractor> _contractors = [];
  List<Contractor> get contractors => _contractors;

  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  List<AnalyticalItem> _analyticalItems = [];
  List<AnalyticalItem> get analyticalItems => _analyticalItems;

  List<Unit> _units = [];
  List<Unit> get units => _units;

  FiscalYear? _activeFiscalYear;
  FiscalYear? get activeFiscalYear => _activeFiscalYear;

  List<AccountingPeriod> _periods = [];
  List<AccountingPeriod> get periods => _periods;

  Map<String, dynamic> _dashboardMetrics = {};
  Map<String, dynamic> get dashboardMetrics => _dashboardMetrics;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([
        loadAccounts(),
        loadProjects(),
        loadContractors(),
        loadSuppliers(),
        loadCustomers(),
        loadAnalyticalItems(),
        loadUnits(),
        loadFiscalData(),
        loadDashboardMetrics(),
      ]);
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAccounts() async {
    _accounts = await _engine.getAccountsWithBalances();
    notifyListeners();
  }

  Future<void> loadProjects() async {
    _projects = await _engine.getAllProjectsWithMetrics();
    notifyListeners();
  }

  Future<void> loadContractors() async {
    _contractors = await _engine.getAllContractorsWithBalances();
    notifyListeners();
  }

  Future<void> loadSuppliers() async {
    _suppliers = await _partyRepo.getAllSuppliers();
    notifyListeners();
  }

  Future<void> loadCustomers() async {
    _customers = await _partyRepo.getAllCustomers();
    notifyListeners();
  }

  Future<void> loadAnalyticalItems() async {
    _analyticalItems = await _analyticalRepo.getAllAnalyticalItems();
    notifyListeners();
  }

  Future<void> loadUnits() async {
    _units = await _analyticalRepo.getAllUnits();
    notifyListeners();
  }

  Future<void> loadFiscalData() async {
    _activeFiscalYear = await _fiscalRepo.getActiveFiscalYear();
    if (_activeFiscalYear != null) {
      _periods = await _fiscalRepo.getPeriodsForFiscalYear(_activeFiscalYear!.id!);
    }
    notifyListeners();
  }

  Future<void> loadDashboardMetrics() async {
    _dashboardMetrics = await _engine.getDashboardMetrics();
    notifyListeners();
  }

  // Account operations
  Future<void> saveAccount(Account account) async {
    if (account.id == null) {
      await _accountRepo.createAccount(account);
    } else {
      await _accountRepo.updateAccount(account);
    }
    await loadAccounts();
  }

  Future<void> deactivateAccount(int accountId) async {
    await _accountRepo.deactivateAccount(accountId);
    await loadAccounts();
  }

  Future<void> activateAccount(int accountId) async {
    await _accountRepo.activateAccount(accountId);
    await loadAccounts();
  }

  Future<void> deleteAccount(int accountId) async {
    await _accountRepo.deleteAccount(accountId);
    await loadAccounts();
  }

  // Project operations
  Future<void> saveProject(Project project) async {
    if (project.id == null) {
      await _projectRepo.createProject(project);
    } else {
      await _projectRepo.updateProject(project);
    }
    await loadProjects();
  }

  // Contractor operations
  Future<void> saveContractor(Contractor contractor) async {
    if (contractor.id == null) {
      await _contractorRepo.createContractor(contractor);
    } else {
      await _contractorRepo.updateContractor(contractor);
    }
    await loadContractors();
  }

  // Supplier & Customer operations
  Future<void> saveSupplier(Supplier s) async {
    if (s.id == null) {
      await _partyRepo.createSupplier(s);
    } else {
      await _partyRepo.updateSupplier(s);
    }
    await loadSuppliers();
  }

  Future<void> saveCustomer(Customer c) async {
    if (c.id == null) {
      await _partyRepo.createCustomer(c);
    } else {
      await _partyRepo.updateCustomer(c);
    }
    await loadCustomers();
  }

  // Analytical & Unit operations
  Future<void> saveAnalyticalItem(AnalyticalItem item) async {
    if (item.id == null) {
      await _analyticalRepo.createAnalyticalItem(item);
    } else {
      await _analyticalRepo.updateAnalyticalItem(item);
    }
    await loadAnalyticalItems();
  }

  Future<void> saveUnit(Unit unit) async {
    if (unit.id == null) {
      await _analyticalRepo.createUnit(unit);
    } else {
      await _analyticalRepo.updateUnit(unit);
    }
    await loadUnits();
  }

  // Fiscal period toggle
  Future<void> togglePeriodClosed(int periodId, bool close, {String? username}) async {
    await _fiscalRepo.togglePeriodClosed(periodId, close, username: username);
    await loadFiscalData();
  }
}
