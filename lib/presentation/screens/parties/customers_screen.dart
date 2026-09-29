import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/party.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/financial_table.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCustomerDialog([Customer? customer]) {
    final codeController = TextEditingController(text: customer?.code ?? '');
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final opBalanceController = TextEditingController(
        text: customer?.openingBalance != null && customer!.openingBalance > 0
            ? customer.openingBalance.toString()
            : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customer == null ? 'إضافة عميل جديد' : 'تعديل بيانات العميل: ${customer.name}'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'كود العميل *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم العميل / الجهة *', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'رقم الهاتف والتواصل', isDense: true),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opBalanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'الرصيد الافتتاحي المستحق على العميل (ج.م)', isDense: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim().isEmpty || nameController.text.trim().isEmpty) return;
              final c = Customer(
                id: customer?.id,
                code: codeController.text.trim(),
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                openingBalance: double.tryParse(opBalanceController.text.trim()) ?? 0.0,
              );
              await Provider.of<AccountingProvider>(context, listen: false).saveCustomer(c);
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
    final filtered = accounting.customers.where((c) {
      if (query.isNotEmpty) {
        return c.code.toLowerCase().contains(query) || c.name.contains(query);
      }
      return true;
    }).toList();

    final columns = [
      FinancialTableColumn(title: 'كود العميل', width: 110),
      FinancialTableColumn(title: 'اسم العميل / جهة الإسناد', width: 280),
      FinancialTableColumn(title: 'رقم الهاتف', width: 140),
      FinancialTableColumn(title: 'الرصيد الافتتاحي', width: 150, textAlign: TextAlign.end),
      FinancialTableColumn(title: 'الإجراءات', width: 100),
    ];

    final rows = filtered.map((c) {
      return [
        Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(c.phone ?? '-'),
        Text(Formatters.formatCurrency(c.openingBalance), textAlign: TextAlign.end),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'تعديل',
          onPressed: () => _openCustomerDialog(c),
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
                      hintText: 'بحث باسم أو كود العميل...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _openCustomerDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('إضافة عميل جديد'),
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
              emptyMessage: 'لا توجد بيانات عملاء مسجلة.',
            ),
          ),
        ],
      ),
    );
  }
}
