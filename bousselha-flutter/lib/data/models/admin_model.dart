class AdminModel {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String status; // ACTIVE, DISABLED
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.status,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }
}
