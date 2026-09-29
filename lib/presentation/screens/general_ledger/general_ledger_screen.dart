import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/services/export_service.dart';
import '../../../domain/models/account.dart';
import '../../../domain/models/report_models.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/financial_table.dart';

class GeneralLedgerScreen extends StatefulWidget {
  final int? initialAccountId;
  final Function(String route, {int? entryId}) onNavigateToEntry;

  const GeneralLedgerScreen({
    super.key,
    this.initialAccountId,
    required this.onNavigateToEntry,
  });

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  int? _selectedAccountId;
  int? _selectedProjectId;
  int? _selectedAnalyticalId;
  int? _selectedContractorId;
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accounting = Provider.of<AccountingProvider>(context, listen: false);
      if (accounting.accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = widget.initialAccountId ?? accounting.accounts.first.id;
        });
        _loadLedger();
      }
    });
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  void _loadLedger() {
    if (_selectedAccountId == null) return;
    Provider.of<ReportProvider>(context, listen: false).loadGeneralLedger(
      accountId: _selectedAccountId!,
      from: _dateFromController.text.trim().isNotEmpty ? _dateFromController.text.trim() : null,
      to: _dateToController.text.trim().isNotEmpty ? _dateToController.text.trim() : null,
      projectId: _selectedProjectId,
      analyticalItemId: _selectedAnalyticalId,
      contractorId: _selectedContractorId,
    );
  }

  void _handlePrint(Account account, List<LedgerRow> rows) {
    ExportService.printReport(
      title: 'دفتر الأستاذ العام / كشف حساب: ${account.nameAr}',
      subtitle: 'كود الحساب: ${account.code} | طبيعة الحساب: ${account.normalBalance == "debit" ? "مدين" : "دائن"}',
      headers: ['التاريخ', 'رقم القيد', 'البيان', 'المشروع', 'مدين', 'دائن', 'الرصيد التراكمي'],
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
        'الرصيد الختامي': Formatters.formatCurrency(rows.isNotEmpty ? rows.last.runningBalance : 0.0),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = Provider.of<ReportProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final account = accounting.accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => accounting.accounts.first,
    );

    final columns = [
      FinancialTableColumn(title: 'التاريخ', width: 100),
      FinancialTableColumn(title: 'رقم القيد', width: 110),
      FinancialTableColumn(title: 'البيان وشرح الحركة', width: 260),
      FinancialTableColumn(title: 'المشروع', width: 150),
      FinancialTableColumn(title: 'بند تحليلي', width: 140),
      FinancialTableColumn(title: 'مدين', width: 120, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'دائن', width: 120, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الرصيد التراكمي', width: 140, textAlign: TextAlign.end),
    ];

    final rows = report.ledgerRows.map((r) {
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
        Text(r.analyticalName ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(Formatters.formatCurrency(r.debit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.debit)),
        Text(Formatters.formatCurrency(r.credit), textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.credit)),
        Text(
          Formatters.formatCurrency(r.runningBalance),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Account Dropdown
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<int>(
                        value: _selectedAccountId,
                        decoration: const InputDecoration(labelText: 'الحساب المالي المطلوب *', isDense: true),
                        items: accounting.accounts.map((a) {
                          return DropdownMenuItem(
                            value: a.id,
                            child: Text('${a.code} - ${a.nameAr}', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedAccountId = val);
                          _loadLedger();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Project Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int?>(
                        value: _selectedProjectId,
                        decoration: const InputDecoration(labelText: 'المشروع', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('جميع المشروعات')),
                          ...accounting.projects.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(p.name, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedProjectId = val);
                          _loadLedger();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Contractor Dropdown
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int?>(
                        value: _selectedContractorId,
                        decoration: const InputDecoration(labelText: 'المقاول', isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('جميع المقاولين')),
                          ...accounting.contractors.map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedContractorId = val);
                          _loadLedger();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Print Button
                    ElevatedButton.icon(
                      onPressed: () => _handlePrint(account, report.ledgerRows),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text('طباعة كشف الحساب'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ledger Table
          Expanded(
            child: report.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد حركات مسجلة لهذا الحساب وفق خيارات التصفية.',
                  ),
          ),
        ],
      ),
    );
  }
}
