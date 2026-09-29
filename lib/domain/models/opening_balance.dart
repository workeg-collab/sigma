class OpeningBalance {
  final int? id;
  final int fiscalYearId;
  final int accountId;
  final int? projectId;
  final int? analyticalItemId;
  final double debit;
  final double credit;
  final String? description;

  // Joined fields
  final String? accountCode;
  final String? accountNameAr;
  final String? projectName;
  final String? analyticalName;

  OpeningBalance({
    this.id,
    required this.fiscalYearId,
    required this.accountId,
    this.projectId,
    this.analyticalItemId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.description,
    this.accountCode,
    this.accountNameAr,
    this.projectName,
    this.analyticalName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fiscal_year_id': fiscalYearId,
      'account_id': accountId,
      'project_id': projectId,
      'analytical_item_id': analyticalItemId,
      'debit': debit,
      'credit': credit,
      'description': description,
    };
  }

  factory OpeningBalance.fromMap(Map<String, dynamic> map) {
    return OpeningBalance(
      id: map['id'] as int?,
      fiscalYearId: map['fiscal_year_id'] as int? ?? 0,
      accountId: map['account_id'] as int? ?? 0,
      projectId: map['project_id'] as int?,
      analyticalItemId: map['analytical_item_id'] as int?,
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String?,
      accountCode: map['account_code'] as String?,
      accountNameAr: map['account_name_ar'] as String?,
      projectName: map['project_name'] as String?,
      analyticalName: map['analytical_name'] as String?,
    );
  }
}
