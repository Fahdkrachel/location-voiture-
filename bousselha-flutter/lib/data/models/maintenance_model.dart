class MaintenanceModel {
  final int id;
  final int carId;
  final String carLabel;
  final String type;
  final String startDate;
  final String endDate;
  final double cost;

  const MaintenanceModel({
    required this.id,
    required this.carId,
    required this.carLabel,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.cost,
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      id: json['id'] as int,
      carId: json['carId'] as int? ?? 0,
      carLabel: json['carLabel'] as String? ?? '',
      type: json['type'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
