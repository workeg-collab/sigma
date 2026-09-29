import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../domain/models/audit_log.dart';
import '../../widgets/financial_table.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _auditRepo = AuditRepository();
  List<AuditLog> _logs = [];
  bool _isLoading = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await _auditRepo.getLogs(search: _searchController.text.trim());
    setState(() {
      _logs = logs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final columns = [
      FinancialTableColumn(title: 'وقت وتاريخ الإجراء', width: 170),
      FinancialTableColumn(title: 'اسم المستخدم', width: 130),
      FinancialTableColumn(title: 'نوع الإجراء', width: 150),
      FinancialTableColumn(title: 'السجل المعني', width: 120),
      FinancialTableColumn(title: 'معرف السجل', width: 110),
      FinancialTableColumn(title: 'تفاصيل العملية والتغييرات', width: 340),
    ];

    final rows = _logs.map((l) {
      return [
        Text(l.createdAt.substring(0, 19).replaceAll('T', ' ')),
        Text(l.username, style: const TextStyle(fontWeight: FontWeight.w700)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(4)),
          child: Text(l.action, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
        ),
        Text(l.recordType),
        Text(l.recordId ?? '-'),
        Text(l.details ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis),
      ];
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'بحث في سجل التدقيق باسم المستخدم أو التفاصيل...',
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _loadLogs(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadLogs,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('تحديث السجل'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FinancialTable(
                    columns: columns,
                    rows: rows,
                    emptyMessage: 'لا توجد حركات تدقيق مسجلة.',
                  ),
          ),
        ],
      ),
    );
  }
}
