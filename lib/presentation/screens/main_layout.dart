import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_top_bar.dart';
import 'dashboard/dashboard_screen.dart';
import 'journal/journal_list_screen.dart';
import 'journal/journal_entry_screen.dart';
import 'journal/quick_entry_dialog.dart';
import 'accounts/chart_of_accounts_screen.dart';
import 'projects/project_list_screen.dart';
import 'projects/project_detail_screen.dart';
import 'contractors/contractor_list_screen.dart';
import 'contractors/contractor_statement_screen.dart';
import 'parties/suppliers_screen.dart';
import 'parties/customers_screen.dart';
import 'general_ledger/general_ledger_screen.dart';
import 'trial_balance/trial_balance_screen.dart';
import 'financial_statements/income_statement_screen.dart';
import 'financial_statements/balance_sheet_screen.dart';
import 'cash_bank/cash_bank_screen.dart';
import 'analytics/analytical_items_screen.dart';
import 'opening_balances/opening_balances_screen.dart';
import 'settings/fiscal_years_screen.dart';
import 'settings/users_permissions_screen.dart';
import 'settings/audit_log_screen.dart';
import 'settings/backup_restore_screen.dart';
import 'settings/import_export_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  String _activeRoute = 'dashboard';
  int? _routeParamId;

  void _navigateTo(String route, {int? id}) {
    setState(() {
      _activeRoute = route;
      _routeParamId = id;
    });
  }

  void _openQuickEntry() {
    showDialog(
      context: context,
      builder: (ctx) => QuickEntryDialog(
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل المعاملة السريعة وترحيلها بنجاح.')),
          );
        },
      ),
    );
  }

  String _getPageTitle() {
    switch (_activeRoute) {
      case 'dashboard': return AppStrings.dashboard;
      case 'journal': return AppStrings.journalEntries;
      case 'journal_entry': return _routeParamId == null ? 'قيد يومية جديد' : 'تعديل قيد اليومية';
      case 'accounts': return AppStrings.chartOfAccounts;
      case 'projects': return AppStrings.projects;
      case 'project_detail': return 'بيان وتحليل تكاليف المشروع';
      case 'contractors': return AppStrings.contractors;
      case 'contractor_statement': return 'كشف حساب المقاول';
      case 'suppliers': return AppStrings.suppliers;
      case 'customers': return AppStrings.customers;
      case 'general_ledger': return AppStrings.generalLedger;
      case 'trial_balance': return AppStrings.trialBalance;
      case 'income_statement': return AppStrings.incomeStatement;
      case 'balance_sheet': return AppStrings.balanceSheet;
      case 'cash_bank': return AppStrings.cashBank;
      case 'analytics': return AppStrings.analyticalItems;
      case 'opening_balances': return AppStrings.openingBalances;
      case 'fiscal': return AppStrings.fiscalYears;
      case 'users': return AppStrings.usersAndPermissions;
      case 'audit': return AppStrings.auditLog;
      case 'import_export': return AppStrings.importExport;
      case 'backup': return AppStrings.backupRestore;
      default: return AppStrings.appName;
    }
  }

  Widget _buildActiveScreen() {
    switch (_activeRoute) {
      case 'dashboard':
        return DashboardScreen(onNavigate: (r) => _navigateTo(r));
      case 'journal':
        return JournalListScreen(onNavigate: (r, {entryId}) => _navigateTo(r, id: entryId));
      case 'journal_entry':
        return JournalEntryScreen(
          entryId: _routeParamId,
          onBack: () => _navigateTo('journal'),
        );
      case 'accounts':
        return ChartOfAccountsScreen(
          onNavigate: (r, {accountId}) => _navigateTo(r, id: accountId),
        );
      case 'projects':
        return ProjectListScreen(
          onNavigate: (r, {projectId}) => _navigateTo(r, id: projectId),
        );
      case 'project_detail':
        return ProjectDetailScreen(
          projectId: _routeParamId ?? 1,
          onBack: () => _navigateTo('projects'),
        );
      case 'contractors':
        return ContractorListScreen(
          onNavigate: (r, {contractorId}) => _navigateTo(r, id: contractorId),
        );
      case 'contractor_statement':
        return ContractorStatementScreen(
          contractorId: _routeParamId ?? 1,
          onBack: () => _navigateTo('contractors'),
          onNavigateToEntry: (r, {entryId}) => _navigateTo(r, id: entryId),
        );
      case 'suppliers':
        return const SuppliersScreen();
      case 'customers':
        return const CustomersScreen();
      case 'general_ledger':
        return GeneralLedgerScreen(
          initialAccountId: _routeParamId,
          onNavigateToEntry: (r, {entryId}) => _navigateTo(r, id: entryId),
        );
      case 'trial_balance':
        return TrialBalanceScreen(
          onNavigateToAccount: (r, {accountId}) => _navigateTo(r, id: accountId),
        );
      case 'income_statement':
        return const IncomeStatementScreen();
      case 'balance_sheet':
        return const BalanceSheetScreen();
      case 'cash_bank':
        return CashBankScreen(
          onNavigateToAccount: (r, {accountId}) => _navigateTo(r, id: accountId),
        );
      case 'analytics':
        return const AnalyticalItemsScreen();
      case 'opening_balances':
        return const OpeningBalancesScreen();
      case 'fiscal':
        return const FiscalYearsScreen();
      case 'users':
        return const UsersPermissionsScreen();
      case 'audit':
        return const AuditLogScreen();
      case 'import_export':
        return const ImportExportScreen();
      case 'backup':
        return const BackupRestoreScreen();
      default:
        return DashboardScreen(onNavigate: (r) => _navigateTo(r));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Row(
          children: [
            // Modern Desktop Sidebar
            AppSidebar(
              activeRoute: _activeRoute,
              onNavigate: (r) => _navigateTo(r),
            ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  AppTopBar(
                    title: _getPageTitle(),
                    onNewJournal: () => _navigateTo('journal_entry'),
                    onQuickEntry: _openQuickEntry,
                  ),
                  Expanded(
                    child: _buildActiveScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
