import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/party.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSupplierDialog([Supplier? supplier]) {
    final codeController = TextEditingController(text: supplier?.code ?? '');
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final phoneController = TextEditingController(text: supplier?.phone ?? '');
    final opBalanceController = TextEditingController(
        text: supplier?.openingBalance != null && supplier!.openingBalance > 0
            ? supplier.openingBalance.toString()
            : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد جديد' : 'تعديل بيانات المورد: ${supplier.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'كود المورد *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم المورد / الشركة *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي المستحق للمورد (ج.م)', isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              final s = Supplier(
                id: supplier?.id,
                code: codeController.text.trim(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                openingBalance: double.tryParse(opBalanceController.text.trim()) ?? 0.0,
              );
              await Provider.of<AccountingProvider>(context, listen: false).saveSupplier(s);
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

    final query = _searchController.text.trim().toLowerCase();
    final filtered = accounting.suppliers.where((s) {
      if (query.isNotEmpty) {
        return s.code.toLowerCase().contains(query) || s.name.contains(query);
      }
      return true;
    }).toList();

    final columns = [
      FinancialTableColumn(title: 'كود المورد', width: 110),
      FinancialTableColumn(title: 'اسم المورد', width: 280),
      FinancialTableColumn(title: 'رقم الهاتف', width: 140),
      FinancialTableColumn(title: 'الرصيد الافتتاحي', width: 150, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الإجراءات', width: 100),
    ];

    final rows = filtered.map((s) {
      return [
        Text(s.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(s.phone ?? '-'),
        Text(Formatters.formatCurrency(s.openingBalance), textAlign: TextAlign.end),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'تعديل',
          onPressed: () => _openSupplierDialog(s),
        ),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'بحث باسم أو كود المورد...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _openSupplierDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة مورد جديد'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FinancialTable(
              columns: columns,
              rows: rows,
              emptyMessage: 'لا توجد بيانات موردين مسجلة.',
            ),
          ),
        ],
      ),
    );
  }
}
