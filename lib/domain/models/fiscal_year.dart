class FiscalYear {
  final int? id;
  final String code;
  final String name;
  final String startDate; // YYYY-MM-DD
  final String endDate;   // YYYY-MM-DD
  final bool isClosed;

  FiscalYear({
    this.id,
    required this.code,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isClosed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'is_closed': isClosed ? 1 : 0,
    };
  }

  factory FiscalYear.fromMap(Map<String, dynamic> map) {
    return FiscalYear(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      startDate: map['start_date'] as String? ?? '',
      endDate: map['end_date'] as String? ?? '',
      isClosed: (map['is_closed'] as int? ?? 0) == 1,
    );
  }
}

class AccountingPeriod {
  final int? id;
  final int fiscalYearId;
  final int periodNumber; // 1 to 12
  final String name;
  final String startDate;
  final String endDate;
  final bool isClosed;
  final String? closedAt;
  final String? closedBy;

  AccountingPeriod({
    this.id,
    required this.fiscalYearId,
    required this.periodNumber,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isClosed = false,
    this.closedAt,
    this.closedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fiscal_year_id': fiscalYearId,
      'period_number': periodNumber,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'is_closed': isClosed ? 1 : 0,
      'closed_at': closedAt,
      'closed_by': closedBy,
    };
  }

  factory AccountingPeriod.fromMap(Map<String, dynamic> map) {
    return AccountingPeriod(
      id: map['id'] as int?,
      fiscalYearId: map['fiscal_year_id'] as int? ?? 0,
      periodNumber: map['period_number'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      startDate: map['start_date'] as String? ?? '',
      endDate: map['end_date'] as String? ?? '',
      isClosed: (map['is_closed'] as int? ?? 0) == 1,
      closedAt: map['closed_at'] as String?,
      closedBy: map['closed_by'] as String?,
    );
  }
}
