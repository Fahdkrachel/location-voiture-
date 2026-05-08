class ContractModel {
  final int id;
  final String carLabel;
  final String clientName;
  final String departureDatetime;
  final String expectedReturnDatetime;
  final String status;
  final double totalGeneral;

  const ContractModel({
    required this.id,
    required this.carLabel,
    required this.clientName,
    required this.departureDatetime,
    required this.expectedReturnDatetime,
    required this.status,
    required this.totalGeneral,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] as int,
      carLabel: json['carLabel'] as String? ?? '',
      clientName: json['clientName'] as String? ?? '',
      departureDatetime: json['departureDatetime'] as String? ?? '',
      expectedReturnDatetime: json['expectedReturnDatetime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      totalGeneral: (json['totalGeneral'] as num?)?.toDouble() ?? 0,
    );
  }
}
