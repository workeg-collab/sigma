import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/journal_entry.dart';
import '../../../domain/models/journal_line.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/auth_provider.dart';

class QuickEntryDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const QuickEntryDialog({super.key, required this.onSuccess});

  @override
  State<QuickEntryDialog> createState() => _QuickEntryDialogState();
}

class _QuickEntryDialogState extends State<QuickEntryDialog> {
  String _operationType = 'cash_payment';
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedProjectId;
  int? _selectedContractorId;
  int? _selectedSupplierId;
  int? _selectedCustomerId;
  int? _selectedAnalyticalId;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      _showError('يرجى إدخال مبلغ صحيح أكبر من الصفر.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('يرجى إدخال وصف وبيان المعاملة.');
      return;
    }

    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    final journal = Provider.of<JournalProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Fetch default standard accounts
    final cashAcc = accounting.accounts.firstWhere((a) => a.code == '1101');
    final bankAcc = accounting.accounts.firstWhere((a) => a.code == '1102');
    final materialAcc = accounting.accounts.firstWhere((a) => a.code == '5101');
    final contractorAcc = accounting.accounts.firstWhere((a) => a.code == '2102');
    final supplierAcc = accounting.accounts.firstWhere((a) => a.code == '2101');
    final customerAcc = accounting.accounts.firstWhere((a) => a.code == '1103');
    final generalExpAcc = accounting.accounts.firstWhere((a) => a.code == '5201');
    final siteExpAcc = accounting.accounts.firstWhere((a) => a.code == '5104');

    List<JournalLine> lines = [];
    final desc = _descriptionController.text.trim();

    switch (_operationType) {
      case 'cash_payment': // صرف نقدي لمصروف موقع
        lines = [
          JournalLine(
            accountId: siteExpAcc.id!,
            projectId: _selectedProjectId,
            analyticalItemId: _selectedAnalyticalId,
            debit: amount,
            credit: 0.0,
            description: desc,
          ),
          JournalLine(
            accountId: cashAcc.id!,
            debit: 0.0,
            credit: amount,
            description: 'صرف من الخزينة: $desc',
          ),
        ];
        break;

      case 'bank_payment': // صرف بنكي
        lines = [
          JournalLine(
            accountId: siteExpAcc.id!,
            projectId: _selectedProjectId,
            analyticalItemId: _selectedAnalyticalId,
            debit: amount,
            credit: 0.0,
            description: desc,
          ),
          JournalLine(
            accountId: bankAcc.id!,
            debit: 0.0,
            credit: amount,
            description: 'صرف من البنك: $desc',
          ),
        ];
        break;

      case 'contractor_payment': // سداد لمقاول باطن
        if (_selectedContractorId == null) {
          _showError('يجب اختيار المقاول.');
          return;
        }
        lines = [
          JournalLine(
            accountId: contractorAcc.id!,
            projectId: _selectedProjectId,
            contractorId: _selectedContractorId,
            debit: amount,
            credit: 0.0,
            description: 'سداد دفعة للمقاول: $desc',
          ),
          JournalLine(
            accountId: cashAcc.id!,
            debit: 0.0,
            credit: amount,
            description: 'صرف خزينة للمقاول',
          ),
        ];
        break;

      case 'supplier_payment': // سداد لمورد
        if (_selectedSupplierId == null) {
          _showError('يجب اختيار المورد.');
          return;
        }
        lines = [
          JournalLine(
            accountId: supplierAcc.id!,
            supplierId: _selectedSupplierId,
            debit: amount,
            credit: 0.0,
            description: 'سداد دفعة للمورد: $desc',
          ),
          JournalLine(
            accountId: bankAcc.id!,
            debit: 0.0,
            credit: amount,
            description: 'تحويل بنكي للمورد',
          ),
        ];
        break;

      case 'customer_receipt': // تحصيل من عميل
        if (_selectedCustomerId == null) {
          _showError('يجب اختيار العميل.');
          return;
        }
        lines = [
          JournalLine(
            accountId: bankAcc.id!,
            debit: amount,
            credit: 0.0,
            description: 'إيداع بنكي من عميل: $desc',
          ),
          JournalLine(
            accountId: customerAcc.id!,
            projectId: _selectedProjectId,
            customerId: _selectedCustomerId,
            debit: 0.0,
            credit: amount,
            description: 'تحصيل مستحقات عميل: $desc',
          ),
        ];
        break;

      case 'material_purchase': // مشتريات مواد على الحساب
        lines = [
          JournalLine(
            accountId: materialAcc.id!,
            projectId: _selectedProjectId,
            analyticalItemId: _selectedAnalyticalId,
            debit: amount,
            credit: 0.0,
            description: desc,
          ),
          JournalLine(
            accountId: supplierAcc.id!,
            supplierId: _selectedSupplierId,
            debit: 0.0,
            credit: amount,
            description: 'فاتورة توريد مواد: $desc',
          ),
        ];
        break;

      case 'transfer': // تحويل بين الخزينة والبنك (سحب بنكي لتغذية الخزينة)
        lines = [
          JournalLine(
            accountId: cashAcc.id!,
            debit: amount,
            credit: 0.0,
            description: 'تغذية الخزينة من البنك',
          ),
          JournalLine(
            accountId: bankAcc.id!,
            debit: 0.0,
            credit: amount,
            description: 'سحب شيك لتغذية الخزينة',
          ),
        ];
        break;

      default:
        lines = [
          JournalLine(accountId: generalExpAcc.id!, debit: amount, credit: 0.0, description: desc),
          JournalLine(accountId: cashAcc.id!, debit: 0.0, credit: amount, description: desc),
        ];
    }

    setState(() => _isSaving = true);
    try {
      final nextNumber = await journal.getNextEntryNumber();
      final entry = JournalEntry(
        entryNumber: nextNumber,
        date: DateTime.now().toIso8601String().substring(0, 10),
        description: desc,
        projectId: _selectedProjectId,
        status: JournalStatus.posted,
        postedBy: auth.currentUser?.username ?? 'admin',
        postedAt: DateTime.now().toIso8601String(),
        lines: lines,
      );

      await journal.createJournalEntry(entry);
      await accounting.loadInitialData();

      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'إدخال سريع للمعاملات المالية',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Operation Type Selector
            DropdownButtonFormField<String>(
              value: _operationType,
              decoration: const InputDecoration(labelText: 'نوع العملية المالية', isDense: true),
              items: const [
                DropdownMenuItem(value: 'cash_payment', child: Text('صرف نقدي من الخزينة لمصروف')),
                DropdownMenuItem(value: 'bank_payment', child: Text('صرف بنكي لمصروفات')),
                DropdownMenuItem(value: 'contractor_payment', child: Text('سداد دفعة لمقاول باطن')),
                DropdownMenuItem(value: 'material_purchase', child: Text('شراء وتوريد مواد للمشروع')),
                DropdownMenuItem(value: 'supplier_payment', child: Text('سداد مستحقات مورد')),
                DropdownMenuItem(value: 'customer_receipt', child: Text('تحصيل مستخلص أو دفعة من عميل')),
                DropdownMenuItem(value: 'transfer', child: Text('تحويل بنكي / تغذية الخزينة')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _operationType = val);
              },
            ),
            const SizedBox(height: 12),

            // Amount Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.end,
              decoration: const InputDecoration(
                labelText: 'المبلغ الإجمالي (ج.م) *',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'البيان وشرح المعاملة *',
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // Project Selector
            DropdownButtonFormField<int?>(
              value: _selectedProjectId,
              decoration: const InputDecoration(labelText: 'المشروع التابع', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون مشروع')),
                ...accounting.projects.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedProjectId = val),
            ),
            const SizedBox(height: 12),

            // Contractor Dropdown (if contractor payment)
            if (_operationType == 'contractor_payment') ...[
              DropdownButtonFormField<int?>(
                value: _selectedContractorId,
                decoration: const InputDecoration(labelText: 'المقاول المستفيد *', isDense: true),
                items: accounting.contractors.map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                onChanged: (val) => setState(() => _selectedContractorId = val),
              ),
              const SizedBox(height: 12),
            ],

            // Supplier Dropdown (if supplier payment or purchase)
            if (_operationType == 'supplier_payment' || _operationType == 'material_purchase') ...[
              DropdownButtonFormField<int?>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(labelText: 'المورد *', isDense: true),
                items: accounting.suppliers.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    )).toList(),
                onChanged: (val) => setState(() => _selectedSupplierId = val),
              ),
              const SizedBox(height: 12),
            ],

            // Customer Dropdown (if customer receipt)
            if (_operationType == 'customer_receipt') ...[
              DropdownButtonFormField<int?>(
                value: _selectedCustomerId,
                decoration: const InputDecoration(labelText: 'العميل المسدد *', isDense: true),
                items: accounting.customers.map((cu) => DropdownMenuItem(
                      value: cu.id,
                      child: Text(cu.name),
                    )).toList(),
                onChanged: (val) => setState(() => _selectedCustomerId = val),
              ),
              const SizedBox(height: 12),
            ],

            // Analytical Item Dropdown
            DropdownButtonFormField<int?>(
              value: _selectedAnalyticalId,
              decoration: const InputDecoration(labelText: 'التوجيه التحليلي (اختياري)', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('بدون توجيه')),
                ...accounting.analyticalItems.map((an) => DropdownMenuItem(
                      value: an.id,
                      child: Text(an.name),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedAnalyticalId = val),
            ),
            const SizedBox(height: 20),

            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: _isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('إنشاء وترحيل المعاملة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
