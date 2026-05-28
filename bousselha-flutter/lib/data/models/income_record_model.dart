class IncomeRecordModel {
  final int id;
  final double amount;
  final String recordedAt;
  final String source;
  final String description;
  final int? contractId;
  final String createdBy;

  const IncomeRecordModel({
    required this.id,
    required this.amount,
    required this.recordedAt,
    required this.source,
    required this.description,
    this.contractId,
    required this.createdBy,
  });

  factory IncomeRecordModel.fromJson(Map<String, dynamic> json) {
    return IncomeRecordModel(
      id: json['id'] as int,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      recordedAt: json['recordedAt'] as String? ?? '',
      source: json['source'] as String? ?? '',
      description: json['description'] as String? ?? '',
      contractId: json['contractId'] as int?,
      createdBy: json['createdBy'] as String? ?? 'Administrateur',
    );
  }
}
