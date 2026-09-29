import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;

  const StatusBadge({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    String label;

    switch (status.toLowerCase()) {
      case JournalStatus.posted:
      case 'balanced':
      case 'active':
        bg = AppColors.successLight;
        text = AppColors.success;
        label = customLabel ?? (status == 'balanced' ? 'متزن' : (status == 'active' ? 'نشط' : 'مرحّل'));
        break;
      case JournalStatus.draft:
      case 'planning':
      case 'warning':
        bg = AppColors.warningLight;
        text = AppColors.warning;
        label = customLabel ?? (status == 'planning' ? 'تخطيط' : 'مسودة');
        break;
      case JournalStatus.cancelled:
      case 'out_of_balance':
      case 'error':
        bg = AppColors.dangerLight;
        text = AppColors.danger;
        label = customLabel ?? (status == 'out_of_balance' ? 'غير متزن' : 'ملغي');
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        label = customLabel ?? status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
