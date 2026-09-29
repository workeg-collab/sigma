import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/export_service.dart';
import '../../providers/report_provider.dart';
import '../../widgets/financial_table.dart';

import '../../../domain/models/report_models.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final VoidCallback onBack;

  const ProjectDetailScreen({super.key, required this.projectId, required this.onBack});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadProjectCost(widget.projectId);
    });
  }

  void _handlePrint(ProjectCostReport report) {
    ExportService.printReport(
      title: 'تقرير تحليل تكاليف وأرباح المشروع: ${report.projectName}',
      subtitle: 'كود المشروع: ${report.projectCode} | العميل: ${report.client ?? "-"}',
      headers: ['بند التكلفة / التوجيه التحليلي', 'المبلغ (ج.م)'],
      rows: report.costByAnalyticalItem.entries.map<List<String>>((e) {
        return [e.key, Formatters.formatCurrency(e.value)];
      }).toList(),
      summary: {
        'الموازنة': Formatters.formatCurrency(report.budget),
        'إجمالي التكاليف': Formatters.formatCurrency(report.totalCost),
        'إجمالي الإيرادات': Formatters.formatCurrency(report.revenue),
        'مجمل الربح': Formatters.formatCurrency(report.grossProfit),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportProvider>(context);
    final report = reportProv.projectCostReport;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (reportProv.isLoading || report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final analyticalColumns = [
      FinancialTableColumn(title: 'بند التوجيه التحليلي', width: 280),
      FinancialTableColumn(title: 'إجمالي التكلفة الفعلية (ج.م)', width: 180, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'النسبة من إجمالي تكاليف المشروع', width: 180, textAlign: TextAlign.end),
    ];

    final analyticalRows = report.costByAnalyticalItem.entries.map((e) {
      final pct = (report.totalCost > 0) ? (e.value / report.totalCost * 100) : 0.0;
      return [
        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(Formatters.formatCurrency(e.value), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger)),
        Text('${pct.toStringAsFixed(1)}%', textAlign: TextAlign.end),
      ];
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: widget.onBack,
                tooltip: 'العودة للمشروعات',
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${report.projectCode} - ${report.projectName}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  if (report.client != null)
                    Text('العميل: ${report.client}', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _handlePrint(report),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('طباعة التقرير PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Top KPIs Grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _kpiBox('الموازنة التقديرية', report.budget, isDark ? const Color(0xFF1E293B) : Colors.white, AppColors.primaryLight),
              _kpiBox('إجمالي الإيرادات', report.revenue, isDark ? const Color(0xFF1E293B) : Colors.white, AppColors.success),
              _kpiBox('إجمالي التكاليف الفعلية', report.totalCost, isDark ? const Color(0xFF1E293B) : Colors.white, AppColors.danger),
              _kpiBox(
                'مجمل الربح',
                report.grossProfit,
                isDark ? const Color(0xFF1E293B) : Colors.white,
                report.grossProfit >= 0 ? AppColors.success : AppColors.danger,
                subtitle: 'هامش الربح: ${report.profitMargin.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Cost Breakdown by Nature / Category
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تحليل التكاليف وفق طبيعة البنود', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _categoryCostItem('مواد مباشرة وتوريدات', report.directMaterials, report.totalCost),
                    _categoryCostItem('أجور وعمالة مباشرة', report.labor, report.totalCost),
                    _categoryCostItem('مقاولي باطن ومسلحات', report.subcontractors, report.totalCost),
                    _categoryCostItem('معدات وحفر وإحلال', report.equipment, report.totalCost),
                    _categoryCostItem('نقل ومشاوير', report.transportation, report.totalCost),
                    _categoryCostItem('مصروفات موقع وكرفانات', report.siteExpenses, report.totalCost),
                    _categoryCostItem('مصروفات صيانة', report.maintenance, report.totalCost),
                    _categoryCostItem('مصروفات عمومية وأخرى', report.generalExpenses + report.otherCosts, report.totalCost),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cost by Analytical Items Table
          const Text('تفاصيل التكاليف حسب بنود التوجيه التحليلي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FinancialTable(
            columns: analyticalColumns,
            rows: analyticalRows,
            footerRow: [
              const Text('إجمالي تكاليف المشروع', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(Formatters.formatCurrency(report.totalCost), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
              const Text('100.0%', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiBox(String title, double amount, Color bg, Color textCol, {String? subtitle}) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textCol.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            Formatters.formatCurrency(amount),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textCol),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol)),
          ],
        ],
      ),
    );
  }

  Widget _categoryCostItem(String label, double amount, double total) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withAlpha(150),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}
