import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../providers/accounting_provider.dart';
import '../providers/theme_provider.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onNewJournal;
  final VoidCallback? onQuickEntry;

  const AppTopBar({
    super.key,
    required this.title,
    this.onNewJournal,
    this.onQuickEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accounting = Provider.of<AccountingProvider>(context);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Page Title
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 16),

          // Active Fiscal Year Badge
          if (accounting.activeFiscalYear != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withAlpha(40)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    accounting.activeFiscalYear!.name,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Quick Action 1: Quick Entry
          if (onQuickEntry != null)
            OutlinedButton.icon(
              onPressed: onQuickEntry,
              icon: const Icon(Icons.flash_on_rounded, size: 16, color: AppColors.secondary),
              label: const Text('إدخال سريع', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.secondary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          const SizedBox(width: 10),

          // Quick Action 2: New Journal Entry
          if (onNewJournal != null)
            ElevatedButton.icon(
              onPressed: onNewJournal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('قيد يومية جديد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          const SizedBox(width: 12),

          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : const Color(0xFF64748B),
            ),
            tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
            onPressed: () => themeProvider.toggleTheme(),
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'تحديث البيانات',
            onPressed: () => accounting.loadInitialData(),
          ),
        ],
      ),
    );
  }
}
