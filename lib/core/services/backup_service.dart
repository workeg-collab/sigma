import 'dart:io';
import '../database/database_helper.dart';
import 'audit_service.dart';

class BackupService {
  final DatabaseHelper _dbHelper;
  final AuditService _auditService;

  BackupService({DatabaseHelper? dbHelper, required AuditService auditService})
      : _dbHelper = dbHelper ?? DatabaseHelper(),
        _auditService = auditService;

  Future<File> createBackup(String destinationPath) async {
    final file = await _dbHelper.backupDatabase(destinationPath);
    await _auditService.log(
      action: 'Backup Created',
      recordType: 'Database',
      details: 'تم إنشاء نسخة احتياطية على المسار: $destinationPath',
    );
    return file;
  }

  Future<bool> restoreBackup(String backupPath) async {
    final success = await _dbHelper.restoreDatabase(backupPath);
    if (success) {
      await _auditService.log(
        action: 'Database Restored',
        recordType: 'Database',
        details: 'تم استعادة قاعدة البيانات من النسخة الاحتياطية: $backupPath',
      );
    }
    return success;
  }

  Future<Map<String, dynamic>> getDatabaseStats() {
    return _dbHelper.getDatabaseInfo();
  }
}
