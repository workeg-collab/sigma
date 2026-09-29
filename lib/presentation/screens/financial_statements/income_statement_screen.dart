import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/export_service.dart';
import '../../../domain/models/report_models.dart';
import '../../providers/report_provider.dart';

class IncomeStatementScreen extends StatefulWidget {
  const IncomeStatementScreen({super.key});

  @override
  State<IncomeStatementScreen> createState() => _IncomeStatementScreenState();
}

class _IncomeStatementScreenState extends State<IncomeStatementScreen> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  void _loadData() {
    Provider.of<ReportProvider>(context, listen: false).loadIncomeStatement(
      from: _fromController.text.trim().isNotEmpty ? _fromController.text.trim() : null,
      to: _toController.text.trim().isNotEmpty ? _toController.text.trim() : null,
    );
  }

  void _handlePrint(IncomeStatementReport report) {
    ExportService.printReport(
      title: 'قائمة الدخل والأرباح والخسائر',
      subtitle: 'الفترة المالية الحالية 2026',
      headers: ['البند المحاسبي', 'المبلغ الجزئي (ج.م)', 'المبلغ الكلي (ج.م)'],
      rows: [
        ['صافي إيرادات النشاط والمبيعات', '', Formatters.formatCurrency(report.netSales)],
        ['تكلفة المبيعات وتكاليف المشروعات', '', Formatters.formatCurrency(report.costOfSales)],
        ['مجمل الربح (Gross Profit)', '', Formatters.formatCurrency(report.grossProfit)],
        ['المصروفات العمومية والإدارية', Formatters.formatCurrency(report.generalAdminExpenses), ''],
        ['مصروفات الموقع والتشغيل', Formatters.formatCurrency(report.siteExpenses), ''],
        ['إجمالي المصروفات التشغيلية', '', Formatters.formatCurrency(report.totalOperatingExpenses)],
        ['الربح التشغيلي (Operating Profit)', '', Formatters.formatCurrency(report.operatingProfit)],
        ['مصروف الإهلاك والضرائب', '', Formatters.formatCurrency(report.depreciationExpense + report.taxExpense)],
        ['صافي الربح النهائي القابل للتوزيع', '', Formatters.formatCurrency(report.netProfit)],
      ],
      summary: {
        'صافي الإيراد': Formatters.formatCurrency(report.netSales),
        'مجمل الربح': Formatters.formatCurrency(report.grossProfit),
        'صافي الربح': Formatters.formatCurrency(report.netProfit),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportProvider>(context);
    final report = reportProv.incomeStatement;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (reportProv.isLoading || report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
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
                        'قائمة الدخل والأرباح والخسائر',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'شركة سيجما للمقاولات والتشييد | السنة المالية 2026',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _handlePrint(report),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('طباعة وتصدير PDF'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(thickness: 1.5),
              const SizedBox(height: 16),

              // 1. Net Sales Section
              _statementSectionTitle('إيرادات النشاط'),
              _statementRow('إجمالي المبيعات والمستخلصات', report.grossSales, isSub: true),
              if (report.salesReturns > 0)
                _statementRow('يخصم: مردودات المبيعات', -report.salesReturns, isSub: true, isNegative: true),
              _statementRow('صافي المبيعات والإيرادات', report.netSales, isBold: true, highlightColor: AppColors.success),
              const SizedBox(height: 16),

              // 2. Cost of Sales
              _statementSectionTitle('تكلفة المبيعات وتكاليف المشروعات'),
              _statementRow('مشتريات مواد العمليات', report.purchases, isSub: true),
              _statementRow('تكاليف مشروعات وعمالة مباشرة ومقاولين', report.directProjectCosts, isSub: true),
              if (report.purchaseReturns > 0)
                _statementRow('يخصم: مردودات المشتريات', -report.purchaseReturns, isSub: true, isNegative: true),
              _statementRow('إجمالي تكلفة المبيعات', report.costOfSales, isBold: true, highlightColor: AppColors.danger),
              const SizedBox(height: 16),

              // 3. Gross Profit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مجمل الربح (Gross Profit)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    Text(
                      Formatters.formatCurrency(report.grossProfit),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: report.grossProfit >= 0 ? AppColors.success : AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Operating Expenses
              _statementSectionTitle('المصروفات الإدارية والعمومية ومصروفات الموقع'),
              _statementRow('مصروفات عمومية وإدارية', report.generalAdminExpenses, isSub: true),
              _statementRow('مصروفات موقع وكرفانات وصيانة', report.siteExpenses, isSub: true),
              if (report.operatingExpenses > 0)
                _statementRow('مصروفات تشغيلية أخرى', report.operatingExpenses, isSub: true),
              _statementRow('إجمالي المصروفات التشغيلية', report.totalOperatingExpenses, isBold: true),
              const SizedBox(height: 16),

              // 5. Operating Profit
              _statementRow('الربح التشغيلي (Operating Profit)', report.operatingProfit, isBold: true),
              const SizedBox(height: 16),

              // 6. Depreciation & Taxes
              if (report.depreciationExpense > 0)
                _statementRow('مصروف الإهلاك', report.depreciationExpense, isSub: true),
              if (report.taxExpense > 0)
                _statementRow('مخصص الضرائب', report.taxExpense, isSub: true),
              const SizedBox(height: 16),

              // 7. Net Profit
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: report.netProfit >= 0 ? AppColors.successLight : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: report.netProfit >= 0 ? AppColors.success : AppColors.danger,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'صافي الربح بعد الضرائب والتكاليف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: report.netProfit >= 0 ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('صافي الأرباح القابلة للتوزيع للملاك والشركاء', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    Text(
                      Formatters.formatCurrency(report.netProfit),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: report.netProfit >= 0 ? AppColors.success : AppColors.danger,
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

  Widget _statementSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
      ),
    );
  }

  Widget _statementRow(String title, double amount, {bool isSub = false, bool isBold = false, bool isNegative = false, Color? highlightColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isBold ? 8 : 4, horizontal: isSub ? 16 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isBold ? 14 : 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: highlightColor ?? (isNegative ? AppColors.danger : null),
            ),
          ),
        ],
      ),
    );
  }
}
