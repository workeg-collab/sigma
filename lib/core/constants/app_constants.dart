class AccountType {
  static const String asset = 'asset'; // أصول
  static const String liability = 'liability'; // خصوم
  static const String equity = 'equity'; // حقوق ملكية
  static const String revenue = 'revenue'; // إيرادات
  static const String expense = 'expense'; // مصروفات

  static String getLabelAr(String type) {
    switch (type) {
      case asset: return 'أصول';
      case liability: return 'خصوم';
      case equity: return 'حقوق ملكية';
      case revenue: return 'إيرادات';
      case expense: return 'مصروفات';
      default: return type;
    }
  }
}

class AccountSubType {
  // Assets
  static const String currentAsset = 'current_asset'; // أصول متداولة (صندوق، بنك، عملاء، أوراق قبض)
  static const String fixedAsset = 'fixed_asset'; // أصول ثابتة (معدات، سيارات)
  static const String otherAsset = 'other_asset'; // أصول أخرى

  // Liabilities
  static const String currentLiability = 'current_liability'; // خصوم متداولة (موردين، مقاولين، ضرائب)
  static const String longTermLiability = 'long_term_liability'; // خصوم طويلة الأجل

  // Equity
  static const String capital = 'capital'; // رأس المال
  static const String partnerAccount = 'partner_account'; // جاري الشريك
  static const String retainedEarnings = 'retained_earnings'; // أرباح مرحلة

  // Revenue
  static const String operatingRevenue = 'operating_revenue'; // إيراد النشاط / مبيعات / مستخلصات
  static const String otherRevenue = 'other_revenue'; // إيرادات أخرى

  // Expense
  static const String directCost = 'direct_cost'; // تكاليف مشروعات مباشرة (مواد، مقاولين باطن، عمالة)
  static const String siteExpense = 'site_expense'; // مصاريف موقع
  static const String administrativeExpense = 'administrative_expense'; // مصاريف عمومية وإدارية
  static const String depreciation = 'depreciation'; // إهلاك
  static const String taxExpense = 'tax_expense'; // ضرائب

  static String getLabelAr(String subType) {
    switch (subType) {
      case currentAsset: return 'أصول متداولة';
      case fixedAsset: return 'أصول ثابتة';
      case otherAsset: return 'أصول أخرى';
      case currentLiability: return 'خصوم متداولة';
      case longTermLiability: return 'خصوم غير متداولة';
      case capital: return 'رأس المال';
      case partnerAccount: return 'جاري الشريك';
      case retainedEarnings: return 'أرباح محتجزة ومرحلة';
      case operatingRevenue: return 'إيرادات النشاط';
      case otherRevenue: return 'إيرادات أخرى';
      case directCost: return 'تكاليف مشروعات وعمليات';
      case siteExpense: return 'مصروفات موقع';
      case administrativeExpense: return 'مصروفات عمومية وإدارية';
      case depreciation: return 'إهلاك';
      case taxExpense: return 'ضرائب';
      default: return subType;
    }
  }
}

class NormalBalance {
  static const String debit = 'debit'; // مدين
  static const String credit = 'credit'; // دائن

  static String getLabelAr(String balance) {
    switch (balance) {
      case debit: return 'مدين';
      case credit: return 'دائن';
      default: return balance;
    }
  }
}

class JournalStatus {
  static const String draft = 'draft';
  static const String posted = 'posted';
  static const String cancelled = 'cancelled';

  static String getLabelAr(String status) {
    switch (status) {
      case draft: return 'مسودة';
      case posted: return 'مرحّل';
      case cancelled: return 'ملغي';
      default: return status;
    }
  }
}

class ProjectStatus {
  static const String planning = 'planning';
  static const String active = 'active';
  static const String onHold = 'on_hold';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static String getLabelAr(String status) {
    switch (status) {
      case planning: return 'قيد التخطيط';
      case active: return 'نشط / جاري التنفيذ';
      case onHold: return 'معلق مؤقتاً';
      case completed: return 'منتهي';
      case cancelled: return 'ملغي';
      default: return status;
    }
  }
}
