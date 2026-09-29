import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/opening_balance.dart';
import '../../../data/repositories/opening_balance_repository.dart';
import '../../providers/accounting_provider.dart';
import '../../widgets/balance_indicator.dart';

class OpeningBalancesScreen extends StatefulWidget {
  const OpeningBalancesScreen({super.key});

  @override
  State<OpeningBalancesScreen> createState() => _OpeningBalancesScreenState();
}

class _OpeningBalancesScreenState extends State<OpeningBalancesScreen> {
  final _repo = OpeningBalanceRepository();
  List<OpeningBalance> _items = [];
  bool _isLoading = false;
  bool _isSaving = false;

  double get _totalDebit => _items.fold(0.0, (sum, i) => sum + i.debit);
  double get _totalCredit => _items.fold(0.0, (sum, i) => sum + i.credit);
  double get _difference => (_totalDebit - _totalCredit).abs();
  bool get _isBalanced => _difference < 0.001;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    if (accounting.activeFiscalYear == null) return;

    setState(() => _isLoading = true);
    final saved = await _repo.getOpeningBalances(accounting.activeFiscalYear!.id!);

    Map<int, OpeningBalance> existingMap = {for (var o in saved) o.accountId: o};

    List<OpeningBalance> list = [];
    for (var acc in accounting.accounts) {
      if (existingMap.containsKey(acc.id)) {
        list.add(existingMap[acc.id]!);
      } else {
        list.add(OpeningBalance(
          fiscalYearId: accounting.activeFiscalYear!.id!,
          accountId: acc.id!,
          accountCode: acc.code,
          accountNameAr: acc.nameAr,
          debit: 0.0,
          credit: 0.0,
        ));
      }
    }

    setState(() {
      _items = list;
      _isLoading = false;
    });
  }

  Future<void> _saveOpeningBalances() async {
    final accounting = Provider.of<AccountingProvider>(context, listen: false);
    if (!_isBalanced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الأرصدة الافتتاحية غير متزنة! الفرق: ${Formatters.formatCurrency(_difference)} ج.م'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _repo.saveOpeningBalances(accounting.activeFiscalYear!.id!, _items);
      await accounting.loadAccounts();
      await accounting.loadDashboardMetrics();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ وتحديث الأرصدة الافتتاحية بنجاح.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الأرصدة الافتتاحية لدليل الحسابات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(
                    'السنة المالية: ${accounting.activeFiscalYear?.name ?? "-"} | شرط التوازن: إجمالي المدين = إجمالي الدائن',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveOpeningBalances,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: const Text('حفظ الأرصدة الافتتاحية'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(item.accountCode ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(item.accountNameAr ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 150,
                                child: TextFormField(
                                  initialValue: item.debit > 0 ? item.debit.toString() : '',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.end,
                                  decoration: const InputDecoration(labelText: 'مدين افتتاحي', isDense: true),
                                  onChanged: (val) {
                                    final d = double.tryParse(val) ?? 0.0;
                                    setState(() {
                                      _items[index] = OpeningBalance(
                                        id: item.id,
                                        fiscalYearId: item.fiscalYearId,
                                        accountId: item.accountId,
                                        accountCode: item.accountCode,
                                        accountNameAr: item.accountNameAr,
                                        debit: d,
                                        credit: d > 0 ? 0.0 : item.credit,
                                      );
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 150,
                                child: TextFormField(
                                  initialValue: item.credit > 0 ? item.credit.toString() : '',
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.end,
                                  decoration: const InputDecoration(labelText: 'دائن افتتاحي', isDense: true),
                                  onChanged: (val) {
                                    final c = double.tryParse(val) ?? 0.0;
                                    setState(() {
                                      _items[index] = OpeningBalance(
                                        id: item.id,
                                        fiscalYearId: item.fiscalYearId,
                                        accountId: item.accountId,
                                        accountCode: item.accountCode,
                                        accountNameAr: item.accountNameAr,
                                        debit: c > 0 ? 0.0 : item.debit,
                                        credit: c,
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // Balance Indicator
          BalanceIndicator(
            totalDebit: _totalDebit,
            totalCredit: _totalCredit,
            difference: _difference,
            isBalanced: _isBalanced,
          ),
        ],
      ),
    );
  }
}
