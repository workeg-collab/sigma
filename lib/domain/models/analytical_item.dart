class AnalyticalItem {
  final int? id;
  final String code;
  final String name;
  final String category; // e.g. materials, labor, equipment, subcontractors, site_expenses
  final bool isActive;
  final String? notes;

  AnalyticalItem({
    this.id,
    required this.code,
    required this.name,
    this.category = 'عام',
    this.isActive = true,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'is_active': isActive ? 1 : 0,
      'notes': notes,
    };
  }

  factory AnalyticalItem.fromMap(Map<String, dynamic> map) {
    return AnalyticalItem(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'عام',
      isActive: (map['is_active'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
    );
  }
}
