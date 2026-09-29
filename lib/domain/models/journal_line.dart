class JournalLine {
  final int? id;
  final int? journalEntryId;
  final int lineNumber;
  final int accountId;
  final int? projectId;
  final int? analyticalItemId;
  final int? unitId;
  final double quantity;
  final double unitPrice;
  final double debit;
  final double credit;
  final int? contractorId;
  final int? supplierId;
  final int? customerId;
  final String? description;
  final String? reference;

  // Joined display properties (resolved by queries)
  final String? accountCode;
  final String? accountNameAr;
  final String? projectName;
  final String? analyticalName;
  final String? unitName;
  final String? contractorName;
  final String? supplierName;
  final String? customerName;

  JournalLine({
    this.id,
    this.journalEntryId,
    this.lineNumber = 1,
    required this.accountId,
    this.projectId,
    this.analyticalItemId,
    this.unitId,
    this.quantity = 0.0,
    this.unitPrice = 0.0,
    this.debit = 0.0,
    this.credit = 0.0,
    this.contractorId,
    this.supplierId,
    this.customerId,
    this.description,
    this.reference,
    this.accountCode,
    this.accountNameAr,
    this.projectName,
    this.analyticalName,
    this.unitName,
    this.contractorName,
    this.supplierName,
    this.customerName,
  });

  JournalLine copyWith({
    int? id,
    int? journalEntryId,
    int? lineNumber,
    int? accountId,
    int? projectId,
    int? analyticalItemId,
    int? unitId,
    double? quantity,
    double? unitPrice,
    double? debit,
    double? credit,
    int? contractorId,
    int? supplierId,
    int? customerId,
    String? description,
    String? reference,
    String? accountCode,
    String? accountNameAr,
    String? projectName,
    String? analyticalName,
    String? unitName,
    String? contractorName,
    String? supplierName,
    String? customerName,
  }) {
    return JournalLine(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      lineNumber: lineNumber ?? this.lineNumber,
      accountId: accountId ?? this.accountId,
      projectId: projectId ?? this.projectId,
      analyticalItemId: analyticalItemId ?? this.analyticalItemId,
      unitId: unitId ?? this.unitId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      contractorId: contractorId ?? this.contractorId,
      supplierId: supplierId ?? this.supplierId,
      customerId: customerId ?? this.customerId,
      description: description ?? this.description,
      reference: reference ?? this.reference,
      accountCode: accountCode ?? this.accountCode,
      accountNameAr: accountNameAr ?? this.accountNameAr,
      projectName: projectName ?? this.projectName,
      analyticalName: analyticalName ?? this.analyticalName,
      unitName: unitName ?? this.unitName,
      contractorName: contractorName ?? this.contractorName,
      supplierName: supplierName ?? this.supplierName,
      customerName: customerName ?? this.customerName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'line_number': lineNumber,
      'account_id': accountId,
      'project_id': projectId,
      'analytical_item_id': analyticalItemId,
      'unit_id': unitId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'debit': debit,
      'credit': credit,
      'contractor_id': contractorId,
      'supplier_id': supplierId,
      'customer_id': customerId,
      'description': description,
      'reference': reference,
    };
  }

  factory JournalLine.fromMap(Map<String, dynamic> map) {
    return JournalLine(
      id: map['id'] as int?,
      journalEntryId: map['journal_entry_id'] as int?,
      lineNumber: map['line_number'] as int? ?? 1,
      accountId: map['account_id'] as int? ?? 0,
      projectId: map['project_id'] as int?,
      analyticalItemId: map['analytical_item_id'] as int?,
      unitId: map['unit_id'] as int?,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
      contractorId: map['contractor_id'] as int?,
      supplierId: map['supplier_id'] as int?,
      customerId: map['customer_id'] as int?,
      description: map['description'] as String?,
      reference: map['reference'] as String?,
      accountCode: map['account_code'] as String?,
      accountNameAr: map['account_name_ar'] as String?,
      projectName: map['project_name'] as String?,
      analyticalName: map['analytical_name'] as String?,
      unitName: map['unit_name'] as String?,
      contractorName: map['contractor_name'] as String?,
      supplierName: map['supplier_name'] as String?,
      customerName: map['customer_name'] as String?,
    );
  }
}
