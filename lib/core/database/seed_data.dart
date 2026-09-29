import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/app_constants.dart';
import '../constants/permissions.dart';

class DatabaseSeedData {
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  static Future<void> seed(Database db) async {
    // 1. Seed Company
    await db.insert('companies', {
      'name': 'Sigma Construction & Contracting',
      'name_ar': 'شركة سيجما للمقاولات والتشييد',
      'tax_number': '123-456-789',
      'commercial_registry': '987654',
      'phone': '01000000000',
      'address': 'القاهرة، جمهورية مصر العربية',
      'currency': 'EGP',
    });

    // 2. Seed Fiscal Year 2026
    final fiscalYearId = await db.insert('fiscal_years', {
      'code': 'FY2026',
      'name': 'السنة المالية 2026',
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'is_closed': 0,
    });

    // 12 Monthly periods
    final monthNames = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    for (int i = 1; i <= 12; i++) {
      final monthStr = i.toString().padLeft(2, '0');
      final lastDay = (i == 2) ? 28 : ([4, 6, 9, 11].contains(i) ? 30 : 31);
      await db.insert('accounting_periods', {
        'fiscal_year_id': fiscalYearId,
        'period_number': i,
        'name': 'فترة ${monthNames[i - 1]} 2026',
        'start_date': '2026-$monthStr-01',
        'end_date': '2026-$monthStr-$lastDay',
        'is_closed': 0,
      });
    }

    // 3. Seed Account Groups
    final groups = [
      {'code': '1', 'name': 'Assets', 'name_ar': 'الأصول', 'category': AccountType.asset},
      {'code': '2', 'name': 'Liabilities', 'name_ar': 'الخصوم', 'category': AccountType.liability},
      {'code': '3', 'name': 'Equity', 'name_ar': 'حقوق الملكية', 'category': AccountType.equity},
      {'code': '4', 'name': 'Revenues', 'name_ar': 'الإيرادات', 'category': AccountType.revenue},
      {'code': '5', 'name': 'Expenses', 'name_ar': 'المصروفات والتكاليف', 'category': AccountType.expense},
    ];
    for (var g in groups) {
      await db.insert('account_groups', g);
    }

    // 4. Seed Standard Chart of Accounts (from the reference system)
    final accounts = [
      // 1. الأصول
      {
        'code': '1101',
        'name': 'Cash in Safe',
        'name_ar': 'الصندوق والخزينة',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.currentAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '1102',
        'name': 'Bank Accounts',
        'name_ar': 'البنك',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.currentAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '1103',
        'name': 'Accounts Receivable - Customers',
        'name_ar': 'عملاء',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.currentAsset,
        'normal_balance': NormalBalance.debit,
        'requires_project': 1,
        'level': 2,
      },
      {
        'code': '1104',
        'name': 'Notes Receivable',
        'name_ar': 'أوراق قبض',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.currentAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '1105',
        'name': 'Checks Under Collection',
        'name_ar': 'شيكات تحت التحصيل',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.currentAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '1106',
        'name': 'Prepaid Expenses',
        'name_ar': 'مصروف مقدم',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.currentAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '1201',
        'name': 'Fixed Assets',
        'name_ar': 'الأصول الثابتة والمعدات',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.fixedAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '1202',
        'name': 'Incorporation Expenses',
        'name_ar': 'م تأسيس',
        'account_type': AccountType.asset,
        'sub_type': AccountSubType.otherAsset,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },

      // 2. الخصوم
      {
        'code': '2101',
        'name': 'Suppliers',
        'name_ar': 'موردين',
        'account_type': AccountType.liability,
        'sub_type': AccountSubType.currentLiability,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },
      {
        'code': '2102',
        'name': 'Subcontractors',
        'name_ar': 'مقاولين',
        'account_type': AccountType.liability,
        'sub_type': AccountSubType.currentLiability,
        'normal_balance': NormalBalance.credit,
        'requires_project': 1,
        'level': 2,
      },
      {
        'code': '2103',
        'name': 'Value Added Tax (VAT)',
        'name_ar': 'ض ق م (ضريبة القيمة المضافة)',
        'account_type': AccountType.liability,
        'sub_type': AccountSubType.currentLiability,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },
      {
        'code': '2104',
        'name': 'Commercial & Industrial Profit Tax',
        'name_ar': 'ضريبة أرباح تجارية وصناعية',
        'account_type': AccountType.liability,
        'sub_type': AccountSubType.currentLiability,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },
      {
        'code': '2105',
        'name': 'Contractor Deductions',
        'name_ar': 'خصومات مقاولين وتأمينات أعمال',
        'account_type': AccountType.liability,
        'sub_type': AccountSubType.currentLiability,
        'normal_balance': NormalBalance.credit,
        'requires_project': 1,
        'level': 2,
      },

      // 3. حقوق الملكية
      {
        'code': '3101',
        'name': 'Capital',
        'name_ar': 'رأس المال',
        'account_type': AccountType.equity,
        'sub_type': AccountSubType.capital,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },
      {
        'code': '3102',
        'name': 'Partner Current Account',
        'name_ar': 'جاري الشريك',
        'account_type': AccountType.equity,
        'sub_type': AccountSubType.partnerAccount,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },
      {
        'code': '3103',
        'name': 'Retained Earnings',
        'name_ar': 'أرباح مرحلة ومحتجزة',
        'account_type': AccountType.equity,
        'sub_type': AccountSubType.retainedEarnings,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },

      // 4. الإيرادات
      {
        'code': '4101',
        'name': 'Project Revenues & Sales',
        'name_ar': 'المبيعات وإيراد العمليات والمستخلصات',
        'account_type': AccountType.revenue,
        'sub_type': AccountSubType.operatingRevenue,
        'normal_balance': NormalBalance.credit,
        'requires_project': 1,
        'level': 2,
      },
      {
        'code': '4102',
        'name': 'Other Revenues',
        'name_ar': 'إيرادات أخرى متنوعة',
        'account_type': AccountType.revenue,
        'sub_type': AccountSubType.otherRevenue,
        'normal_balance': NormalBalance.credit,
        'level': 2,
      },

      // 5. المصروفات والتكاليف
      {
        'code': '5101',
        'name': 'Material Purchases',
        'name_ar': 'مشتريات مواد',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.directCost,
        'normal_balance': NormalBalance.debit,
        'requires_project': 1,
        'requires_analytical': 1,
        'level': 2,
      },
      {
        'code': '5102',
        'name': 'Purchase Returns',
        'name_ar': 'مردودات مشتريات',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.directCost,
        'normal_balance': NormalBalance.credit,
        'requires_project': 1,
        'level': 2,
      },
      {
        'code': '5103',
        'name': 'Operating & Site Cost',
        'name_ar': 'مصروف العمليات',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.directCost,
        'normal_balance': NormalBalance.debit,
        'requires_project': 1,
        'requires_analytical': 1,
        'level': 2,
      },
      {
        'code': '5104',
        'name': 'Site Expenses',
        'name_ar': 'مصروفات موقع',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.siteExpense,
        'normal_balance': NormalBalance.debit,
        'requires_project': 1,
        'requires_analytical': 1,
        'level': 2,
      },
      {
        'code': '5105',
        'name': 'Labor Expenses',
        'name_ar': 'مصروفات عمالة',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.directCost,
        'normal_balance': NormalBalance.debit,
        'requires_project': 1,
        'requires_analytical': 1,
        'level': 2,
      },
      {
        'code': '5201',
        'name': 'General and Administrative Expenses',
        'name_ar': 'مصروفات عمومية وإدارية',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.administrativeExpense,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '5202',
        'name': 'Sundry & Petty Cash Expenses',
        'name_ar': 'نثريات',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.administrativeExpense,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
      {
        'code': '5203',
        'name': 'Maintenance Expenses',
        'name_ar': 'مصروفات صيانة',
        'account_type': AccountType.expense,
        'sub_type': AccountSubType.administrativeExpense,
        'normal_balance': NormalBalance.debit,
        'level': 2,
      },
    ];

    for (var acc in accounts) {
      await db.insert('accounts', acc);
    }

    // 5. Seed Reference Projects
    final projects = [
      {'code': 'PRJ-01', 'name': 'نيوم أكتوبر فيلات', 'budget': 15000000.0, 'status': 'active'},
      {'code': 'PRJ-02', 'name': 'نيوم أكتوبر انفرا', 'budget': 22000000.0, 'status': 'active'},
      {'code': 'PRJ-03', 'name': 'بيراميدز', 'budget': 8500000.0, 'status': 'active'},
      {'code': 'PRJ-04', 'name': 'بارك استريت', 'budget': 12000000.0, 'status': 'active'},
      {'code': 'PRJ-05', 'name': 'المجمع الطبي', 'budget': 9500000.0, 'status': 'active'},
      {'code': 'PRJ-06', 'name': 'مطبخ مستشفي العجوزة', 'budget': 4200000.0, 'status': 'active'},
      {'code': 'PRJ-07', 'name': 'التجمع الخامس', 'budget': 18000000.0, 'status': 'active'},
      {'code': 'PRJ-08', 'name': 'باب الشعريه', 'budget': 3500000.0, 'status': 'completed'},
      {'code': 'PRJ-09', 'name': 'قسم فيصل', 'budget': 5000000.0, 'status': 'active'},
      {'code': 'PRJ-10', 'name': 'اسانسير أكتوبر', 'budget': 1200000.0, 'status': 'active'},
      {'code': 'PRJ-11', 'name': 'احمد حسين', 'budget': 3000000.0, 'status': 'active'},
      {'code': 'PRJ-12', 'name': 'خاص م محمد أبو اليزيد', 'budget': 2000000.0, 'status': 'active'},
      {'code': 'PRJ-13', 'name': 'مصروفات صيانه', 'budget': 500000.0, 'status': 'active'},
      {'code': 'PRJ-14', 'name': 'الأصول والمعدات', 'budget': 5000000.0, 'status': 'active'},
    ];
    for (var p in projects) {
      await db.insert('projects', p);
    }

    // 6. Seed Analytical Items
    final analyticalItems = [
      {'code': 'AN-01', 'name': 'توريدات الخرسانه', 'category': 'مواد مباشرة'},
      {'code': 'AN-02', 'name': 'النجاره المسلحه', 'category': 'مقاولين باطن'},
      {'code': 'AN-03', 'name': 'اعمال الحداده', 'category': 'مقاولين باطن'},
      {'code': 'AN-04', 'name': 'توريدات الحديد', 'category': 'مواد مباشرة'},
      {'code': 'AN-05', 'name': 'اعمال الكهرباء', 'category': 'تشطيبات'},
      {'code': 'AN-06', 'name': 'اخشاب', 'category': 'مواد مباشرة'},
      {'code': 'AN-07', 'name': 'طاقه شمسيه', 'category': 'أعمال كهروميكانيكية'},
      {'code': 'AN-08', 'name': 'معدات وايجار معدات', 'category': 'معدات'},
      {'code': 'AN-09', 'name': 'مكاتب وكرفان', 'category': 'مصروفات موقع'},
      {'code': 'AN-10', 'name': 'اجهزة كمبيوتر', 'category': 'أصول ومعدات'},
      {'code': 'AN-11', 'name': 'مصروفات موقع', 'category': 'مصروفات موقع'},
      {'code': 'AN-12', 'name': 'مصروفات عماله', 'category': 'عمالة مباشرة'},
      {'code': 'AN-13', 'name': 'رخام', 'category': 'تشطيبات'},
      {'code': 'AN-14', 'name': 'سيراميك', 'category': 'تشطيبات'},
      {'code': 'AN-15', 'name': 'اعمال تكييف', 'category': 'أعمال كهروميكانيكية'},
      {'code': 'AN-16', 'name': 'اعمال نجاره', 'category': 'تشطيبات'},
      {'code': 'AN-17', 'name': 'مكتب استشاري', 'category': 'استشارات ومكتب فني'},
      {'code': 'AN-18', 'name': 'نجاره الخزان', 'category': 'مقاولين باطن'},
      {'code': 'AN-19', 'name': 'مواد مباشره', 'category': 'مواد مباشرة'},
      {'code': 'AN-20', 'name': 'مواسير وتغذية وصرف', 'category': 'مواد مباشرة'},
      {'code': 'AN-21', 'name': 'م صيانه', 'category': 'صيانة'},
      {'code': 'AN-22', 'name': 'نثريات', 'category': 'عمومية'},
      {'code': 'AN-23', 'name': 'سيكوريت', 'category': 'تشطيبات'},
      {'code': 'AN-24', 'name': 'مرتبات وأجور', 'category': 'عمالة وموظفين'},
      {'code': 'AN-25', 'name': 'اعمال المحاره', 'category': 'تشطيبات'},
      {'code': 'AN-26', 'name': 'اعمال جسيبسون بورد', 'category': 'تشطيبات'},
      {'code': 'AN-27', 'name': 'اعمال المباني', 'category': 'أعمال مباني'},
      {'code': 'AN-28', 'name': 'شوب درونج ومكتب فني', 'category': 'استشارات ومكتب فني'},
      {'code': 'AN-29', 'name': 'توريدات الطوب', 'category': 'مواد مباشرة'},
      {'code': 'AN-30', 'name': 'احلال وردم', 'category': 'أعمال حفر وإحلال'},
      {'code': 'AN-31', 'name': 'اعمال حفر', 'category': 'أعمال حفر وإحلال'},
    ];
    for (var a in analyticalItems) {
      await db.insert('analytical_items', a);
    }

    // 7. Seed Units
    final units = [
      {'code': 'U-01', 'name': 'طن', 'symbol': 'طن'},
      {'code': 'U-02', 'name': 'متر مكعب', 'symbol': 'م3'},
      {'code': 'U-03', 'name': 'متر طولي', 'symbol': 'م.ط'},
      {'code': 'U-04', 'name': 'متر مسطح', 'symbol': 'م2'},
      {'code': 'U-05', 'name': 'بالسقف', 'symbol': 'سقف'},
      {'code': 'U-06', 'name': 'بالسلم', 'symbol': 'سلم'},
      {'code': 'U-07', 'name': 'بالفيلا', 'symbol': 'فيلا'},
      {'code': 'U-08', 'name': 'نقل ومشوار', 'symbol': 'نقل'},
      {'code': 'U-09', 'name': 'ضرائب ورسوم', 'symbol': 'رسوم'},
      {'code': 'U-10', 'name': 'إيجار شقق موظفين', 'symbol': 'شهر'},
      {'code': 'U-11', 'name': 'مولد كهرباء', 'symbol': 'يوم'},
      {'code': 'U-12', 'name': 'عدد / بالقطعة', 'symbol': 'عدد'},
    ];
    for (var u in units) {
      await db.insert('units', u);
    }

    // 8. Seed Contractors & Suppliers
    final contractors = [
      {'code': 'CON-01', 'name': 'مقاولات الأمل للمسلحات', 'phone': '0111111111', 'project_id': 1},
      {'code': 'CON-02', 'name': 'شركة الأهرام لأعمال الحفر والردم', 'phone': '0122222222', 'project_id': 2},
      {'code': 'CON-03', 'name': 'مؤسسة السلام للتشطيبات والرخام', 'phone': '0103333333', 'project_id': 1},
    ];
    for (var c in contractors) {
      await db.insert('contractors', c);
    }

    final suppliers = [
      {'code': 'SUP-01', 'name': 'شركة السويس للأسمنت والخرسانة', 'phone': '0104444444'},
      {'code': 'SUP-02', 'name': 'مجموعة عز للحديد والصلب', 'phone': '0105555555'},
      {'code': 'SUP-03', 'name': 'سيراميك كليوباترا', 'phone': '0106666666'},
    ];
    for (var s in suppliers) {
      await db.insert('suppliers', s);
    }

    final customers = [
      {'code': 'CUST-01', 'name': 'شركة تطوير مصر للاستثمار العقاري', 'phone': '0107777777'},
      {'code': 'CUST-02', 'name': 'جهاز مدينة 6 أكتوبر', 'phone': '0108888888'},
    ];
    for (var cu in customers) {
      await db.insert('customers', cu);
    }

    // 9. Seed Roles & Permissions
    final roles = [
      {'id': 1, 'code': 'ADMIN', 'name': 'Administrator', 'description': 'مسؤول النظام الكامل', 'is_system': 1},
      {'id': 2, 'code': 'ACCOUNTANT', 'name': 'Accountant', 'description': 'محاسب مسؤول عن القيود والتقارير', 'is_system': 1},
      {'id': 3, 'code': 'REVIEWER', 'name': 'Reviewer', 'description': 'مراجع مالي ومعتمد للقيود', 'is_system': 1},
      {'id': 4, 'code': 'DATA_ENTRY', 'name': 'Data Entry', 'description': 'مدخل بيانات مسودات فقط', 'is_system': 1},
      {'id': 5, 'code': 'VIEWER', 'name': 'Viewer', 'description': 'مشاهدة وتقارير فقط', 'is_system': 1},
    ];
    for (var r in roles) {
      await db.insert('roles', r);
    }

    // Insert permissions for each role
    for (var r in roles) {
      final roleName = r['name'] as String;
      final perms = AppPermissions.roleDefaults[roleName] ?? [];
      for (var p in perms) {
        await db.insert('permissions', {
          'role_id': r['id'],
          'permission_key': p,
          'is_granted': 1,
        });
      }
    }

    // 10. Seed Default Users
    final users = [
      {
        'username': 'admin',
        'full_name': 'المدير العام (مسؤول النظام)',
        'email': 'admin@sigma.com',
        'password_hash': hashPassword('admin123'),
        'role_id': 1,
        'is_active': 1,
      },
      {
        'username': 'accountant',
        'full_name': 'أحمد إبراهيم (رئيس الحسابات)',
        'email': 'accountant@sigma.com',
        'password_hash': hashPassword('acc123'),
        'role_id': 2,
        'is_active': 1,
      },
      {
        'username': 'reviewer',
        'full_name': 'محمد فاروق (المراجع المالي)',
        'email': 'reviewer@sigma.com',
        'password_hash': hashPassword('rev123'),
        'role_id': 3,
        'is_active': 1,
      },
      {
        'username': 'data_entry',
        'full_name': 'سارة عادل (مدخل بيانات)',
        'email': 'entry@sigma.com',
        'password_hash': hashPassword('entry123'),
        'role_id': 4,
        'is_active': 1,
      },
    ];
    for (var u in users) {
      await db.insert('users', u);
    }

    // 11. Initial Audit Log
    await db.insert('audit_logs', {
      'user_id': 1,
      'username': 'admin',
      'action': 'System Initialized',
      'record_type': 'Database',
      'record_id': '1',
      'details': 'تم تهيئة النظام وقواعد البيانات ودليل الحسابات والمشروعات بنجاح',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
