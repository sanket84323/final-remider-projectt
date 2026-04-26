import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final ApiService _api = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<AuthResponse> login(String email, String password) async {
    // Get FCM token for push notifications
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    try {
      final response = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
        if (fcmToken != null) 'fcmToken': fcmToken,
      });

      final authResponse = AuthResponse.fromJson(response.data['data']);
      
      // Securely store tokens
      await _storage.write(key: 'access_token', value: authResponse.accessToken);
      await _storage.write(key: 'refresh_token', value: authResponse.refreshToken);

      return authResponse;
    } on DioException catch (e) {
      String msg = 'Login failed';
      if (e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      throw Exception(msg);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? className,
    String? section,
    String? rollNumber,
  }) async {
    try {
      final response = await _api.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (className != null) 'className': className,
        if (section != null) 'section': section,
        if (rollNumber != null) 'rollNumber': rollNumber,
      });

      final authResponse = AuthResponse.fromJson(response.data['data']);
      
      // Securely store tokens
      await _storage.write(key: 'access_token', value: authResponse.accessToken);
      await _storage.write(key: 'refresh_token', value: authResponse.refreshToken);

      return authResponse;
    } on DioException catch (e) {
      String msg = 'Registration failed';
      if (e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      throw Exception(msg);
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _api.post('/auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      String msg = 'Failed to change password';
      if (e.response?.data is Map) {
        msg = e.response?.data['message'] ?? msg;
      }
      throw Exception(msg);
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;
    try {
      final response = await _api.get('/users/me');
      return UserModel.fromJson(response.data['data']);
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}
