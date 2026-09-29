import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/analytical_item.dart';
import '../../../domain/models/unit.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';

class AnalyticalItemsScreen extends StatefulWidget {
  const AnalyticalItemsScreen({super.key});

  @override
  State<AnalyticalItemsScreen> createState() => _AnalyticalItemsScreenState();
}

class _AnalyticalItemsScreenState extends State<AnalyticalItemsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAnalyticalDialog([AnalyticalItem? item]) {
    final codeController = TextEditingController(text: item?.code ?? '');
    final nameController = TextEditingController(text: item?.name ?? '');
    final categoryController = TextEditingController(text: item?.category ?? 'مواد مباشرة');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'إضافة بند توجيه تحليلي' : 'تعديل بند: ${item.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'كود البند *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم البند التحليلي *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'التصنيف (مواد، عمالة، مقاولين، معدات...) *', isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              final an = AnalyticalItem(
                id: item?.id,
                code: codeController.text.trim(),
                name: nameController.text.trim(),
                category: categoryController.text.trim(),
              );
              await Provider.of<AccountingProvider>(context, listen: false).saveAnalyticalItem(an);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _openUnitDialog([Unit? unit]) {
    final codeController = TextEditingController(text: unit?.code ?? '');
    final nameController = TextEditingController(text: unit?.name ?? '');
    final symbolController = TextEditingController(text: unit?.symbol ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(unit == null ? 'إضافة وحدة قياس' : 'تعديل وحدة: ${unit.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'كود الوحدة *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الوحدة (طن، م3، متر...) *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(labelText: 'الرمز الاختصاري', isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              final u = Unit(
                id: unit?.id,
                code: codeController.text.trim(),
                name: nameController.text.trim(),
                symbol: symbolController.text.trim(),
              );
              await Provider.of<AccountingProvider>(context, listen: false).saveUnit(u);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final analyticalColumns = [
      FinancialTableColumn(title: 'كود البند', width: 120),
      FinancialTableColumn(title: 'اسم بند التوجيه التحليلي', width: 340),
      FinancialTableColumn(title: 'التصنيف التحليلي', width: 200),
      FinancialTableColumn(title: 'الإجراءات', width: 100),
    ];

    final analyticalRows = accounting.analyticalItems.map((a) {
      return [
        Text(a.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: Colors.blueGrey.withAlpha(25), borderRadius: BorderRadius.circular(4)),
          child: Text(a.category, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'تعديل',
          onPressed: () => _openAnalyticalDialog(a),
        ),
      ];
    }).toList();

    final unitColumns = [
      FinancialTableColumn(title: 'كود الوحدة', width: 120),
      FinancialTableColumn(title: 'اسم وحدة القياس', width: 280),
      FinancialTableColumn(title: 'الرمز الاختصاري', width: 160),
      FinancialTableColumn(title: 'الإجراءات', width: 100),
    ];

    final unitRows = accounting.units.map((u) {
      return [
        Text(u.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(u.symbol ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'تعديل',
          onPressed: () => _openUnitDialog(u),
        ),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tab bar header
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: const [
                    Tab(text: 'بنود التوجيه التحليلي للمشروعات (Analytical Items)'),
                    Tab(text: 'الوحدات والمقاييس (Units of Measurement)'),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_tabController.index == 0) {
                      _openAnalyticalDialog();
                    } else {
                      _openUnitDialog();
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FinancialTable(
                  columns: analyticalColumns,
                  rows: analyticalRows,
                  emptyMessage: 'لا توجد بنود تحليلية مسجلة.',
                ),
                FinancialTable(
                  columns: unitColumns,
                  rows: unitRows,
                  emptyMessage: 'لا توجد وحدات قياس مسجلة.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
