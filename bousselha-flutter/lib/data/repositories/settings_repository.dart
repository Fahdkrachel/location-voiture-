import 'dart:io';
import 'package:dio/dio.dart';
import '../models/settings_model.dart';

class SettingsRepository {
  final Dio dio;

  SettingsRepository(this.dio);

  Future<SettingsModel> getSettings() async {
    final resp = await dio.get('/settings');
    return SettingsModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<SettingsModel> updateCompanyInfo({
    required String companyName,
    String? address,
    String? phone,
    String? fax,
    String? gsm,
    String? email,
    String? website,
  }) async {
    final resp = await dio.put(
      '/settings',
      data: {
        'companyName': companyName,
        'address': address,
        'phone': phone,
        'fax': fax,
        'gsm': gsm,
        'email': email,
        'website': website,
      },
    );
    return SettingsModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<SettingsModel> uploadLogo(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split(Platform.pathSeparator).last),
    });
    final resp = await dio.post('/settings/logo', data: formData);
    return SettingsModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
