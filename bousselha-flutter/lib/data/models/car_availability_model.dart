class CarAvailabilityModel {
  final int carId;
  final String brand;
  final String matricule;
  final String fuelType;
  final String currentStatus;
  final String availabilityLabel;

  const CarAvailabilityModel({
    required this.carId,
    required this.brand,
    required this.matricule,
    required this.fuelType,
    required this.currentStatus,
    required this.availabilityLabel,
  });

  factory CarAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return CarAvailabilityModel(
      carId: json['carId'] as int,
      brand: json['brand'] as String? ?? '',
      matricule: json['matricule'] as String? ?? '',
      fuelType: json['fuelType'] as String? ?? '',
      currentStatus: json['currentStatus'] as String? ?? '',
      availabilityLabel: json['availabilityLabel'] as String? ?? '',
    );
  }
}
