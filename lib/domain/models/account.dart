class AccountGroup {
  final int? id;
  final String code;
  final String name;
  final String nameAr;
  final int? parentId;
  final String category; // asset, liability, equity, revenue, expense

  AccountGroup({
    this.id,
    required this.code,
    required this.name,
    required this.nameAr,
    this.parentId,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'name_ar': nameAr,
      'parent_id': parentId,
      'category': category,
    };
  }

  factory AccountGroup.fromMap(Map<String, dynamic> map) {
    return AccountGroup(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? '',
      parentId: map['parent_id'] as int?,
      category: map['category'] as String? ?? '',
    );
  }
}

class Account {
  final int? id;
  final String code;
  final String name;
  final String nameAr;
  final int? groupId;
  final int? parentId;
  final String accountType; // asset, liability, equity, revenue, expense
  final String subType;     // current_asset, fixed_asset, direct_cost, etc.
  final String normalBalance; // debit, credit
  final bool isActive;
  final bool requiresProject;
  final bool requiresAnalytical;
  final String? notes;
  final int level;

  // Runtime helper fields (not stored directly in account table)
  final double currentBalance;
  final double totalDebit;
  final double totalCredit;

  Account({
    this.id,
    required this.code,
    required this.name,
    required this.nameAr,
    this.groupId,
    this.parentId,
    required this.accountType,
    required this.subType,
    required this.normalBalance,
    this.isActive = true,
    this.requiresProject = false,
    this.requiresAnalytical = false,
    this.notes,
    this.level = 1,
    this.currentBalance = 0.0,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
  });

  Account copyWith({
    int? id,
    String? code,
    String? name,
    String? nameAr,
    int? groupId,
    int? parentId,
    String? accountType,
    String? subType,
    String? normalBalance,
    bool? isActive,
    bool? requiresProject,
    bool? requiresAnalytical,
    String? notes,
    int? level,
    double? currentBalance,
    double? totalDebit,
    double? totalCredit,
  }) {
    return Account(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      groupId: groupId ?? this.groupId,
      parentId: parentId ?? this.parentId,
      accountType: accountType ?? this.accountType,
      subType: subType ?? this.subType,
      normalBalance: normalBalance ?? this.normalBalance,
      isActive: isActive ?? this.isActive,
      requiresProject: requiresProject ?? this.requiresProject,
      requiresAnalytical: requiresAnalytical ?? this.requiresAnalytical,
      notes: notes ?? this.notes,
      level: level ?? this.level,
      currentBalance: currentBalance ?? this.currentBalance,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'name_ar': nameAr,
      'group_id': groupId,
      'parent_id': parentId,
      'account_type': accountType,
      'sub_type': subType,
      'normal_balance': normalBalance,
      'is_active': isActive ? 1 : 0,
      'requires_project': requiresProject ? 1 : 0,
      'requires_analytical': requiresAnalytical ? 1 : 0,
      'notes': notes,
      'level': level,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? '',
      groupId: map['group_id'] as int?,
      parentId: map['parent_id'] as int?,
      accountType: map['account_type'] as String? ?? 'asset',
      subType: map['sub_type'] as String? ?? '',
      normalBalance: map['normal_balance'] as String? ?? 'debit',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      requiresProject: (map['requires_project'] as int? ?? 0) == 1,
      requiresAnalytical: (map['requires_analytical'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      level: map['level'] as int? ?? 1,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      totalDebit: (map['total_debit'] as num?)?.toDouble() ?? 0.0,
      totalCredit: (map['total_credit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
