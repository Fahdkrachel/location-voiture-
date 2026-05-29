class ExpenseRecordModel {
  final int id;
  final double amount;
  final String recordedAt;
  final String source;
  final String category;
  final String description;
  final int? maintenanceId;
  final String carName;

  const ExpenseRecordModel({
    required this.id,
    required this.amount,
    required this.recordedAt,
    required this.source,
    required this.category,
    required this.description,
    this.maintenanceId,
    this.carName = '',
  });

  factory ExpenseRecordModel.fromJson(Map<String, dynamic> json) {
    return ExpenseRecordModel(
      id: json['id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      recordedAt: json['recordedAt'] as String? ?? '',
      source: json['source'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      maintenanceId: json['maintenanceId'] as int?,
      carName: json['carName'] as String? ?? '',
    );
  }
}
