import 'dart:io';
import 'package:excel/excel.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/project_repository.dart';
import '../../domain/models/account.dart';
import '../../domain/models/project.dart';

class ImportPreviewItem {
  final String entityType; // Account, Project, JournalEntry
  final String codeOrNumber;
  final String title;
  final String status; // Valid, Warning, Error
  final String message;

  ImportPreviewItem({
    required this.entityType,
    required this.codeOrNumber,
    required this.title,
    required this.status,
    required this.message,
  });
}

class ImportValidationReport {
  final List<ImportPreviewItem> items;
  final int totalCount;
  final int validCount;
  final int errorCount;
  final int warningCount;

  ImportValidationReport({
    required this.items,
    required this.totalCount,
    required this.validCount,
    required this.errorCount,
    required this.warningCount,
  });

  bool get canImport => errorCount == 0 && validCount > 0;
}

class ImportService {
  final AccountRepository _accountRepo;
  final ProjectRepository _projectRepo;

  ImportService({
    AccountRepository? accountRepo,
    ProjectRepository? projectRepo,
  })  : _accountRepo = accountRepo ?? AccountRepository(),
        _projectRepo = projectRepo ?? ProjectRepository();

  /// Reads and validates Excel workbook before importing
  Future<ImportValidationReport> validateExcelFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    List<ImportPreviewItem> items = [];
    int valid = 0;
    int errors = 0;
    int warnings = 0;

    // Existing accounts & projects for duplicate and foreign key checks
    final existingAccounts = await _accountRepo.getAllAccounts();
    final existingCodes = existingAccounts.map((a) => a.code).toSet();
    final existingProjects = await _projectRepo.getAllProjects();
    final projectCodes = existingProjects.map((p) => p.code).toSet();

    for (var sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName];
      if (table == null || table.rows.isEmpty) continue;

      final normalizedSheet = sheetName.trim().toLowerCase();

      // Check if accounts sheet
      if (normalizedSheet.contains('حساب') || normalizedSheet.contains('account')) {
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final code = row[0]?.value?.toString().trim() ?? '';
          final name = (row.length > 1 && row[1] != null) ? row[1]!.value.toString().trim() : '';

          if (code.isEmpty || name.isEmpty) continue;

          if (existingCodes.contains(code)) {
            warnings++;
            items.add(ImportPreviewItem(
              entityType: 'دليل الحسابات',
              codeOrNumber: code,
              title: name,
              status: 'Warning',
              message: 'كود الحساب موجود بالفعل، سيتم تحديث بياناته أو تجاهله',
            ));
          } else {
            valid++;
            items.add(ImportPreviewItem(
              entityType: 'دليل الحسابات',
              codeOrNumber: code,
              title: name,
              status: 'Valid',
              message: 'حساب جديد صالح للاستيراد',
            ));
          }
        }
      }

      // Check if projects sheet
      if (normalizedSheet.contains('مشروع') || normalizedSheet.contains('project')) {
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final code = row[0]?.value?.toString().trim() ?? '';
          final name = (row.length > 1 && row[1] != null) ? row[1]!.value.toString().trim() : '';

          if (code.isEmpty || name.isEmpty) continue;

          if (projectCodes.contains(code)) {
            warnings++;
            items.add(ImportPreviewItem(
              entityType: 'المشروعات',
              codeOrNumber: code,
              title: name,
              status: 'Warning',
              message: 'المشروع موجود بالفعل مسبقاً',
            ));
          } else {
            valid++;
            items.add(ImportPreviewItem(
              entityType: 'المشروعات',
              codeOrNumber: code,
              title: name,
              status: 'Valid',
              message: 'مشروع جديد صالح للاستيراد',
            ));
          }
        }
      }
    }

    if (items.isEmpty) {
      errors++;
      items.add(ImportPreviewItem(
        entityType: 'عام',
        codeOrNumber: '-',
        title: 'الملف لا يحتوي على بيانات متطابقة',
        status: 'Error',
        message: 'تأكد من وجود شيتات تحتوي على "دليل الحسابات" أو "المشروعات"',
      ));
    }

    return ImportValidationReport(
      items: items,
      totalCount: items.length,
      validCount: valid,
      errorCount: errors,
      warningCount: warnings,
    );
  }

  /// Commits validated data to the database
  Future<int> commitImport(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    int importedCount = 0;

    for (var sheetName in excel.tables.keys) {
      final table = excel.tables[sheetName];
      if (table == null || table.rows.isEmpty) continue;

      final normalizedSheet = sheetName.trim().toLowerCase();

      // Accounts
      if (normalizedSheet.contains('حساب') || normalizedSheet.contains('account')) {
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final code = row[0]?.value?.toString().trim() ?? '';
          final name = (row.length > 1 && row[1] != null) ? row[1]!.value.toString().trim() : '';
          final type = (row.length > 2 && row[2] != null) ? row[2]!.value.toString().trim() : 'asset';

          if (code.isNotEmpty && name.isNotEmpty) {
            final existing = await _accountRepo.getAccountByCode(code);
            if (existing == null) {
              await _accountRepo.createAccount(Account(
                code: code,
                name: name,
                nameAr: name,
                accountType: type.toLowerCase().contains('expense') ? AccountType.expense : AccountType.asset,
                subType: AccountSubType.currentAsset,
                normalBalance: NormalBalance.debit,
              ));
              importedCount++;
            }
          }
        }
      }

      // Projects
      if (normalizedSheet.contains('مشروع') || normalizedSheet.contains('project')) {
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.isEmpty || row[0] == null) continue;

          final code = row[0]?.value?.toString().trim() ?? '';
          final name = (row.length > 1 && row[1] != null) ? row[1]!.value.toString().trim() : '';

          if (code.isNotEmpty && name.isNotEmpty) {
            final projects = await _projectRepo.getAllProjects(search: code);
            if (projects.isEmpty) {
              await _projectRepo.createProject(Project(
                code: code,
                name: name,
                budget: 0.0,
                status: 'active',
              ));
              importedCount++;
            }
          }
        }
      }
    }

    return importedCount;
  }
}
