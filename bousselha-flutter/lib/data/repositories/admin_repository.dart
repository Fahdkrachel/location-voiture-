import 'package:dio/dio.dart';
import '../models/admin_model.dart';

class AdminRepository {
  final Dio dio;

  AdminRepository(this.dio);

  Future<List<AdminModel>> getAdmins() async {
    final resp = await dio.get('/admins');
    final list = resp.data as List;
    return list.map((e) => AdminModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AdminModel> createAdmin({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final resp = await dio.post(
      '/admins',
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
      },
    );
    return AdminModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<AdminModel> updateAdmin({
    required int id,
    required String fullName,
    required String email,
    required String phone,
  }) async {
    final resp = await dio.put(
      '/admins/$id',
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
      },
    );
    return AdminModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<AdminModel> toggleStatus(int id, String status) async {
    final resp = await dio.patch(
      '/admins/$id/status',
      data: {'status': status},
    );
    return AdminModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required int id,
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    await dio.patch(
      '/admins/$id/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }
}
