class Company {
  final int? id;
  final String name;
  final String nameAr;
  final String? taxNumber;
  final String? commercialRegistry;
  final String? phone;
  final String? address;
  final String currency;
  final String? logoPath;

  Company({
    this.id,
    required this.name,
    required this.nameAr,
    this.taxNumber,
    this.commercialRegistry,
    this.phone,
    this.address,
    this.currency = 'EGP',
    this.logoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'tax_number': taxNumber,
      'commercial_registry': commercialRegistry,
      'phone': phone,
      'address': address,
      'currency': currency,
      'logo_path': logoPath,
    };
  }

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? '',
      taxNumber: map['tax_number'] as String?,
      commercialRegistry: map['commercial_registry'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      currency: map['currency'] as String? ?? 'EGP',
      logoPath: map['logo_path'] as String?,
    );
  }
}
