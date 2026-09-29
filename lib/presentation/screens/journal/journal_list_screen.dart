import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';
import '../../widgets/status_badge.dart';

class JournalListScreen extends StatefulWidget {
  final Function(String route, {int? entryId}) onNavigate;

  const JournalListScreen({super.key, required this.onNavigate});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus = 'all';
  int? _selectedProject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JournalProvider>(context, listen: false).loadEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    Provider.of<JournalProvider>(context, listen: false).setFilters(
      status: _selectedStatus,
      project: _selectedProject,
      search: _searchController.text.trim(),
    );
  }

  void _resetFilter() {
    _searchController.clear();
    setState(() {
      _selectedStatus = 'all';
      _selectedProject = null;
    });
    Provider.of<JournalProvider>(context, listen: false).resetFilters();
  }

  Future<void> _handlePost(int entryId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.hasPermission(AppPermissions.postJournal)) {
      _showSnackbar('عذراً، ليس لديك صلاحية ترحيل القيود.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد ترحيل القيد'),
        content: const Text('هل أنت متأكد من رغبتك في ترحيل هذا القيد؟ بعد الترحيل لا يمكن تعديل القيد وسيدخل في حسابات القوائم المالية.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('ترحيل القيد'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<JournalProvider>(context, listen: false).postEntry(
          entryId,
          postedBy: auth.currentUser?.username ?? 'admin',
        );
        _showSnackbar('تم ترحيل القيد بنجاح.');
      } catch (e) {
        _showSnackbar(e.toString(), isError: true);
      }
    }
  }

  Future<void> _handleCancel(int entryId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.hasPermission(AppPermissions.cancelJournal)) {
      _showSnackbar('عذراً، ليس لديك صلاحية إلغاء القيود المرحّلة.');
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء قيد مرحّل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('سيتم استبعاد أثر القيد من الحسابات مع الاحتفاظ به في سجل العمليات.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'سبب الإلغاء (إلزامي)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<JournalProvider>(context, listen: false).cancelEntry(
          entryId,
          cancelledBy: auth.currentUser?.username ?? 'admin',
          reason: reasonController.text.trim(),
        );
        _showSnackbar('تم إلغاء القيد بنجاح.');
      } catch (e) {
        _showSnackbar(e.toString(), isError: true);
      }
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final journal = Provider.of<JournalProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final columns = [
      FinancialTableColumn(title: 'رقم القيد', width: 110),
      FinancialTableColumn(title: 'التاريخ', width: 100),
      FinancialTableColumn(title: 'البيان والشرح', width: 260),
      FinancialTableColumn(title: 'المشروع', width: 160),
      FinancialTableColumn(title: 'إجمالي المدين', width: 120, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'إجمالي الدائن', width: 120, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الحالة', width: 90),
      FinancialTableColumn(title: 'الإجراءات', width: 150),
    ];

    final rows = journal.entries.map((e) {
      return [
        Text(e.entryNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(e.date),
        Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(e.projectName ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(
          Formatters.formatCurrency(e.totalDebit),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.debit),
        ),
        Text(
          Formatters.formatCurrency(e.totalCredit),
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.credit),
        ),
        StatusBadge(status: e.status),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_rounded, size: 18),
              tooltip: 'عرض وتعديل',
              onPressed: () => widget.onNavigate('journal_entry', entryId: e.id),
            ),
            if (e.status == JournalStatus.draft) ...[
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.success),
                tooltip: 'ترحيل القيد',
                onPressed: () => _handlePost(e.id!),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                tooltip: 'حذف المسودة',
                onPressed: () => journal.deleteDraft(e.id!),
              ),
            ] else if (e.status == JournalStatus.posted) ...[
              IconButton(
                icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
                tooltip: 'إلغاء القيد',
                onPressed: () => _handleCancel(e.id!),
              ),
            ],
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
                // Search Input
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'بحث برقم القيد أو البيان أو المرجع...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
                const SizedBox(width: 12),

                // Status Dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'الحالة', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('جميع الحالات')),
                      DropdownMenuItem(value: JournalStatus.draft, child: Text('مسودات')),
                      DropdownMenuItem(value: JournalStatus.posted, child: Text('مرحّلة')),
                      DropdownMenuItem(value: JournalStatus.cancelled, child: Text('ملغية')),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Project Dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedProject,
                    decoration: const InputDecoration(labelText: 'المشروع', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('جميع المشروعات')),
                      ...accounting.projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedProject = val);
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Apply & Reset Buttons
                ElevatedButton(
                  onPressed: _applyFilter,
                  child: const Text('تطبيق'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _resetFilter,
                  child: const Text('إعادة تعيين'),
                ),
                const Spacer(),

                // Create Entry Button
                ElevatedButton.icon(
                  onPressed: () => widget.onNavigate('journal_entry'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('قيد جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Table of Journal Entries
          Expanded(
            child: journal.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد قيود يومية مطابقة لمعايير البحث الحالية.',
                  ),
          ),
        ],
      ),
    );
  }
}
