import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'app_providers.dart';

final secureStorage = FlutterSecureStorage();

class AuthState {
  final String? token;
  final Map<String, dynamic>? admin; // minimal
  final bool isInitialized;
  
  AuthState({this.token, this.admin, this.isInitialized = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio dio;
  AuthNotifier(this.dio) : super(AuthState(token: null, admin: null, isInitialized: false)) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final t = await secureStorage.read(key: 'jwt_token');
      if (t != null) {
        try {
          // Validate token and fetch fresh profile
          final resp = await dio.get('/auth/me', options: Options(headers: {'Authorization': 'Bearer $t'}));
          final data = resp.data as Map<String, dynamic>;
          dio.options.headers['Authorization'] = 'Bearer $t';
          state = AuthState(
            token: t,
            admin: {'id': data['id'], 'fullName': data['fullName'], 'email': data['email']},
            isInitialized: true,
          );
        } catch (e) {
          // Token expired or invalid
          await secureStorage.delete(key: 'jwt_token');
          dio.options.headers.remove('Authorization');
          state = AuthState(token: null, admin: null, isInitialized: true);
        }
      } else {
        state = AuthState(token: null, admin: null, isInitialized: true);
      }
    } catch (e) {
      state = AuthState(token: null, admin: null, isInitialized: true);
    }
  }

  Future<void> login(String email, String password) async {
    final resp = await dio.post('/auth/login', data: {'email': email, 'password': password});
    final data = resp.data as Map<String, dynamic>;
    final token = data['token'] as String;
    await secureStorage.write(key: 'jwt_token', value: token);
    dio.options.headers['Authorization'] = 'Bearer $token';
    state = AuthState(
      token: token,
      admin: {'id': data['id'], 'fullName': data['fullName'], 'email': data['email']},
      isInitialized: true,
    );
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'jwt_token');
    dio.options.headers.remove('Authorization');
    state = AuthState(token: null, admin: null, isInitialized: true);
  }

  void updateLocalAdminInfo(Map<String, dynamic> adminInfo) {
    if (state.token != null) {
      state = AuthState(
        token: state.token,
        admin: adminInfo,
        isInitialized: true,
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider));
});

