class ClientModel {
  final int id;
  final String fullName;
  final String birthDate;
  final String addressMorocco;
  final String addressAbroad;
  final String profession;
  final String drivingLicenseNumber;
  final String drivingLicenseIssuedAt;
  final String cinNumber;
  final String passportNumber;
  final String passportIssuedAt;
  final String phone;

  final String additionalDriverFullName;
  final String additionalDriverDrivingLicenseNumber;
  final String additionalDriverDrivingLicenseIssuedAt;
  final String additionalDriverPassportNumber;

  const ClientModel({
    required this.id,
    required this.fullName,
    required this.birthDate,
    required this.addressMorocco,
    required this.addressAbroad,
    required this.profession,
    required this.drivingLicenseNumber,
    required this.drivingLicenseIssuedAt,
    required this.phone,
    required this.cinNumber,
    required this.passportNumber,
    required this.passportIssuedAt,
    required this.additionalDriverFullName,
    required this.additionalDriverDrivingLicenseNumber,
    required this.additionalDriverDrivingLicenseIssuedAt,
    required this.additionalDriverPassportNumber,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      addressMorocco: json['addressMorocco'] as String? ?? '',
      addressAbroad: json['addressAbroad'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      drivingLicenseNumber: json['drivingLicenseNumber'] as String? ?? '',
      drivingLicenseIssuedAt: json['drivingLicenseIssuedAt'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      cinNumber: json['cinNumber'] as String? ?? '',
      passportNumber: json['passportNumber'] as String? ?? '',
      passportIssuedAt: json['passportIssuedAt'] as String? ?? '',
      additionalDriverFullName: json['additionalDriverFullName'] as String? ?? '',
      additionalDriverDrivingLicenseNumber: json['additionalDriverDrivingLicenseNumber'] as String? ?? '',
      additionalDriverDrivingLicenseIssuedAt: json['additionalDriverDrivingLicenseIssuedAt'] as String? ?? '',
      additionalDriverPassportNumber: json['additionalDriverPassportNumber'] as String? ?? '',
    );
  }
}
