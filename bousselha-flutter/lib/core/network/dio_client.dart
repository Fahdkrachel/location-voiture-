import 'package:dio/dio.dart';
import '../config/app_config.dart';

class ApiException extends DioException {
  final String cleanMessage;

  ApiException({
    required super.requestOptions,
    super.response,
    super.type,
    super.error,
    required this.cleanMessage,
  }) : super(message: cleanMessage);

  @override
  String toString() => cleanMessage;
}

class DioClient {
  DioClient._();

  static Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          String cleanMsg = '';
          if (e.response?.data != null && e.response!.data is Map) {
            final data = e.response!.data as Map;
            if (data.containsKey('fields') && data['fields'] is Map) {
              final fields = data['fields'] as Map;
              final buffer = StringBuffer();
              buffer.writeln('Erreur de validation :');
              fields.forEach((key, value) {
                buffer.writeln('- $key : $value');
              });
              cleanMsg = buffer.toString().trim();
            } else if (data.containsKey('error')) {
              cleanMsg = data['error'].toString();
            } else if (data.containsKey('message')) {
              cleanMsg = data['message'].toString();
            }
          }

          if (cleanMsg.isEmpty) {
            if (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout) {
              cleanMsg = 'Délai d\'attente dépassé. Veuillez vérifier la connexion au serveur.';
            } else if (e.type == DioExceptionType.connectionError) {
              cleanMsg = 'Impossible de se connecter au serveur. Assurez-vous que le backend est démarré.';
            } else {
              cleanMsg = e.message ?? 'Erreur inconnue de l\'API';
            }
          }

          handler.next(
            ApiException(
              requestOptions: e.requestOptions,
              response: e.response,
              type: e.type,
              error: e.error,
              cleanMessage: cleanMsg,
            ),
          );
        },
      ),
    );
    return dio;
  }
}
