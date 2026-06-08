class SettingsModel {
  final int id;
  final String companyName;
  final String? address;
  final String? phone;
  final String? fax;
  final String? gsm;
  final String? email;
  final String? website;
  final String? logoUrl;
  final DateTime? updatedAt;

  const SettingsModel({
    required this.id,
    required this.companyName,
    this.address,
    this.phone,
    this.fax,
    this.gsm,
    this.email,
    this.website,
    this.logoUrl,
    this.updatedAt,
  });

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['id'] ?? 1,
      companyName: json['companyName'] ?? 'BOUSSELHA CARS',
      address: json['address'],
      phone: json['phone'],
      fax: json['fax'],
      gsm: json['gsm'],
      email: json['email'],
      website: json['website'],
      logoUrl: json['logoUrl'],
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  SettingsModel copyWith({
    String? companyName,
    String? address,
    String? phone,
    String? fax,
    String? gsm,
    String? email,
    String? website,
    String? logoUrl,
    DateTime? updatedAt,
  }) {
    return SettingsModel(
      id: id,
      companyName: companyName ?? this.companyName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      fax: fax ?? this.fax,
      gsm: gsm ?? this.gsm,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
