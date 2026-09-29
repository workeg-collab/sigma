import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/accounting_provider.dart';
import '../../providers/auth_provider.dart';

class FiscalYearsScreen extends StatelessWidget {
  const FiscalYearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accounting = Provider.of<AccountingProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fy = accounting.activeFiscalYear;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إدارة السنوات والفترات المالية الشهرية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'إغلاق الفترة المحاسبية يمنع ترحيل أي قيود جديدة أو تعديل القيود السابقة في تلك الفترة.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // Fiscal Year Active Card
          if (fy != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fy.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('من: ${fy.startDate}  إلى: ${fy.endDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: fy.isClosed ? AppColors.dangerLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      fy.isClosed ? 'سنة مغلقة' : 'سنة مالية نشطة',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: fy.isClosed ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Monthly Periods Grid
          const Text('الفترات المحاسبية الشهرية (12 شهراً)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: accounting.periods.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 110,
                    ),
                    itemCount: accounting.periods.length,
                    itemBuilder: (context, index) {
                      final p = accounting.periods[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: p.isClosed
                                ? AppColors.danger.withAlpha(50)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  '${p.startDate} ~ ${p.endDate}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.isClosed ? 'مغلقة' : 'مفتوحة للترحيل',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: p.isClosed ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: !p.isClosed,
                              activeColor: AppColors.success,
                              onChanged: (open) {
                                accounting.togglePeriodClosed(
                                  p.id!,
                                  !open,
                                  username: auth.currentUser?.username,
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
