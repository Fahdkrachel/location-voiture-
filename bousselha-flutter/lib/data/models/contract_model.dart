class ContractModel {
  final int id;
  final int carId;
  final String carLabel;
  final String carBrand;
  final String carMatricule;
  final String carFuelType;
  final String departurePlace;
  final String returnPlace;
  final int clientId;
  final String clientName;
  final String clientBirthDate;
  final String clientAddressMorocco;
  final String clientAddressAbroad;
  final String clientProfession;
  final String clientDrivingLicenseNumber;
  final String clientDrivingLicenseIssuedAt;
  final String clientCinNumber;
  final String clientPassportNumber;
  final String clientPhone;
  final String additionalDriverName;
  final String additionalDriverLicense;
  final String additionalDriverLicenseIssuedAt;
  final String additionalDriverPassport;
  final String departureDatetime;
  final String expectedReturnDatetime;
  final String actualReturnDatetime;
  final int durationDays;
  final double pricePerHour;
  final double pricePerDay;
  final double pricePerWeek;
  final double pricePerMonth;
  final bool withInsurance;
  final double totalPrice;
  final double supplement;
  final String status;
  final double totalGeneral;
  final double paymentCash;
  final double paymentCheck;
  final double paymentDeposit;
  final String vehicleConditionDeparture;
  final String vehicleConditionReturn;
  final String damagesIdentified;
  final String createdAt;
  final bool deleted;

  const ContractModel({
    required this.id,
    required this.carId,
    required this.carLabel,
    required this.carBrand,
    required this.carMatricule,
    required this.carFuelType,
    required this.departurePlace,
    required this.returnPlace,
    required this.clientId,
    required this.clientName,
    required this.clientBirthDate,
    required this.clientAddressMorocco,
    required this.clientAddressAbroad,
    required this.clientProfession,
    required this.clientDrivingLicenseNumber,
    required this.clientDrivingLicenseIssuedAt,
    required this.clientCinNumber,
    required this.clientPassportNumber,
    required this.clientPhone,
    required this.additionalDriverName,
    required this.additionalDriverLicense,
    required this.additionalDriverLicenseIssuedAt,
    required this.additionalDriverPassport,
    required this.departureDatetime,
    required this.expectedReturnDatetime,
    required this.actualReturnDatetime,
    required this.durationDays,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.pricePerWeek,
    required this.pricePerMonth,
    required this.withInsurance,
    required this.totalPrice,
    required this.supplement,
    required this.status,
    required this.totalGeneral,
    required this.paymentCash,
    required this.paymentCheck,
    required this.paymentDeposit,
    required this.vehicleConditionDeparture,
    required this.vehicleConditionReturn,
    required this.damagesIdentified,
    required this.createdAt,
    this.deleted = false,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] as int,
      carId: json['carId'] as int? ?? 0,
      carLabel: json['carLabel'] as String? ?? '',
      carBrand: json['carBrand'] as String? ?? '',
      carMatricule: json['carMatricule'] as String? ?? '',
      carFuelType: json['carFuelType'] as String? ?? '',
      departurePlace: json['departurePlace'] as String? ?? '',
      returnPlace: json['returnPlace'] as String? ?? '',
      clientId: json['clientId'] as int? ?? 0,
      clientName: json['clientName'] as String? ?? '',
      clientBirthDate: json['clientBirthDate'] as String? ?? '',
      clientAddressMorocco: json['clientAddressMorocco'] as String? ?? '',
      clientAddressAbroad: json['clientAddressAbroad'] as String? ?? '',
      clientProfession: json['clientProfession'] as String? ?? '',
      clientDrivingLicenseNumber: json['clientDrivingLicenseNumber'] as String? ?? '',
      clientDrivingLicenseIssuedAt: json['clientDrivingLicenseIssuedAt'] as String? ?? '',
      clientCinNumber: json['clientCinNumber'] as String? ?? '',
      clientPassportNumber: json['clientPassportNumber'] as String? ?? '',
      clientPhone: json['clientPhone'] as String? ?? '',
      additionalDriverName: json['additionalDriverName'] as String? ?? '',
      additionalDriverLicense: json['additionalDriverLicense'] as String? ?? '',
      additionalDriverLicenseIssuedAt: json['additionalDriverLicenseIssuedAt'] as String? ?? '',
      additionalDriverPassport: json['additionalDriverPassport'] as String? ?? '',
      departureDatetime: json['departureDatetime'] as String? ?? '',
      expectedReturnDatetime: json['expectedReturnDatetime'] as String? ?? '',
      actualReturnDatetime: json['actualReturnDatetime'] as String? ?? '',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 0,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0,
      pricePerWeek: (json['pricePerWeek'] as num?)?.toDouble() ?? 0,
      pricePerMonth: (json['pricePerMonth'] as num?)?.toDouble() ?? 0,
      withInsurance: json['withInsurance'] as bool? ?? false,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      supplement: (json['supplement'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      totalGeneral: (json['totalGeneral'] as num?)?.toDouble() ?? 0,
      paymentCash: (json['paymentCash'] as num?)?.toDouble() ?? 0,
      paymentCheck: (json['paymentCheck'] as num?)?.toDouble() ?? 0,
      paymentDeposit: (json['paymentDeposit'] as num?)?.toDouble() ?? 0,
      vehicleConditionDeparture: json['vehicleConditionDeparture'] as String? ?? '',
      vehicleConditionReturn: json['vehicleConditionReturn'] as String? ?? '',
      damagesIdentified: json['damagesIdentified'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      deleted: json['deleted'] as bool? ?? false,
    );
  }
}
