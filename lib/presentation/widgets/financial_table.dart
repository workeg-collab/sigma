import 'package:flutter/material.dart';

class FinancialTableColumn {
  final String title;
  final double? width;
  final TextAlign textAlign;

  FinancialTableColumn({
    required this.title,
    this.width,
    this.textAlign = TextAlign.start,
  });
}

class FinancialTable extends StatelessWidget {
  final List<FinancialTableColumn> columns;
  final List<List<Widget>> rows;
  final List<Widget>? footerRow;
  final String emptyMessage;

  const FinancialTable({
    super.key,
    required this.columns,
    required this.rows,
    this.footerRow,
    this.emptyMessage = 'لا توجد بيانات متاحة حالياً',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: columns.map((col) {
                      return SizedBox(
                        width: col.width ?? 120,
                        child: Text(
                          col.title,
                          textAlign: col.textAlign,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // Data Rows
                ...rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isEven = index % 2 == 0;
                  final rowColor = isEven
                      ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                      : (isDark ? const Color(0xFF172033) : const Color(0xFFF8FAFC));

                  return Container(
                    color: rowColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: row.asMap().entries.map((cEntry) {
                        final cIndex = cEntry.key;
                        final cell = cEntry.value;
                        final col = columns[cIndex];
                        return SizedBox(
                          width: col.width ?? 120,
                          child: cell,
                        );
                      }).toList(),
                    ),
                  );
                }),

                // Footer Row if provided
                if (footerRow != null) ...[
                  const Divider(height: 1, thickness: 1.5),
                  Container(
                    color: isDark ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: footerRow!.asMap().entries.map((cEntry) {
                        final cIndex = cEntry.key;
                        final cell = cEntry.value;
                        final col = columns[cIndex];
                        return SizedBox(
                          width: col.width ?? 120,
                          child: cell,
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
