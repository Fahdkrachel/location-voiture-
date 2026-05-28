class DashboardStatsModel {
  final int totalCars;
  final int available;
  final int rented;
  final int maintenance;

  const DashboardStatsModel({
    required this.totalCars,
    required this.available,
    required this.rented,
    required this.maintenance,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCars: (json['totalCars'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      rented: (json['rented'] as num?)?.toInt() ?? 0,
      maintenance: (json['maintenance'] as num?)?.toInt() ?? 0,
    );
  }
}
