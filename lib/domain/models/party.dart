class Contractor {
  final int? id;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final int? projectId;
  final double openingBalance;
  final String? notes;
  final bool isActive;

  // Runtime calculated fields
  final double totalDebit;
  final double totalCredit;
  final double currentBalance; // opening + credit - debit (creditor nature usually)

  Contractor({
    this.id,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.taxNumber,
    this.projectId,
    this.openingBalance = 0.0,
    this.notes,
    this.isActive = true,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.currentBalance = 0.0,
  });

  Contractor copyWith({
    int? id,
    String? code,
    String? name,
    String? phone,
    String? address,
    String? taxNumber,
    int? projectId,
    double? openingBalance,
    String? notes,
    bool? isActive,
    double? totalDebit,
    double? totalCredit,
    double? currentBalance,
  }) {
    return Contractor(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      taxNumber: taxNumber ?? this.taxNumber,
      projectId: projectId ?? this.projectId,
      openingBalance: openingBalance ?? this.openingBalance,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'tax_number': taxNumber,
      'project_id': projectId,
      'opening_balance': openingBalance,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Contractor.fromMap(Map<String, dynamic> map) {
    return Contractor(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      taxNumber: map['tax_number'] as String?,
      projectId: map['project_id'] as int?,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}

class Supplier {
  final int? id;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final double openingBalance;
  final String? notes;
  final bool isActive;

  final double totalDebit;
  final double totalCredit;
  final double currentBalance;

  Supplier({
    this.id,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.taxNumber,
    this.openingBalance = 0.0,
    this.notes,
    this.isActive = true,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'tax_number': taxNumber,
      'opening_balance': openingBalance,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      taxNumber: map['tax_number'] as String?,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}

class Customer {
  final int? id;
  final String code;
  final String name;
  final String? phone;
  final String? address;
  final String? taxNumber;
  final double openingBalance;
  final String? notes;
  final bool isActive;

  final double totalDebit;
  final double totalCredit;
  final double currentBalance;

  Customer({
    this.id,
    required this.code,
    required this.name,
    this.phone,
    this.address,
    this.taxNumber,
    this.openingBalance = 0.0,
    this.notes,
    this.isActive = true,
    this.totalDebit = 0.0,
    this.totalCredit = 0.0,
    this.currentBalance = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'address': address,
      'tax_number': taxNumber,
      'opening_balance': openingBalance,
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      taxNumber: map['tax_number'] as String?,
      openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
