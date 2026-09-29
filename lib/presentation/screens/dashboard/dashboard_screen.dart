import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/journal_provider.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String route) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AccountingProvider>(context, listen: false).loadDashboardMetrics();
      Provider.of<JournalProvider>(context, listen: false).loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final journal = Provider.of<JournalProvider>(context);
    final metrics = accounting.dashboardMetrics;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final rev = (metrics['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final exp = (metrics['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final net = (metrics['netProfit'] as num?)?.toDouble() ?? 0.0;
    final cash = (metrics['cashBalance'] as num?)?.toDouble() ?? 0.0;
    final bank = (metrics['bankBalance'] as num?)?.toDouble() ?? 0.0;
    final liquidity = (metrics['totalLiquidity'] as num?)?.toDouble() ?? 0.0;
    final receivables = (metrics['receivables'] as num?)?.toDouble() ?? 0.0;
    final payables = (metrics['payables'] as num?)?.toDouble() ?? 0.0;
    final contractors = (metrics['contractorBalance'] as num?)?.toDouble() ?? 0.0;
    final isBalanced = metrics['isBalanceSheetBalanced'] as bool? ?? true;
    final draftCount = metrics['draftEntriesCount'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Accounting Alerts Bar
          if (!isBalanced) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تنبيه محاسبي: الميزانية العمومية غير متزنة!',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.danger, fontSize: 14),
                        ),
                        Text(
                          'إجمالي الأصول لا يساوي إجمالي الخصوم وحقوق الملكية. يرجى مراجعة ميزان المراجعة والقيود.',
                          style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => widget.onNavigate('trial_balance'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('فحص ميزان المراجعة'),
                  ),
                ],
              ),
            ),
          ],

          if (draftCount > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'يوجد لديك $draftCount قيود يومية غير مرحلة (مسودة)',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF78350F), fontSize: 13),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => widget.onNavigate('journal'),
                    child: const Text('مراجعة المسودات', style: TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // 2. Primary KPI Row
          const Text(
            'مؤشرات الأداء المالي والسيولة',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'إجمالي الإيرادات',
                    amount: rev,
                    subtitle: 'إيراد المبيعات والمستخلصات',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                    onTap: () => widget.onNavigate('income_statement'),
                  ),
                ),
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'إجمالي التكاليف والمصروفات',
                    amount: exp,
                    subtitle: 'تكاليف المشروعات والعمومية',
                    icon: Icons.trending_down_rounded,
                    color: AppColors.danger,
                    onTap: () => widget.onNavigate('income_statement'),
                  ),
                ),
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'صافي الربح',
                    amount: net,
                    subtitle: 'صافي أرباح الفترة الحالية',
                    icon: Icons.monetization_on_rounded,
                    color: net >= 0 ? AppColors.success : AppColors.danger,
                    onTap: () => widget.onNavigate('income_statement'),
                  ),
                ),
                SizedBox(
                  width: cardWidth > 200 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'إجمالي السيولة المتاحة',
                    amount: liquidity,
                    subtitle: 'خزينة: ${Formatters.formatCurrency(cash)} | بنك: ${Formatters.formatCurrency(bank)}',
                    icon: Icons.account_balance_rounded,
                    color: AppColors.primaryLight,
                    onTap: () => widget.onNavigate('cash_bank'),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          // 3. Secondary Metrics: Receivables, Payables, Contractors
          LayoutBuilder(builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - (2 * 16)) / 3;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth > 220 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'مستحقات العملاء (أوراق قبض ومدينون)',
                    amount: receivables,
                    subtitle: 'أرصدة العملاء المستحقة',
                    icon: Icons.assignment_ind_rounded,
                    color: Colors.indigo,
                    onTap: () => widget.onNavigate('customers'),
                  ),
                ),
                SizedBox(
                  width: cardWidth > 220 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'مستحقات الموردين (التزامات شراء)',
                    amount: payables,
                    subtitle: 'أرصدة الموردين المستحقة',
                    icon: Icons.local_shipping_rounded,
                    color: Colors.orange,
                    onTap: () => widget.onNavigate('suppliers'),
                  ),
                ),
                SizedBox(
                  width: cardWidth > 220 ? cardWidth : constraints.maxWidth,
                  child: KpiCard(
                    title: 'أرصدة المقاولين (مستخلصات مستحقة)',
                    amount: contractors,
                    subtitle: 'أرصدة مقاولي الباطن',
                    icon: Icons.engineering_rounded,
                    color: Colors.purple,
                    onTap: () => widget.onNavigate('contractors'),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 28),

          // 4. Projects Quick Overview & Recent Journals
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Projects status card
              Expanded(
                flex: 5,
                child: Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'المشروعات الجارية والتكاليف',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () => widget.onNavigate('projects'),
                            child: const Text('عرض الكل'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (accounting.projects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('لا توجد مشروعات مسجلة حالياً')),
                        )
                      else
                        ...accounting.projects.take(5).map((p) {
                          final completion = (p.budget > 0) ? (p.totalCost / p.budget).clamp(0.0, 1.0) : 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${p.code} - ${p.name}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      'التكلفة: ${Formatters.formatCurrency(p.totalCost)} / ${Formatters.formatCurrency(p.budget)}',
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: completion,
                                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  color: completion > 0.9 ? AppColors.danger : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 6,
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Recent Transactions Card
              Expanded(
                flex: 5,
                child: Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'أحدث قيود اليومية المسجلة',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          TextButton(
                            onPressed: () => widget.onNavigate('journal'),
                            child: const Text('عرض اليومية'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (journal.entries.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('لا توجد قيود مسجلة')),
                        )
                      else
                        ...journal.entries.take(5).map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${e.entryNumber} - ${e.description}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${e.date} | ${Formatters.formatCurrency(e.totalDebit)} ج.م',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: e.status),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
