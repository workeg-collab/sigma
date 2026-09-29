import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/export_service.dart';
import '../../../domain/models/party.dart';
import '../../../domain/models/report_models.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/financial_table.dart';

class ContractorStatementScreen extends StatefulWidget {
  final int contractorId;
  final VoidCallback onBack;
  final Function(String route, {int? entryId}) onNavigateToEntry;

  const ContractorStatementScreen({
    super.key,
    required this.contractorId,
    required this.onBack,
    required this.onNavigateToEntry,
  });

  @override
  State<ContractorStatementScreen> createState() => _ContractorStatementScreenState();
}

class _ContractorStatementScreenState extends State<ContractorStatementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).loadContractorStatement(widget.contractorId);
    });
  }

  void _handlePrint(Contractor contractor, List<ContractorLedgerRow> rows) {
    ExportService.printReport(
      title: 'كشف حساب المقاول: ${contractor.name}',
      subtitle: 'كود المقاول: ${contractor.code} | الهاتف: ${contractor.phone ?? "-"}',
      headers: ['التاريخ', 'رقم القيد', 'البيان', 'المشروع', 'مدين (المسدد)', 'دائن (المستخلص)', 'الرصيد التراكمي'],
      rows: rows.map<List<String>>((r) => [
        r.date,
        r.entryNumber,
        r.description,
        r.projectName ?? '-',
        Formatters.formatCurrency(r.debit),
        Formatters.formatCurrency(r.credit),
        Formatters.formatCurrency(r.runningBalance),
      ]).toList(),
      summary: {
        'رصيد أول المدة': Formatters.formatCurrency(contractor.openingBalance),
        'إجمالي المسدد': Formatters.formatCurrency(contractor.totalDebit),
        'إجمالي المستخلصات': Formatters.formatCurrency(contractor.totalCredit),
        'الرصيد الختامي': Formatters.formatCurrency(contractor.currentBalance),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = Provider.of<ReportProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final contractor = accounting.contractors.firstWhere(
      (c) => c.id == widget.contractorId,
      orElse: () => accounting.contractors.first,
    );

    final columns = [
      FinancialTableColumn(title: 'التاريخ', width: 100),
      FinancialTableColumn(title: 'رقم القيد', width: 110),
      FinancialTableColumn(title: 'البيان وتفاصيل المعاملة', width: 280),
      FinancialTableColumn(title: 'المشروع التابع', width: 160),
      FinancialTableColumn(title: 'مدين (المسدد له)', width: 130, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'دائن (مستخلصات وأعمال)', width: 140, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الرصيد التراكمي المستحق', width: 150, textAlign: TextAlign.end),
    ];

    final rows = report.contractorRows.map((r) {
      return [
        Text(r.date),
        InkWell(
          onTap: r.journalEntryId != null
              ? () => widget.onNavigateToEntry('journal_entry', entryId: r.journalEntryId)
              : null,
          child: Text(
            r.entryNumber,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: r.journalEntryId != null ? AppColors.primaryLight : null,
              decoration: r.journalEntryId != null ? TextDecoration.underline : null,
            ),
          ),
        ),
        Text(r.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(r.projectName ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(Formatters.formatCurrency(r.debit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.debit)),
        Text(Formatters.formatCurrency(r.credit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.credit)),
        Text(
          Formatters.formatCurrency(r.runningBalance),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: r.runningBalance > 0 ? AppColors.danger : AppColors.success,
          ),
        ),
      ];
    }).toList();

    return Padding(
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
                tooltip: 'العودة للمقاولين',
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كشف حساب: ${contractor.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'كود المقاول: ${contractor.code} | الهاتف: ${contractor.phone ?? "-"}',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _handlePrint(contractor, report.contractorRows),
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('طباعة كشف الحساب'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Header Cards
          Row(
            children: [
              _metricPill('رصيد أول المدة', contractor.openingBalance, Colors.grey),
              const SizedBox(width: 12),
              _metricPill('إجمالي المستخلصات (دائن)', contractor.totalCredit, AppColors.credit),
              const SizedBox(width: 12),
              _metricPill('إجمالي المسدد (مدين)', contractor.totalDebit, AppColors.debit),
              const SizedBox(width: 12),
              _metricPill('الرصيد الختامي المستحق للمقاول', contractor.currentBalance, AppColors.danger, isBold: true),
            ],
          ),
          const SizedBox(height: 20),

          // Statement Table
          Expanded(
            child: report.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد حركات مسجلة لهذا المقاول حالياً.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String title, double amount, Color color, {bool isBold = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(
              Formatters.formatCurrency(amount),
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
