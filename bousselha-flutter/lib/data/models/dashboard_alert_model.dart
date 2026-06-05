class DashboardAlertModel {
  final String type;
  final int carId;
  final String carLabel;
  final String message;
  final String severity;
  final String dueDate;
  final int? contractId;

  const DashboardAlertModel({
    required this.type,
    required this.carId,
    required this.carLabel,
    required this.message,
    required this.severity,
    required this.dueDate,
    this.contractId,
  });

  factory DashboardAlertModel.fromJson(Map<String, dynamic> json) {
    return DashboardAlertModel(
      type: json['type'] as String? ?? '',
      carId: (json['carId'] as num?)?.toInt() ?? 0,
      carLabel: json['carLabel'] as String? ?? '',
      message: json['message'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      dueDate: json['dueDate'] as String? ?? '',
      contractId: (json['contractId'] as num?)?.toInt(),
    );
  }
}
