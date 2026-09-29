import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/export_service.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({super.key});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  final _importService = ImportService();
  String? _selectedFilePath;
  ImportValidationReport? _report;
  bool _isAnalyzing = false;
  bool _isImporting = false;
  String? _resultMessage;

  Future<void> _pickAndAnalyzeFile() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'اختر ملف إكسيل المحاسبي للاستيراد',
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final path = files.first.path!;
      setState(() {
        _selectedFilePath = path;
        _isAnalyzing = true;
        _resultMessage = null;
        _report = null;
      });

      try {
        final rep = await _importService.validateExcelFile(path);
        setState(() => _report = rep);
      } catch (e) {
        setState(() => _resultMessage = 'خطأ أثناء قراءة ملف الإكسيل: $e');
      } finally {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _commitImport() async {
    if (_selectedFilePath == null) return;

    setState(() => _isImporting = true);
    try {
      final count = await _importService.commitImport(_selectedFilePath!);
      await Provider.of<AccountingProvider>(context, listen: false).loadInitialData();
      setState(() {
        _resultMessage = 'تم استيراد $count سجلاً بنجاح وتحديث دليل الحسابات والمشروعات!';
        _report = null;
        _selectedFilePath = null;
      });
    } catch (e) {
      setState(() => _resultMessage = 'خطأ أثناء حفظ البيانات المستوردة: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  Future<void> _exportAccountsToExcel() async {
    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    final docDir = await getApplicationDocumentsDirectory();
    final path = '${docDir.path}/chart_of_accounts_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final headers = ['كود الحساب', 'اسم الحساب', 'النوع', 'طبيعة الحساب', 'الرصيد الحالي'];
    final rows = accounting.accounts.map((a) => [
      a.code,
      a.nameAr,
      a.accountType,
      a.normalBalance,
      a.currentBalance,
    ]).toList();

    await ExportService.exportToExcel(
      filePath: path,
      sheetName: 'دليل الحسابات',
      headers: headers,
      rows: rows,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تصدير دليل الحسابات بنجاح إلى:\n$path'), backgroundColor: AppColors.success),
    );
  }

  Future<void> _exportProjectsToExcel() async {
    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    final docDir = await getApplicationDocumentsDirectory();
    final path = '${docDir.path}/project_costs_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final headers = ['كود المشروع', 'اسم المشروع', 'العميل', 'الموازنة', 'التكاليف الفعلية', 'الإيرادات', 'مجمل الربح', 'هامش الربح %'];
    final rows = accounting.projects.map((p) => [
      p.code,
      p.name,
      p.client ?? '',
      p.budget,
      p.totalCost,
      p.totalRevenue,
      p.grossProfit,
      p.profitMargin,
    ]).toList();

    await ExportService.exportToExcel(
      filePath: path,
      sheetName: 'تكاليف المشروعات',
      headers: headers,
      rows: rows,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تصدير تكاليف المشروعات بنجاح إلى:\n$path'), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final reportColumns = [
      FinancialTableColumn(title: 'نوع السجل', width: 140),
      FinancialTableColumn(title: 'الكود / المعرف', width: 120),
      FinancialTableColumn(title: 'البيان', width: 220),
      FinancialTableColumn(title: 'الحالة', width: 100),
      FinancialTableColumn(title: 'تقرير الفحص والتحقق', width: 320),
    ];

    final reportRows = (_report?.items ?? []).map((i) {
      return [
        Text(i.entityType),
        Text(i.codeOrNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(i.title),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: i.status == 'Valid'
                ? AppColors.successLight
                : (i.status == 'Warning' ? AppColors.warningLight : AppColors.dangerLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            i.status == 'Valid' ? 'صالح' : (i.status == 'Warning' ? 'تنبيه' : 'خطأ'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: i.status == 'Valid'
                  ? AppColors.success
                  : (i.status == 'Warning' ? AppColors.warning : AppColors.danger),
            ),
          ),
        ),
        Text(i.message, style: const TextStyle(fontSize: 12)),
      ];
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('استيراد وتصدير بيانات ملفات الإكسيل (Excel Tools)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'أداة متخصصة لاستيراد بيانات دفاتر وملفات الإكسيل السابقة مع فحص التناسق، والتصدير المنظم لكافة التقارير.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Import Box
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.file_upload_outlined, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('معالج استيراد ملف إكسيل مع الفحص المسبق', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        Text('يفحص أوراق دليل الحسابات والمشروعات والقيود ويتأكد من عدم وجود تعارضات', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _pickAndAnalyzeFile,
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('اختيار ملف إكسيل وفحصه'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
                if (_selectedFilePath != null) ...[
                  const SizedBox(height: 12),
                  Text('الملف المحدد: $_selectedFilePath', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
                ],
                if (_isAnalyzing) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2),
                      SizedBox(width: 12),
                      Text('جاري فحص وتدقيق بنود الملف والتحقق من التناسق المحاسبي...'),
                    ],
                  ),
                ],
                if (_resultMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _resultMessage!.contains('خطأ') ? AppColors.dangerLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _resultMessage!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _resultMessage!.contains('خطأ') ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Import Validation Preview if report exists
          if (_report != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تقرير فحص الاستيراد: ${_report!.validCount} صالح | ${_report!.warningCount} تنبيهات | ${_report!.errorCount} أخطاء',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      ElevatedButton.icon(
                        onPressed: _report!.canImport && !_isImporting ? _commitImport : null,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('اعتماد واستيراد البيانات'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FinancialTable(
                    columns: reportColumns,
                    rows: reportRows,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Batch Export Section
          const Text('مركز تصدير التقارير والقوائم إلى إكسيل (Excel Export Center)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _exportButton('تصدير دليل الحسابات (.xlsx)', Icons.account_tree_rounded, _exportAccountsToExcel),
              _exportButton('تصدير تكاليف المشروعات (.xlsx)', Icons.construction_rounded, _exportProjectsToExcel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportButton(String title, IconData icon, VoidCallback onTap) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0D9488).withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('تصدير الملف الآن'),
          ),
        ],
      ),
    );
  }
}
