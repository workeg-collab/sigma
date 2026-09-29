import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/export_service.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/financial_table.dart';
import '../../widgets/status_badge.dart';

import '../../../domain/models/report_models.dart';

class TrialBalanceScreen extends StatefulWidget {
  final Function(String route, {int? accountId}) onNavigateToAccount;

  const TrialBalanceScreen({super.key, required this.onNavigateToAccount});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  int _viewMode = 0; // 0: By Balances (بالأرصدة), 1: By Totals (بالمجاميع)
  int? _selectedProjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    Provider.of<ReportProvider>(context, listen: false).loadTrialBalance(
      projectId: _selectedProjectId,
    );
  }

  void _handlePrint(TrialBalanceReport report) {
    if (_viewMode == 0) {
      // By Balances
      ExportService.printReport(
        title: 'ميزان المراجعة بالأرصدة',
        subtitle: 'تاريخ الاستخراج: ${DateTime.now().toIso8601String().substring(0, 10)}',
        headers: [
          'كود الحساب', 'اسم الحساب',
          'افتتاحي مدين', 'افتتاحي دائن',
          'حركة مدين', 'حركة دائن',
          'ختامي مدين', 'ختامي دائن'
        ],
        rows: report.items.map<List<String>>((i) => [
          i.account.code,
          i.account.nameAr,
          Formatters.formatCurrency(i.openingDebit),
          Formatters.formatCurrency(i.openingCredit),
          Formatters.formatCurrency(i.movementDebit),
          Formatters.formatCurrency(i.movementCredit),
          Formatters.formatCurrency(i.closingDebit),
          Formatters.formatCurrency(i.closingCredit),
        ]).toList(),
        summary: {
          'إجمالي الأرصدة المدينة': Formatters.formatCurrency(report.totalClosingDebit),
          'إجمالي الأرصدة الدائنة': Formatters.formatCurrency(report.totalClosingCredit),
          'الحالة': report.isBalanced ? 'متزن' : 'غير متزن',
        },
      );
    } else {
      // By Totals
      ExportService.printReport(
        title: 'ميزان المراجعة بالمجاميع',
        subtitle: 'تاريخ الاستخراج: ${DateTime.now().toIso8601String().substring(0, 10)}',
        headers: ['كود الحساب', 'اسم الحساب', 'إجمالي المدين', 'إجمالي الدائن', 'الفرق'],
        rows: report.items.map<List<String>>((i) => [
          i.account.code,
          i.account.nameAr,
          Formatters.formatCurrency(i.totalDebit),
          Formatters.formatCurrency(i.totalCredit),
          Formatters.formatCurrency(i.difference),
        ]).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportProv = Provider.of<ReportProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final report = reportProv.trialBalance;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final columnsByBalances = [
      FinancialTableColumn(title: 'كود الحساب', width: 95),
      FinancialTableColumn(title: 'اسم الحساب', width: 220),
      FinancialTableColumn(title: 'افتتاحي مدين', width: 110, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'افتتاحي دائن', width: 110, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'حركات مدين', width: 110, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'حركات دائن', width: 110, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'ختامي مدين', width: 120, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'ختامي دائن', width: 120, textAlign: TextAlign.end),
    ];

    final columnsByTotals = [
      FinancialTableColumn(title: 'كود الحساب', width: 110),
      FinancialTableColumn(title: 'اسم الحساب', width: 280),
      FinancialTableColumn(title: 'إجمالي المدين', width: 160, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'إجمالي الدائن', width: 160, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الفرق / الرصيد', width: 160, textAlign: TextAlign.end),
    ];

    final rows = (report?.items ?? []).map((item) {
      if (_viewMode == 0) {
        return [
          Text(item.account.code, style: const TextStyle(fontWeight: FontWeight.w700)),
          InkWell(
            onTap: () => widget.onNavigateToAccount('general_ledger', accountId: item.account.id),
            child: Text(
              item.account.nameAr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryLight, decoration: TextDecoration.underline),
            ),
          ),
          Text(Formatters.formatCurrency(item.openingDebit), textAlign: TextAlign.end),
          Text(Formatters.formatCurrency(item.openingCredit), textAlign: TextAlign.end),
          Text(Formatters.formatCurrency(item.movementDebit), textAlign: TextAlign.end, style: const TextStyle(color: AppColors.debit)),
          Text(Formatters.formatCurrency(item.movementCredit), textAlign: TextAlign.end, style: const TextStyle(color: AppColors.credit)),
          Text(
            Formatters.formatCurrency(item.closingDebit),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.debit),
          ),
          Text(
            Formatters.formatCurrency(item.closingCredit),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.credit),
          ),
        ];
      } else {
        return [
          Text(item.account.code, style: const TextStyle(fontWeight: FontWeight.w700)),
          InkWell(
            onTap: () => widget.onNavigateToAccount('general_ledger', accountId: item.account.id),
            child: Text(
              item.account.nameAr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryLight, decoration: TextDecoration.underline),
            ),
          ),
          Text(
            Formatters.formatCurrency(item.totalDebit),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.debit),
          ),
          Text(
            Formatters.formatCurrency(item.totalCredit),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.credit),
          ),
          Text(
            Formatters.formatCurrency(item.difference),
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ];
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Toggle Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // View Mode Toggle
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('ميزان المراجعة بالأرصدة')),
                    ButtonSegment(value: 1, label: Text('ميزان المراجعة بالمجاميع')),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (set) => setState(() => _viewMode = set.first),
                ),
                const SizedBox(width: 16),

                // Project Dropdown
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(labelText: 'تصفية بالمشروع', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('جميع المشروعات')),
                      ...accounting.projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedProjectId = val);
                      _loadData();
                    },
                  ),
                ),
                const Spacer(),

                // Balance Status Badge
                if (report != null) ...[
                  StatusBadge(status: report.isBalanced ? 'balanced' : 'out_of_balance'),
                  const SizedBox(width: 12),
                ],

                ElevatedButton.icon(
                  onPressed: report != null ? () => _handlePrint(report) : null,
                  icon: const Icon(Icons.print_rounded, size: 18),
                  label: const Text('طباعة الميزان'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Table
          Expanded(
            child: reportProv.isLoading || report == null
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: _viewMode == 0 ? columnsByBalances : columnsByTotals,
                    rows: rows,
                    footerRow: _viewMode == 0
                        ? [
                            const Text('الإجمالي العام', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text(''),
                            Text(Formatters.formatCurrency(report.totalOpeningDebit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(Formatters.formatCurrency(report.totalOpeningCredit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(Formatters.formatCurrency(report.totalMovementDebit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.debit)),
                            Text(Formatters.formatCurrency(report.totalMovementCredit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.credit)),
                            Text(Formatters.formatCurrency(report.totalClosingDebit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.debit)),
                            Text(Formatters.formatCurrency(report.totalClosingCredit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.credit)),
                          ]
                        : [
                            const Text('الإجمالي العام', style: TextStyle(fontWeight: FontWeight.bold)),
                            const Text(''),
                            Text(Formatters.formatCurrency(report.totalOpeningDebit + report.totalMovementDebit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.debit)),
                            Text(Formatters.formatCurrency(report.totalOpeningCredit + report.totalMovementCredit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.credit)),
                            Text(
                              Formatters.formatCurrency((report.totalOpeningDebit + report.totalMovementDebit) - (report.totalOpeningCredit + report.totalMovementCredit)),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                  ),
          ),
        ],
      ),
    );
  }
}
