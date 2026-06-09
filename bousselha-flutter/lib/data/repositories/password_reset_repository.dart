import 'package:dio/dio.dart';

class PasswordResetRepository {
  final Dio dio;

  PasswordResetRepository(this.dio);

  Future<String> requestReset(String email) async {
    final resp = await dio.post(
      '/auth/password-reset/request',
      data: {'email': email},
    );
    return _messageFrom(resp.data,
        'Un code de vérification a été envoyé si le compte est actif.');
  }

  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    final resp = await dio.post(
      '/auth/password-reset/verify',
      data: {'email': email, 'code': code},
    );
    return _messageFrom(resp.data, 'Code vérifié avec succès.');
  }

  Future<String> confirmReset({
    required String email,
    required String code,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final resp = await dio.post(
      '/auth/password-reset/confirm',
      data: {
        'email': email,
        'code': code,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
    return _messageFrom(resp.data, 'Mot de passe réinitialisé avec succès.');
  }

  String _messageFrom(dynamic data, String fallback) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }
}
