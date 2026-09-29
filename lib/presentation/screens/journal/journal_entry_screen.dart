import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/balance_indicator.dart';

class JournalEntryScreen extends StatefulWidget {
  final int? entryId;
  final VoidCallback onBack;

  const JournalEntryScreen({super.key, this.entryId, required this.onBack});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _entryNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final _descController = TextEditingController();
  final _refController = TextEditingController();
  int? _selectedProjectId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final journal = Provider.of<JournalProvider>(context, listen: false);
      if (widget.entryId != null) {
        await journal.loadEntryForEdit(widget.entryId!);
        if (journal.activeEntry != null) {
          _entryNumberController.text = journal.activeEntry!.entryNumber;
          _dateController.text = journal.activeEntry!.date;
          _descController.text = journal.activeEntry!.description;
          _refController.text = journal.activeEntry!.referenceNumber ?? '';
          setState(() {
            _selectedProjectId = journal.activeEntry!.projectId;
          });
        }
      } else {
        await journal.initNewEntry();
        if (journal.activeEntry != null) {
          _entryNumberController.text = journal.activeEntry!.entryNumber;
          _dateController.text = journal.activeEntry!.date;
          _descController.text = '';
          _refController.text = '';
        }
      }
    });
  }

  @override
  void dispose() {
    _entryNumberController.dispose();
    _dateController.dispose();
    _descController.dispose();
    _refController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry({bool postImmediately = false}) async {
    final journal = Provider.of<JournalProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_descController.text.trim().isEmpty) {
      _showSnackbar('يرجى إدخال شرح وبيان القيد.', isError: true);
      return;
    }

    journal.activeEntry = journal.activeEntry!.copyWith(
      entryNumber: _entryNumberController.text.trim(),
      date: _dateController.text.trim(),
      description: _descController.text.trim(),
      referenceNumber: _refController.text.trim(),
      projectId: _selectedProjectId,
    );

    setState(() => _isSaving = true);
    try {
      await journal.saveCurrentEntry(
        postImmediately: postImmediately,
        username: auth.currentUser?.username,
      );
      _showSnackbar(postImmediately ? 'تم ترحيل القيد بنجاح.' : 'تم حفظ مسودة القيد بنجاح.');
      widget.onBack();
    } catch (e) {
      _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
    final isReadOnly = journal.activeEntry?.status == JournalStatus.posted ||
        journal.activeEntry?.status == JournalStatus.cancelled;

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
                tooltip: 'العودة لقائمة القيود',
              ),
              const SizedBox(width: 8),
              Text(
                widget.entryId == null ? 'إنشاء قيد يومية جديد' : 'قيد يومية: ${_entryNumberController.text}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              if (journal.activeEntry != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: journal.activeEntry!.status == JournalStatus.posted
                        ? AppColors.successLight
                        : (journal.activeEntry!.status == JournalStatus.draft
                            ? AppColors.warningLight
                            : AppColors.dangerLight),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    JournalStatus.getLabelAr(journal.activeEntry!.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: journal.activeEntry!.status == JournalStatus.posted
                          ? AppColors.success
                          : (journal.activeEntry!.status == JournalStatus.draft
                              ? AppColors.warning
                              : AppColors.danger),
                    ),
                  ),
                ),
              const Spacer(),
              if (!isReadOnly) ...[
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _saveEntry(postImmediately: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('حفظ كمسودة'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : () => _saveEntry(postImmediately: true),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('ترحيل القيد الآن'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Header Input Fields Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Entry Number
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _entryNumberController,
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(labelText: 'رقم القيد', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),

                // Date
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dateController,
                    enabled: !isReadOnly,
                    decoration: InputDecoration(
                      labelText: 'التاريخ',
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        onPressed: isReadOnly
                            ? null
                            : () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (d != null) {
                                  _dateController.text = d.toIso8601String().substring(0, 10);
                                }
                              },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Project
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int?>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(labelText: 'المشروع العام للقيد', isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('بدون مشروع')),
                      ...accounting.projects.map((p) => DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.code} - ${p.name}', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: isReadOnly ? null : (val) => setState(() => _selectedProjectId = val),
                  ),
                ),
                const SizedBox(width: 12),

                // Reference
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _refController,
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(labelText: 'رقم المستند / المرجع', isDense: true),
                  ),
                ),
                const SizedBox(width: 12),

                // Description
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _descController,
                    enabled: !isReadOnly,
                    decoration: const InputDecoration(labelText: 'بيان وشرح القيد الرئيسي', isDense: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lines Grid Header & Add Line Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'أسطر القيد المحاسبي (${journal.activeLines.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              if (!isReadOnly)
                ElevatedButton.icon(
                  onPressed: () => journal.addLine(projectId: _selectedProjectId),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('إضافة سطر'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Lines List View
          Expanded(
            child: ListView.builder(
              itemCount: journal.activeLines.length,
              itemBuilder: (context, index) {
                final line = journal.activeLines[index];
                final errors = journal.lineValidationErrors[index] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: errors.isNotEmpty
                          ? AppColors.danger
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: errors.isNotEmpty ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Line Number
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Account Selector
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: line.accountId > 0 ? line.accountId : null,
                              decoration: const InputDecoration(labelText: 'الحساب المالي *', isDense: true),
                              items: accounting.accounts.map((a) {
                                return DropdownMenuItem(
                                  value: a.id,
                                  child: Text('${a.code} - ${a.nameAr}', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: isReadOnly
                                  ? null
                                  : (val) {
                                      if (val != null) {
                                        journal.updateLine(index, line.copyWith(accountId: val));
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Project
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: line.projectId,
                              decoration: const InputDecoration(labelText: 'المشروع', isDense: true),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('بدون مشروع')),
                                ...accounting.projects.map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.name, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: isReadOnly
                                  ? null
                                  : (val) {
                                      journal.updateLine(index, line.copyWith(projectId: val));
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Analytical Item
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: line.analyticalItemId,
                              decoration: const InputDecoration(labelText: 'التوجيه التحليلي', isDense: true),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('بدون توجيه')),
                                ...accounting.analyticalItems.map((an) => DropdownMenuItem(
                                      value: an.id,
                                      child: Text(an.name, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: isReadOnly
                                  ? null
                                  : (val) {
                                      journal.updateLine(index, line.copyWith(analyticalItemId: val));
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Contractor / Party
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<int?>(
                              value: line.contractorId,
                              decoration: const InputDecoration(labelText: 'المقاول', isDense: true),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('بدون مقاول')),
                                ...accounting.contractors.map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: isReadOnly
                                  ? null
                                  : (val) {
                                      journal.updateLine(index, line.copyWith(contractorId: val));
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Debit
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: line.debit > 0 ? line.debit.toString() : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                labelText: 'مدين',
                                isDense: true,
                                labelStyle: TextStyle(color: AppColors.debit, fontWeight: FontWeight.bold),
                              ),
                              onChanged: (val) {
                                final d = double.tryParse(val) ?? 0.0;
                                journal.updateLine(index, line.copyWith(debit: d, credit: d > 0 ? 0.0 : line.credit));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Credit
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: line.credit > 0 ? line.credit.toString() : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.end,
                              decoration: const InputDecoration(
                                labelText: 'دائن',
                                isDense: true,
                                labelStyle: TextStyle(color: AppColors.credit, fontWeight: FontWeight.bold),
                              ),
                              onChanged: (val) {
                                final c = double.tryParse(val) ?? 0.0;
                                journal.updateLine(index, line.copyWith(credit: c, debit: c > 0 ? 0.0 : line.debit));
                              },
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Line Actions
                          if (!isReadOnly) ...[
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16),
                              tooltip: 'تكرار السطر',
                              onPressed: () => journal.duplicateLine(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                              tooltip: 'حذف السطر',
                              onPressed: () => journal.removeLine(index),
                            ),
                          ],
                        ],
                      ),

                      // Optional Quantity & Unit Calculation Drawer
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const SizedBox(width: 32),
                          // Unit
                          SizedBox(
                            width: 110,
                            child: DropdownButtonFormField<int?>(
                              value: line.unitId,
                              decoration: const InputDecoration(labelText: 'الوحدة', isDense: true),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('الوحدة')),
                                ...accounting.units.map((u) => DropdownMenuItem(
                                      value: u.id,
                                      child: Text(u.name, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: isReadOnly
                                  ? null
                                  : (val) {
                                      journal.updateLine(index, line.copyWith(unitId: val));
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Quantity
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              initialValue: line.quantity > 0 ? line.quantity.toString() : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'الكمية', isDense: true),
                              onChanged: (val) {
                                final qty = double.tryParse(val) ?? 0.0;
                                final amt = qty * line.unitPrice;
                                journal.updateLine(
                                  index,
                                  line.copyWith(
                                    quantity: qty,
                                    debit: (line.debit > 0 || (line.debit == 0 && line.credit == 0)) ? amt : 0.0,
                                    credit: line.credit > 0 ? amt : 0.0,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Unit Price
                          SizedBox(
                            width: 110,
                            child: TextFormField(
                              initialValue: line.unitPrice > 0 ? line.unitPrice.toString() : '',
                              enabled: !isReadOnly,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'سعر الوحدة', isDense: true),
                              onChanged: (val) {
                                final price = double.tryParse(val) ?? 0.0;
                                final amt = line.quantity * price;
                                journal.updateLine(
                                  index,
                                  line.copyWith(
                                    unitPrice: price,
                                    debit: (line.debit > 0 || (line.debit == 0 && line.credit == 0)) ? amt : 0.0,
                                    credit: line.credit > 0 ? amt : 0.0,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Line Note / Reference
                          Expanded(
                            child: TextFormField(
                              initialValue: line.description ?? '',
                              enabled: !isReadOnly,
                              decoration: const InputDecoration(labelText: 'ملاحظة تفصيلية للسطر', isDense: true),
                              onChanged: (val) {
                                journal.updateLine(index, line.copyWith(description: val));
                              },
                            ),
                          ),
                        ],
                      ),

                      // Errors banner if any
                      if (errors.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(right: 32),
                          child: Text(
                            errors.join(' • '),
                            style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Real-Time Balance Indicator Footer
          BalanceIndicator(
            totalDebit: journal.currentTotalDebit,
            totalCredit: journal.currentTotalCredit,
            difference: journal.currentDifference,
            isBalanced: journal.isCurrentBalanced,
          ),
        ],
      ),
    );
  }
}
