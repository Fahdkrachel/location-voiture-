class CarModel {
  final int id;
  final String brand;
  final String fuelType;
  final String matricule;
  final String nextInspectionDate;
  final String lastOilChangeDate;
  final String insuranceExpiryDate;
  final String imageUrl;
  final String status;

  const CarModel({
    required this.id,
    required this.brand,
    required this.fuelType,
    required this.matricule,
    required this.nextInspectionDate,
    required this.lastOilChangeDate,
    required this.insuranceExpiryDate,
    required this.imageUrl,
    required this.status,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] as int,
      brand: json['brand'] as String? ?? '',
      fuelType: json['fuelType'] as String? ?? '',
      matricule: json['matricule'] as String? ?? '',
      nextInspectionDate: json['nextInspectionDate'] as String? ?? '',
      lastOilChangeDate: json['lastOilChangeDate'] as String? ?? '',
      insuranceExpiryDate: json['insuranceExpiryDate'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
