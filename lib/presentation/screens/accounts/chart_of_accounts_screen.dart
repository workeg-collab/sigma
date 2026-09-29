import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/account.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  final Function(String route, {int? accountId}) onNavigate;

  const ChartOfAccountsScreen({super.key, required this.onNavigate});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAccountDialog([Account? account]) {
    final codeController = TextEditingController(text: account?.code ?? '');
    final nameArController = TextEditingController(text: account?.nameAr ?? '');
    final nameEnController = TextEditingController(text: account?.name ?? '');
    String accountType = account?.accountType ?? AccountType.asset;
    String subType = account?.subType ?? AccountSubType.currentAsset;
    String normalBalance = account?.normalBalance ?? NormalBalance.debit;
    bool requiresProject = account?.requiresProject ?? false;
    bool requiresAnalytical = account?.requiresAnalytical ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(account == null ? 'إضافة حساب جديد' : 'تعديل الحساب: ${account.nameAr}'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeController,
                      enabled: account == null,
                      decoration: const InputDecoration(labelText: 'كود الحساب *', isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameArController,
                      decoration: const InputDecoration(labelText: 'اسم الحساب بالعربية *', isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameEnController,
                      decoration: const InputDecoration(labelText: 'اسم الحساب بالإنجليزية', isDense: true),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: accountType,
                      decoration: const InputDecoration(labelText: 'نوع الحساب الرئيسي', isDense: true),
                      items: [
                        DropdownMenuItem(value: AccountType.asset, child: Text(AccountType.getLabelAr(AccountType.asset))),
                        DropdownMenuItem(value: AccountType.liability, child: Text(AccountType.getLabelAr(AccountType.liability))),
                        DropdownMenuItem(value: AccountType.equity, child: Text(AccountType.getLabelAr(AccountType.equity))),
                        DropdownMenuItem(value: AccountType.revenue, child: Text(AccountType.getLabelAr(AccountType.revenue))),
                        DropdownMenuItem(value: AccountType.expense, child: Text(AccountType.getLabelAr(AccountType.expense))),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            accountType = val;
                            normalBalance = (val == AccountType.asset || val == AccountType.expense)
                                ? NormalBalance.debit
                                : NormalBalance.credit;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: normalBalance,
                      decoration: const InputDecoration(labelText: 'طبيعة الحساب', isDense: true),
                      items: [
                        DropdownMenuItem(value: NormalBalance.debit, child: Text(NormalBalance.getLabelAr(NormalBalance.debit))),
                        DropdownMenuItem(value: NormalBalance.credit, child: Text(NormalBalance.getLabelAr(NormalBalance.credit))),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => normalBalance = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('يتطلب تحديد مشروع عند التسجيل', style: TextStyle(fontSize: 13)),
                      value: requiresProject,
                      onChanged: (val) => setDialogState(() => requiresProject = val),
                      dense: true,
                    ),
                    SwitchListTile(
                      title: const Text('يتطلب تحديد بند تحليلي عند التسجيل', style: TextStyle(fontSize: 13)),
                      value: requiresAnalytical,
                      onChanged: (val) => setDialogState(() => requiresAnalytical = val),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (codeController.text.trim().isEmpty || nameArController.text.trim().isEmpty) return;
                  final accounting = Provider.of<AccountingProvider>(context, listen: false);
                  final acc = Account(
                    id: account?.id,
                    code: codeController.text.trim(),
                    name: nameEnController.text.trim().isEmpty ? nameArController.text.trim() : nameEnController.text.trim(),
                    nameAr: nameArController.text.trim(),
                    accountType: accountType,
                    subType: subType,
                    normalBalance: normalBalance,
                    requiresProject: requiresProject,
                    requiresAnalytical: requiresAnalytical,
                  );
                  await accounting.saveAccount(acc);
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleDeleteOrDeactivate(Account account) async {
    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعطيل أو حذف الحساب'),
        content: Text('هل تريد تعطيل الحساب "${account.nameAr}"؟\nملاحظة: الحسابات التي عليها حركات قيود يتم تعطيلها ولا يتم حذفها نهائياً حفاظاً على سلامة الدفاتر المحاسبية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تأكيد التعطيل'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await accounting.deleteAccount(account.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث حالة الحساب بنجاح.')),
        );
      } catch (e) {
        await accounting.deactivateAccount(account.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.warning),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filteredAccounts = accounting.accounts.where((a) {
      if (_selectedCategory != 'all' && a.accountType != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty) {
        return a.code.contains(query) || a.nameAr.contains(query) || a.name.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    final columns = [
      FinancialTableColumn(title: 'كود الحساب', width: 110),
      FinancialTableColumn(title: 'اسم الحساب', width: 280),
      FinancialTableColumn(title: 'التصنيف الرئيسي', width: 140),
      FinancialTableColumn(title: 'طبيعة الحساب', width: 110),
      FinancialTableColumn(title: 'إجمالي الحركات', width: 130, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الرصيد الفعلي الحالي', width: 150, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الحالة', width: 90),
      FinancialTableColumn(title: 'الإجراءات', width: 140),
    ];

    final rows = filteredAccounts.map((a) {
      return [
        Text(a.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        InkWell(
          onTap: () => widget.onNavigate('general_ledger', accountId: a.id),
          child: Text(
            a.nameAr,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryLight, decoration: TextDecoration.underline),
          ),
        ),
        Text(AccountType.getLabelAr(a.accountType)),
        Text(
          NormalBalance.getLabelAr(a.normalBalance),
          style: TextStyle(
            color: a.normalBalance == NormalBalance.debit ? AppColors.debit : AppColors.credit,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          Formatters.formatCurrency(a.totalDebit + a.totalCredit),
          textAlign: TextAlign.end,
        ),
        Text(
          Formatters.formatCurrency(a.currentBalance),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: a.currentBalance >= 0 ? AppColors.textPrimaryLight : AppColors.danger,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: a.isActive ? AppColors.successLight : AppColors.dangerLight,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            a.isActive ? 'نشط' : 'معطل',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: a.isActive ? AppColors.success : AppColors.danger,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primaryLight),
              tooltip: 'كشف الحساب / دفتر الأستاذ',
              onPressed: () => widget.onNavigate('general_ledger', accountId: a.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'تعديل',
              onPressed: () => _openAccountDialog(a),
            ),
            IconButton(
              icon: Icon(a.isActive ? Icons.block_rounded : Icons.check_circle_outline, size: 18, color: AppColors.danger),
              tooltip: a.isActive ? 'تعطيل الحساب' : 'تفعيل الحساب',
              onPressed: () => a.isActive ? _handleDeleteOrDeactivate(a) : accounting.activateAccount(a.id!),
            ),
          ],
        ),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'بحث بكود أو اسم الحساب...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'التصنيف الرئيسي', isDense: true),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('جميع الحسابات')),
                      DropdownMenuItem(value: AccountType.asset, child: Text(AccountType.getLabelAr(AccountType.asset))),
                      DropdownMenuItem(value: AccountType.liability, child: Text(AccountType.getLabelAr(AccountType.liability))),
                      DropdownMenuItem(value: AccountType.equity, child: Text(AccountType.getLabelAr(AccountType.equity))),
                      DropdownMenuItem(value: AccountType.revenue, child: Text(AccountType.getLabelAr(AccountType.revenue))),
                      DropdownMenuItem(value: AccountType.expense, child: Text(AccountType.getLabelAr(AccountType.expense))),
                    ],
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openAccountDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة حساب جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Accounts Table
          Expanded(
            child: accounting.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد حسابات مطابقة لمعايير البحث.',
                  ),
          ),
        ],
      ),
    );
  }
}
