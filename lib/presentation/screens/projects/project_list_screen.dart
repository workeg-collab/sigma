import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/project.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';
import '../../widgets/status_badge.dart';

class ProjectListScreen extends StatefulWidget {
  final Function(String route, {int? projectId}) onNavigate;

  const ProjectListScreen({super.key, required this.onNavigate});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProjectDialog([Project? project]) {
    final codeController = TextEditingController(text: project?.code ?? '');
    final nameController = TextEditingController(text: project?.name ?? '');
    final clientController = TextEditingController(text: project?.client ?? '');
    final budgetController = TextEditingController(text: project?.budget != null && project!.budget > 0 ? project.budget.toString() : '');
    String status = project?.status ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(project == null ? 'إضافة مشروع جديد' : 'تعديل مشروع: ${project.name}'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'كود المشروع *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم المشروع *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: clientController,
                    decoration: const InputDecoration(labelText: 'العميل / جهة الإسناد', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: budgetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'الموازنة التقديرية (ج.م)', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'حالة المشروع', isDense: true),
                    items: [
                      DropdownMenuItem(value: ProjectStatus.planning, child: Text(ProjectStatus.getLabelAr(ProjectStatus.planning))),
                      DropdownMenuItem(value: ProjectStatus.active, child: Text(ProjectStatus.getLabelAr(ProjectStatus.active))),
                      DropdownMenuItem(value: ProjectStatus.onHold, child: Text(ProjectStatus.getLabelAr(ProjectStatus.onHold))),
                      DropdownMenuItem(value: ProjectStatus.completed, child: Text(ProjectStatus.getLabelAr(ProjectStatus.completed))),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => status = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
                  final accounting = Provider.of<AccountingProvider>(context, listen: false);
                  final p = Project(
                    id: project?.id,
                    code: codeController.text.trim(),
                    name: nameController.text.trim(),
                    client: clientController.text.trim(),
                    budget: double.tryParse(budgetController.text.trim()) ?? 0.0,
                    status: status,
                  );
                  await accounting.saveProject(p);
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ المشروع'),
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
    final filteredProjects = accounting.projects.where((p) {
      if (_selectedStatus != 'all' && p.status != _selectedStatus) return false;
      if (query.isNotEmpty) {
        return p.code.toLowerCase().contains(query) || p.name.contains(query) || (p.client?.contains(query) ?? false);
      }
      return true;
    }).toList();

    final columns = [
      FinancialTableColumn(title: 'كود المشروع', width: 110),
      FinancialTableColumn(title: 'اسم المشروع', width: 220),
      FinancialTableColumn(title: 'العميل', width: 160),
      FinancialTableColumn(title: 'الموازنة التقديرية', width: 130, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'إجمالي التكاليف الفعلية', width: 140, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'إجمالي الإيرادات', width: 130, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'مجمل الربح', width: 120, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'هامش الربح', width: 90, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الحالة', width: 90),
      FinancialTableColumn(title: 'الإجراءات', width: 120),
    ];

    final rows = filteredProjects.map((p) {
      return [
        Text(p.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        InkWell(
          onTap: () => widget.onNavigate('project_detail', projectId: p.id),
          child: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryLight, decoration: TextDecoration.underline),
          ),
        ),
        Text(p.client ?? '-'),
        Text(Formatters.formatCurrency(p.budget), textAlign: TextAlign.end),
        Text(
          Formatters.formatCurrency(p.totalCost),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger),
        ),
        Text(
          Formatters.formatCurrency(p.totalRevenue),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
        ),
        Text(
          Formatters.formatCurrency(p.grossProfit),
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: p.grossProfit >= 0 ? AppColors.success : AppColors.danger,
          ),
        ),
        Text(
          '${p.profitMargin.toStringAsFixed(1)}%',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: p.profitMargin >= 0 ? AppColors.success : AppColors.danger,
          ),
        ),
        StatusBadge(status: p.status),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.analytics_rounded, size: 18, color: AppColors.primaryLight),
              tooltip: 'تحليل تكاليف المشروع',
              onPressed: () => widget.onNavigate('project_detail', projectId: p.id),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'تعديل',
              onPressed: () => _openProjectDialog(p),
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
                      hintText: 'بحث بكود أو اسم المشروع أو العميل...',
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
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'الحالة', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                      DropdownMenuItem(value: 'active', child: Text('المشروعات الجارية')),
                      DropdownMenuItem(value: 'planning', child: Text('قيد التخطيط')),
                      DropdownMenuItem(value: 'completed', child: Text('المنتهية')),
                    ],
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _openProjectDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة مشروع جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Projects Table
          Expanded(
            child: accounting.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد مشروعات مطابقة لمعايير البحث.',
                  ),
          ),
        ],
      ),
    );
  }
}
