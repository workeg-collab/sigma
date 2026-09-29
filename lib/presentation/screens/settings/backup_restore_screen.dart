import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/services/audit_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accounting_provider.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  late BackupService _backupService;
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final audit = AuditService(authService: auth);
    _backupService = BackupService(auditService: audit);
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _backupService.getDatabaseStats();
    setState(() => _stats = stats);
  }

  Future<void> _handleBackup() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final dest = '${docDir.path}/sigma_backup_$timestamp.db';

      await _backupService.createBackup(dest);
      await _loadStats();

      setState(() {
        _statusMessage = 'تم إنشاء النسخة الاحتياطية بنجاح على المسار:\n$dest';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ أثناء إنشاء النسخة الاحتياطية: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    final files = await FilePicker.pickFiles(
      dialogTitle: 'اختر ملف قاعدة البيانات لاستعادته',
      type: FileType.custom,
      allowedExtensions: ['db', 'sqlite'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final path = files.first.path!;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تأكيد استعادة قاعدة البيانات'),
          content: const Text('تحذير: استعادة قاعدة البيانات ستستبدل البيانات الحالية بالكامل ببيانات ملف النسخة الاحتياطية. هل أنت متأكد من الاستمرار؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('تأكيد الاستبدال والاستعادة'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        setState(() {
          _isLoading = true;
          _statusMessage = null;
        });

        try {
          await _backupService.restoreBackup(path);
          await Provider.of<AccountingProvider>(context, listen: false).loadInitialData();
          await _loadStats();

          setState(() {
            _statusMessage = 'تمت استعادة قاعدة البيانات وفحص سلامتها بنجاح!';
          });
        } catch (e) {
          setState(() {
            _statusMessage = 'خطأ أثناء الاستعادة: $e';
          });
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('النسخ الاحتياطي واستعادة البيانات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'حفظ نسخ احتياطية دورية لقاعدة البيانات يضمن سلامة واستمرارية أعمالك المحاسبية.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Database Stats Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('حالة قاعدة البيانات الحالية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _statRow('مسار قاعدة البيانات النشطة:', _stats['path']?.toString() ?? '-'),
                const SizedBox(height: 8),
                _statRow('حجم قاعدة البيانات الفعلي:', _stats['sizeFormatted']?.toString() ?? '0 KB'),
                const SizedBox(height: 8),
                _statRow('تاريخ آخر تحديث / فحص:', _stats['lastModified']?.toString().substring(0, 19).replaceAll('T', ' ') ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Cards
          Row(
            children: [
              // Backup Card
              Expanded(
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.cloud_upload_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text('إنشاء نسخة احتياطية فورية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'يتم حفظ نسخة مطابقة تماماً من قاعدة البيانات وحفظها في مجلد المستندات مع تسجيل العملية في سجل التدقيق.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleBackup,
                        icon: const Icon(Icons.backup_rounded, size: 18),
                        label: const Text('أخذ نسخة احتياطية الآن'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Restore Card
              Expanded(
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.danger.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.danger, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text('استعادة من نسخة احتياطية', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'حدد ملف النسخة الاحتياطية (.db) لاستعادة كافة الحسابات والقيود والتقارير وفحص سلامة التناسق.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleRestore,
                        icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.danger),
                        label: const Text('اختيار ملف والاستعادة', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _statusMessage!.contains('خطأ') ? AppColors.dangerLight : AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _statusMessage!.contains('خطأ') ? AppColors.danger : AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 180, child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)))),
      ],
    );
  }
}
