import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/export_service.dart';
import '../../../domain/models/report_models.dart';
import '../../providers/report_provider.dart';
import '../../widgets/status_badge.dart';

class BalanceSheetScreen extends StatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  State<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends State<BalanceSheetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadBalanceSheet();
    });
  }

  void _handlePrint(BalanceSheetReport report) {
    ExportService.printReport(
      title: 'الميزانية العمومية والمركز المالي',
      subtitle: 'كما في: ${DateTime.now().toIso8601String().substring(0, 10)}',
      headers: ['البيان', 'المبلغ (ج.م)'],
      rows: [
        ['إجمالي الأصول المتداولة', Formatters.formatCurrency(report.totalCurrentAssets)],
        ['إجمالي الأصول الثابتة', Formatters.formatCurrency(report.totalFixedAssets)],
        ['إجمالي الأصول (Assets)', Formatters.formatCurrency(report.totalAssets)],
        ['إجمالي الخصوم والالتزامات المتداولة', Formatters.formatCurrency(report.totalCurrentLiabilities)],
        ['أرصدة المقاولين المستحقة', Formatters.formatCurrency(report.contractorBalances)],
        ['رأس المال', Formatters.formatCurrency(report.capital)],
        ['جاري الشريك', Formatters.formatCurrency(report.partnersCurrentAccounts)],
        ['صافي أرباح العام الحالي', Formatters.formatCurrency(report.currentYearProfit)],
        ['إجمالي الخصوم وحقوق الملكية (Liabilities + Equity)', Formatters.formatCurrency(report.totalLiabilitiesAndEquity)],
      ],
      summary: {
        'إجمالي الأصول': Formatters.formatCurrency(report.totalAssets),
        'إجمالي الخصوم وحقوق الملكية': Formatters.formatCurrency(report.totalLiabilitiesAndEquity),
        'حالة التوازن': report.isBalanced ? 'متزنة محاسبياً' : 'غير متزنة',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportProvider>(context);
    final report = reportProv.balanceSheet;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (reportProv.isLoading || report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'الميزانية العمومية وقائمة المركز المالي',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الأصول = الخصوم + حقوق الملكية | كما في ${DateTime.now().toIso8601String().substring(0, 10)}',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StatusBadge(status: report.isBalanced ? 'balanced' : 'out_of_balance'),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _handlePrint(report),
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('طباعة الميزانية PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 16),

              // Two Columns Layout: Assets (Right) and Liabilities + Equity (Left)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Right Column: Assets (الأصول)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('أولاً: الأصول (Assets)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryLight)),
                          const SizedBox(height: 12),

                          const Text('1. الأصول المتداولة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ...report.currentAssets.map((ca) => _itemRow(ca.name, ca.amount)),
                          _subtotalRow('إجمالي الأصول المتداولة', report.totalCurrentAssets),
                          const SizedBox(height: 16),

                          const Text('2. الأصول الثابتة وغير المتداولة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ...report.fixedAssets.map((fa) => _itemRow(fa.name, fa.amount)),
                          if (report.accumulatedDepreciation > 0)
                            _itemRow('يخصم: مجمع الإهلاك', -report.accumulatedDepreciation, isNegative: true),
                          _subtotalRow('صافي الأصول الثابتة', report.netFixedAssets),
                          const SizedBox(height: 24),

                          // Total Assets Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي الأصول', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                                Text(
                                  Formatters.formatCurrency(report.totalAssets),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryLight),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Left Column: Liabilities + Equity (الخصوم وحقوق الملكية)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ثانياً: الخصوم وحقوق الملكية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.secondary)),
                          const SizedBox(height: 12),

                          const Text('1. الالتزامات المتداولة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ...report.currentLiabilities.map((cl) => _itemRow(cl.name, cl.amount)),
                          _subtotalRow('إجمالي الخصوم المتداولة', report.totalCurrentLiabilities),
                          const SizedBox(height: 16),

                          const Text('2. حقوق الملكية (Equity)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          _itemRow('رأس المال المدفوع', report.capital),
                          _itemRow('جاري الشريك', report.partnersCurrentAccounts),
                          if (report.retainedEarnings != 0)
                            _itemRow('أرباح مرحلة', report.retainedEarnings),
                          _itemRow('صافي أرباح الفترة الحالية', report.currentYearProfit, highlightColor: report.currentYearProfit >= 0 ? AppColors.success : AppColors.danger),
                          _subtotalRow('إجمالي حقوق الملكية', report.totalEquity),
                          const SizedBox(height: 24),

                          // Total Liabilities and Equity Box
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('إجمالي الخصوم وحقوق الملكية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                                Text(
                                  Formatters.formatCurrency(report.totalLiabilitiesAndEquity),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.secondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reconciliation Verification Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: report.isBalanced ? AppColors.successLight : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: report.isBalanced ? AppColors.success : AppColors.danger),
                ),
                child: Row(
                  children: [
                    Icon(
                      report.isBalanced ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: report.isBalanced ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      report.isBalanced
                          ? 'معادلة الميزانية متحققة ومتزنة: إجمالي الأصول = إجمالي الخصوم وحقوق الملكية'
                          : 'الميزانية غير متزنة! الفرق: ${Formatters.formatCurrency(report.difference)} ج.م',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: report.isBalanced ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(String title, double amount, {bool isNegative = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12.5)),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlightColor ?? (isNegative ? AppColors.danger : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subtotalRow(String title, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Container(
        padding: const EdgeInsets.only(top: 4),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFCBD5E1), width: 0.8))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(
              Formatters.formatCurrency(amount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
