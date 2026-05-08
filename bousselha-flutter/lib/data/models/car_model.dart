class CarModel {
  final int id;
  final String brand;
  final String matricule;
  final String status;

  const CarModel({
    required this.id,
    required this.brand,
    required this.matricule,
    required this.status,
  });

  factory CarModel.fromJson(Map<String, dynamic> json) {
    return CarModel(
      id: json['id'] as int,
      brand: json['brand'] as String? ?? '',
      matricule: json['matricule'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}
