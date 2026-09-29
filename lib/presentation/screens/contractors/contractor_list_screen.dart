import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/party.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';

class ContractorListScreen extends StatefulWidget {
  final Function(String route, {int? contractorId}) onNavigate;

  const ContractorListScreen({super.key, required this.onNavigate});

  @override
  State<ContractorListScreen> createState() => _ContractorListScreenState();
}

class _ContractorListScreenState extends State<ContractorListScreen> {
  final _searchController = TextEditingController();
  int? _selectedProject;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openContractorDialog([Contractor? contractor]) {
    final codeController = TextEditingController(text: contractor?.code ?? '');
    final nameController = TextEditingController(text: contractor?.name ?? '');
    final phoneController = TextEditingController(text: contractor?.phone ?? '');
    final opBalanceController = TextEditingController(
        text: contractor?.openingBalance != null && contractor!.openingBalance > 0
            ? contractor.openingBalance.toString()
            : '');
    int? projectId = contractor?.projectId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final accounting = Provider.of<AccountingProvider>(context, listen: false);
          return AlertDialog(
            title: Text(contractor == null ? 'إضافة مقاول باطن جديد' : 'تعديل بيانات المقاول: ${contractor.name}'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'كود المقاول *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم المقاول / الشركة *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف والتواصل', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: projectId,
                    decoration: const InputDecoration(labelText: 'المشروع التابع له', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('عام / غير محدد')),
                      ...accounting.projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) => setDialogState(() => projectId = val),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: opBalanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي المستحق للمقاول (ج.م)', isDense: true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
                  final c = Contractor(
                    id: contractor?.id,
                    code: codeController.text.trim(),
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    projectId: projectId,
                    openingBalance: double.tryParse(opBalanceController.text.trim()) ?? 0.0,
                  );
                  await accounting.saveContractor(c);
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

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final query = _searchController.text.trim().toLowerCase();
    final filtered = accounting.contractors.where((c) {
      if (_selectedProject != null && c.projectId != _selectedProject) return false;
      if (query.isNotEmpty) {
        return c.code.toLowerCase().contains(query) || c.name.contains(query);
      }
      return true;
    }).toList();

    final columns = [
      FinancialTableColumn(title: 'كود المقاول', width: 110),
      FinancialTableColumn(title: 'اسم المقاول', width: 240),
      FinancialTableColumn(title: 'الهاتف', width: 120),
      FinancialTableColumn(title: 'رصيد أول المدة', width: 130, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'إجمالي المستخلصات (دائن)', width: 150, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'إجمالي المسدد له (مدين)', width: 140, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الرصيد الحالي المستحق', width: 150, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الإجراءات', width: 120),
    ];

    final rows = filtered.map((c) {
      return [
        Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        InkWell(
          onTap: () => widget.onNavigate('contractor_statement', contractorId: c.id),
          child: Text(
            c.name,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryLight, decoration: TextDecoration.underline),
          ),
        ),
        Text(c.phone ?? '-'),
        Text(Formatters.formatCurrency(c.openingBalance), textAlign: TextAlign.end),
        Text(
          Formatters.formatCurrency(c.totalCredit),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.credit),
        ),
        Text(
          Formatters.formatCurrency(c.totalDebit),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.debit),
        ),
        Text(
          Formatters.formatCurrency(c.currentBalance),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: c.currentBalance > 0 ? AppColors.danger : AppColors.success,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primaryLight),
              tooltip: 'كشف حساب المقاول',
              onPressed: () => widget.onNavigate('contractor_statement', contractorId: c.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'تعديل',
              onPressed: () => _openContractorDialog(c),
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
          // Filter Bar
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
                      hintText: 'بحث باسم أو كود المقاول...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedProject,
                    decoration: const InputDecoration(labelText: 'تصفية حسب المشروع', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('جميع المشروعات')),
                      ...accounting.projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedProject = val),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openContractorDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة مقاول جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contractors Table
          Expanded(
            child: accounting.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد بيانات مقاولين مسجلة.',
                  ),
          ),
        ],
      ),
    );
  }
}
