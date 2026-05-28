class DashboardStatsModel {
  final int totalCars;
  final int available;
  final int rented;
  final int maintenance;
  final double totalIncome;
  final double totalExpense;

  const DashboardStatsModel({
    required this.totalCars,
    required this.available,
    required this.rented,
    required this.maintenance,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCars: (json['totalCars'] as num?)?.toInt() ?? 0,
      available: (json['available'] as num?)?.toInt() ?? 0,
      rented: (json['rented'] as num?)?.toInt() ?? 0,
      maintenance: (json['maintenance'] as num?)?.toInt() ?? 0,
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
    );
  }
}
