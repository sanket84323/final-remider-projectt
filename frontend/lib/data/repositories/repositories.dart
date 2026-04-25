import '../services/api_service.dart';
import '../models/models.dart';
import 'admin_repository.dart';

export 'admin_repository.dart';

class ReminderRepository {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getReminders({
    int page = 1, int limit = 20,
    String? priority, String? category, String? search,
  }) async {
    final response = await _api.get('/reminders', queryParameters: {
      'page': page, 'limit': limit,
      if (priority != null) 'priority': priority,
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    });
    final data = response.data;
    final reminders = (data['data'] as List).map((r) => ReminderModel.fromJson(r)).toList();
    return {'reminders': reminders, 'pagination': data['pagination']};
  }

  Future<ReminderModel> getReminderById(String id) async {
    final response = await _api.get('/reminders/$id');
    return ReminderModel.fromJson(response.data['data']);
  }

  Future<ReminderModel> createReminder(Map<String, dynamic> data) async {
    final response = await _api.post('/reminders', data: data);
    return ReminderModel.fromJson(response.data['data']);
  }

  Future<ReminderModel> updateReminder(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/reminders/$id', data: data);
    return ReminderModel.fromJson(response.data['data']);
  }

  Future<void> deleteReminder(String id) async {
    await _api.delete('/reminders/$id');
  }

  Future<Map<String, dynamic>> getReadReceipts(String id) async {
    final response = await _api.get('/reminders/$id/read-receipts');
    return response.data['data'];
  }
}

class AssignmentRepository {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getAssignments({int page = 1, int limit = 20}) async {
    final response = await _api.get('/assignments', queryParameters: {'page': page, 'limit': limit});
    final data = response.data;
    final assignments = (data['data'] as List).map((a) => AssignmentModel.fromJson(a)).toList();
    return {'assignments': assignments, 'pagination': data['pagination']};
  }

  Future<AssignmentModel> getAssignmentById(String id) async {
    final response = await _api.get('/assignments/$id');
    return AssignmentModel.fromJson(response.data['data']);
  }

  Future<AssignmentModel> createAssignment(Map<String, dynamic> data) async {
    final response = await _api.post('/assignments', data: data);
    return AssignmentModel.fromJson(response.data['data']);
  }

  Future<void> markComplete(String id, {String? note}) async {
    await _api.put('/assignments/$id/complete', data: {'note': note});
  }

  Future<void> deleteAssignment(String id) async {
    await _api.delete('/assignments/$id');
  }
}

class NotificationRepository {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getNotifications({int page = 1, bool unreadOnly = false}) async {
    final response = await _api.get('/notifications', queryParameters: {
      'page': page, 'unreadOnly': unreadOnly,
    });
    final data = response.data['data'];
    final notifications = (data['notifications'] as List).map((n) => NotificationModel.fromJson(n)).toList();
    return {'notifications': notifications, 'unreadCount': data['unreadCount']};
  }

  Future<void> markAsRead(String id) async {
    await _api.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _api.put('/notifications/mark-all-read');
  }

  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }
}

class DashboardRepository {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getStudentDashboard() async {
    final response = await _api.get('/dashboard/student');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getTeacherDashboard() async {
    final response = await _api.get('/dashboard/teacher');
    return response.data['data'];
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await _api.get('/dashboard/admin');
    return response.data['data'];
  }
}
