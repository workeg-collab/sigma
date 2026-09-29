import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/report_provider.dart';
import '../../widgets/financial_table.dart';

class CashBankScreen extends StatefulWidget {
  final Function(String route, {int? accountId}) onNavigateToAccount;

  const CashBankScreen({super.key, required this.onNavigateToAccount});

  @override
  State<CashBankScreen> createState() => _CashBankScreenState();
}

class _CashBankScreenState extends State<CashBankScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadCashBankPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = Provider.of<ReportProvider>(context);

    double totalCash = 0.0;
    double totalBank = 0.0;
    for (var item in report.cashBankItems) {
      if (item.type == 'cash') totalCash += item.currentBalance;
      if (item.type == 'bank') totalBank += item.currentBalance;
    }
    final totalLiquidity = totalCash + totalBank;

    final columns = [
      FinancialTableColumn(title: 'كود الحساب', width: 110),
      FinancialTableColumn(title: 'اسم الحساب', width: 260),
      FinancialTableColumn(title: 'النوع', width: 120),
      FinancialTableColumn(title: 'رصيد أول المدة', width: 140, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'المقبوضات (مدين)', width: 140, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'المدفوعات (دائن)', width: 140, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الرصيد المتاح الحالي', width: 160, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الإجراءات', width: 120),
    ];

    final rows = report.cashBankItems.map((item) {
      return [
        Text(item.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        InkWell(
          onTap: () => widget.onNavigateToAccount('general_ledger', accountId: item.accountId),
          child: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryLight, decoration: TextDecoration.underline),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: item.type == 'cash' ? Colors.amber.withAlpha(30) : Colors.blue.withAlpha(30),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            item.type == 'cash' ? 'خزينة / نقدية' : 'حساب بنكي',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: item.type == 'cash' ? Colors.amber[800] : Colors.blue[800],
            ),
          ),
        ),
        Text(Formatters.formatCurrency(item.openingBalance), textAlign: TextAlign.end),
        Text(Formatters.formatCurrency(item.debitMovement), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.debit)),
        Text(Formatters.formatCurrency(item.creditMovement), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.credit)),
        Text(
          Formatters.formatCurrency(item.currentBalance),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: item.currentBalance >= 0 ? AppColors.textPrimaryLight : AppColors.danger,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.menu_book_rounded, size: 18, color: AppColors.primaryLight),
          tooltip: 'كشف حركة الصندوق / البنك',
          onPressed: () => widget.onNavigateToAccount('general_ledger', accountId: item.accountId),
        ),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Liquidity Overview Cards
          Row(
            children: [
              _liquidityCard('إجمالي السيولة النقدية المتاحة', totalLiquidity, AppColors.primaryLight, Icons.account_balance_wallet_rounded),
              const SizedBox(width: 16),
              _liquidityCard('أرصدة الخزينة والصناديق النقدية', totalCash, Colors.amber[700]!, Icons.savings_rounded),
              const SizedBox(width: 16),
              _liquidityCard('أرصدة الحسابات البنكية', totalBank, AppColors.secondary, Icons.account_balance_rounded),
            ],
          ),
          const SizedBox(height: 24),

          // Accounts Table
          const Text('تفاصيل أرصدة وحركات الخزائن والبنوك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: report.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد حسابات بنكية أو نقدية معرفة.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _liquidityCard(String title, double amount, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Text(
                  Formatters.formatCurrency(amount),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
