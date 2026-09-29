import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class BalanceIndicator extends StatelessWidget {
  final double totalDebit;
  final double totalCredit;
  final double difference;
  final bool isBalanced;

  const BalanceIndicator({
    super.key,
    required this.totalDebit,
    required this.totalCredit,
    required this.difference,
    required this.isBalanced,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isBalanced ? AppColors.successLight.withAlpha(100) : AppColors.dangerLight.withAlpha(150),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBalanced ? AppColors.success.withAlpha(100) : AppColors.danger.withAlpha(100),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: isBalanced ? AppColors.success : AppColors.danger,
            size: 26,
          ),
          const SizedBox(width: 12),
          Text(
            isBalanced ? 'القيد متزن محاسبياً' : 'القيد غير متزن!',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isBalanced ? AppColors.success : AppColors.danger,
            ),
          ),
          const Spacer(),
          _metricColumn('إجمالي المدين', totalDebit, AppColors.debit),
          const SizedBox(width: 24),
          _metricColumn('إجمالي الدائن', totalCredit, AppColors.credit),
          const SizedBox(width: 24),
          _metricColumn('الفرق', difference, isBalanced ? AppColors.textSecondaryLight : AppColors.danger),
        ],
      ),
    );
  }

  Widget _metricColumn(String title, double amount, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 2),
        Text(
          Formatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
