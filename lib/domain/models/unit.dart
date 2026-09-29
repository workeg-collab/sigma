class Unit {
  final int? id;
  final String code;
  final String name;
  final String? symbol;
  final bool isActive;

  Unit({
    this.id,
    required this.code,
    required this.name,
    this.symbol,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'symbol': symbol,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      symbol: map['symbol'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }
}
