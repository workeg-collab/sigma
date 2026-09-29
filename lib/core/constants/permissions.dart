class AppPermissions {
  // Journal Entries
  static const String viewJournal = 'journal.view';
  static const String createJournal = 'journal.create';
  static const String editDraftJournal = 'journal.edit_draft';
  static const String postJournal = 'journal.post';
  static const String cancelJournal = 'journal.cancel';

  // Reports
  static const String viewReports = 'reports.view';
  static const String exportReports = 'reports.export';

  // Master Data
  static const String manageAccounts = 'accounts.manage';
  static const String manageProjects = 'projects.manage';
  static const String manageContractors = 'contractors.manage';
  static const String manageSuppliers = 'suppliers.manage';
  static const String manageCustomers = 'customers.manage';
  static const String manageAnalytical = 'analytical.manage';

  // System & Settings
  static const String manageUsers = 'users.manage';
  static const String manageFiscalYears = 'fiscal.manage';
  static const String manageSettings = 'settings.manage';
  static const String backupRestore = 'system.backup_restore';
  static const String viewAuditLog = 'system.audit_log';

  static const List<String> allPermissions = [
    viewJournal,
    createJournal,
    editDraftJournal,
    postJournal,
    cancelJournal,
    viewReports,
    exportReports,
    manageAccounts,
    manageProjects,
    manageContractors,
    manageSuppliers,
    manageCustomers,
    manageAnalytical,
    manageUsers,
    manageFiscalYears,
    manageSettings,
    backupRestore,
    viewAuditLog,
  ];

  static Map<String, List<String>> roleDefaults = {
    'Administrator': allPermissions,
    'Accountant': [
      viewJournal,
      createJournal,
      editDraftJournal,
      postJournal,
      viewReports,
      exportReports,
      manageAccounts,
      manageProjects,
      manageContractors,
      manageSuppliers,
      manageCustomers,
      manageAnalytical,
    ],
    'Reviewer': [
      viewJournal,
      postJournal,
      cancelJournal,
      viewReports,
      exportReports,
    ],
    'Data Entry': [
      viewJournal,
      createJournal,
      editDraftJournal,
      viewReports,
    ],
    'Viewer': [
      viewJournal,
      viewReports,
    ],
  };

  static String getPermissionLabelAr(String key) {
    switch (key) {
      case viewJournal: return 'عرض قيود اليومية';
      case createJournal: return 'إنشاء قيد جديد';
      case editDraftJournal: return 'تعديل مسودات القيود';
      case postJournal: return 'ترحيل القيود';
      case cancelJournal: return 'إلغاء قيود مرحلة';
      case viewReports: return 'عرض التقارير والقوائم';
      case exportReports: return 'تصدير التقارير (Excel/PDF)';
      case manageAccounts: return 'إدارة دليل الحسابات';
      case manageProjects: return 'إدارة المشروعات والتكاليف';
      case manageContractors: return 'إدارة حسابات المقاولين';
      case manageSuppliers: return 'إدارة حسابات الموردين';
      case manageCustomers: return 'إدارة حسابات العملاء';
      case manageAnalytical: return 'إدارة التوجيه التحليلي والوحدات';
      case manageUsers: return 'إدارة المستخدمين والصلاحيات';
      case manageFiscalYears: return 'إدارة السنوات والفترات المالية';
      case manageSettings: return 'إدارة إعدادات النظام';
      case backupRestore: return 'النسخ الاحتياطي والاستعادة';
      case viewAuditLog: return 'سجل التدقيق والمراقبة';
      default: return key;
    }
  }
}
