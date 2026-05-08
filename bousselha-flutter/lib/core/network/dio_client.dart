import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static Dio build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080/api',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
