class Project {
  final int? id;
  final String code;
  final String name;
  final String? client;
  final String? startDate;
  final String? expectedEndDate;
  final String? actualEndDate;
  final String status; // planning, active, on_hold, completed, cancelled
  final double budget;
  final String? notes;

  // Dynamically calculated financial fields
  final double totalRevenue;
  final double directCost;
  final double indirectCost;
  final double totalCost;
  final double grossProfit;
  final double profitMargin;
  final double contractorBalances;

  Project({
    this.id,
    required this.code,
    required this.name,
    this.client,
    this.startDate,
    this.expectedEndDate,
    this.actualEndDate,
    this.status = 'active',
    this.budget = 0.0,
    this.notes,
    this.totalRevenue = 0.0,
    this.directCost = 0.0,
    this.indirectCost = 0.0,
    this.totalCost = 0.0,
    this.grossProfit = 0.0,
    this.profitMargin = 0.0,
    this.contractorBalances = 0.0,
  });

  Project copyWith({
    int? id,
    String? code,
    String? name,
    String? client,
    String? startDate,
    String? expectedEndDate,
    String? actualEndDate,
    String? status,
    double? budget,
    String? notes,
    double? totalRevenue,
    double? directCost,
    double? indirectCost,
    double? totalCost,
    double? grossProfit,
    double? profitMargin,
    double? contractorBalances,
  }) {
    return Project(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      client: client ?? this.client,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      directCost: directCost ?? this.directCost,
      indirectCost: indirectCost ?? this.indirectCost,
      totalCost: totalCost ?? this.totalCost,
      grossProfit: grossProfit ?? this.grossProfit,
      profitMargin: profitMargin ?? this.profitMargin,
      contractorBalances: contractorBalances ?? this.contractorBalances,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'client': client,
      'start_date': startDate,
      'expected_end_date': expectedEndDate,
      'actual_end_date': actualEndDate,
      'status': status,
      'budget': budget,
      'notes': notes,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      client: map['client'] as String?,
      startDate: map['start_date'] as String?,
      expectedEndDate: map['expected_end_date'] as String?,
      actualEndDate: map['actual_end_date'] as String?,
      status: map['status'] as String? ?? 'active',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
    );
  }
}
