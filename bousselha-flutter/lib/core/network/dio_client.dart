import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080/api',
        connectTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) {
          handler.next(
            DioException(
              requestOptions: e.requestOptions,
              message: e.response?.data?['error']?.toString() ?? e.message,
              response: e.response,
              type: e.type,
            ),
          );
        },
      ),
    );
    return dio;
  }
}
