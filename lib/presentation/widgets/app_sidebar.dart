import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AppSidebar extends StatelessWidget {
  final String activeRoute;
  final Function(String route) onNavigate;

  const AppSidebar({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBgLight,
      ),
      child: Column(
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سيجما',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'نظام مالي متكامل',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Navigation Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _menuSectionHeader('المالية والمحاسبة'),
                _navItem('dashboard', AppStrings.dashboard, Icons.dashboard_rounded),
                _navItem('journal', AppStrings.journalEntries, Icons.receipt_long_rounded),
                _navItem('accounts', AppStrings.chartOfAccounts, Icons.account_tree_rounded),
                _navItem('general_ledger', AppStrings.generalLedger, Icons.menu_book_rounded),
                _navItem('trial_balance', AppStrings.trialBalance, Icons.balance_rounded),
                _navItem('cash_bank', AppStrings.cashBank, Icons.account_balance_rounded),
                _navItem('opening_balances', AppStrings.openingBalances, Icons.lock_open_rounded),

                _menuSectionHeader('المشروعات والعمليات'),
                _navItem('projects', AppStrings.projects, Icons.construction_rounded),
                _navItem('contractors', AppStrings.contractors, Icons.engineering_rounded),
                _navItem('suppliers', AppStrings.suppliers, Icons.local_shipping_rounded),
                _navItem('customers', AppStrings.customers, Icons.business_rounded),
                _navItem('analytics', AppStrings.analyticalItems, Icons.category_rounded),

                _menuSectionHeader('القوائم المالية'),
                _navItem('income_statement', AppStrings.incomeStatement, Icons.trending_up_rounded),
                _navItem('balance_sheet', AppStrings.balanceSheet, Icons.account_balance_wallet_rounded),

                _menuSectionHeader('إدارة النظام'),
                _navItem('fiscal', AppStrings.fiscalYears, Icons.date_range_rounded),
                _navItem('users', AppStrings.usersAndPermissions, Icons.manage_accounts_rounded),
                _navItem('audit', AppStrings.auditLog, Icons.history_rounded),
                _navItem('import_export', AppStrings.importExport, Icons.import_export_rounded),
                _navItem('backup', AppStrings.backupRestore, Icons.backup_rounded),
              ],
            ),
          ),

          // User Profile Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFF090D16),
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    user != null && user.fullName.isNotEmpty ? user.fullName.substring(0, 1) : 'U',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'المستخدم',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roleName ?? 'مستخدم',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 18),
                  tooltip: AppStrings.logout,
                  onPressed: () => auth.logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 18, left: 18, top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _navItem(String route, String label, IconData icon) {
    final isSelected = activeRoute == route;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.sidebarActiveBgLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.sidebarActiveLight : AppColors.sidebarTextLight,
          size: 19,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.sidebarTextLight,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () => onNavigate(route),
      ),
    );
  }
}
