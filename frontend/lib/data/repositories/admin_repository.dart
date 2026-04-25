import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AdminRepository {
  final ApiService _api;

  AdminRepository(this._api);

  Future<List<dynamic>> getUsers({String? role, String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _api.get('/users', queryParameters: queryParams);
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch users');
    }
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await _api.post('/users', data: userData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create user');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _api.delete('/users/$userId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete user');
    }
  }

  // ─── Department Management ──────────────────────────────────────────────────
  Future<List<dynamic>> getDepartments() async {
    try {
      final response = await _api.get('/departments');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch departments');
    }
  }

  Future<void> createDepartment(Map<String, dynamic> data) async {
    try {
      await _api.post('/departments', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create department');
    }
  }

  Future<void> deleteDepartment(String id) async {
    try {
      await _api.delete('/departments/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete department');
    }
  }

  // ─── Class Management ──────────────────────────────────────────────────────
  Future<List<dynamic>> getClasses() async {
    try {
      final response = await _api.get('/classes');
      return response.data['data'] as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch classes');
    }
  }

  Future<void> createClass(Map<String, dynamic> data) async {
    try {
      await _api.post('/classes', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create class');
    }
  }

  Future<void> deleteClass(String id) async {
    try {
      await _api.delete('/classes/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete class');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _api.get('/analytics/dashboard');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to fetch dashboard stats');
    }
  }
}
