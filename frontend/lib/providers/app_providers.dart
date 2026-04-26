import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import '../data/services/api_service.dart';

// ─── Repositories ─────────────────────────────────────────────────────────────
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) => ReminderRepository());
final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) => AssignmentRepository());
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => NotificationRepository());
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => DashboardRepository());
final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ApiService()));

// ─── Reminder List State ──────────────────────────────────────────────────────
final reminderListProvider = StateNotifierProvider<ReminderListNotifier, AsyncValue<List<ReminderModel>>>((ref) {
  return ReminderListNotifier(ref.watch(reminderRepositoryProvider));
});

class ReminderListNotifier extends StateNotifier<AsyncValue<List<ReminderModel>>> {
  final ReminderRepository _repo;
  int _page = 1;
  bool _hasMore = true;

  // Don't auto-load — screens must call loadReminders() explicitly
  ReminderListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> loadReminders({bool refresh = false, String? priority, String? category, String? search}) async {
    if (refresh) { _page = 1; _hasMore = true; }
    if (!_hasMore && !refresh) return;

    try {
      if (_page == 1) state = const AsyncValue.loading();
      final result = await _repo.getReminders(page: _page, priority: priority, category: category, search: search);
      final newReminders = result['reminders'] as List<ReminderModel>;
      final pagination = result['pagination'];
      _hasMore = pagination['hasNextPage'] ?? false;
      _page++;

      final current = _page == 2 ? <ReminderModel>[] : (state.valueOrNull ?? []);
      state = AsyncValue.data([...current, ...newReminders]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    state = AsyncValue.data(
      state.valueOrNull?.where((r) => r.id != id).toList() ?? [],
    );
  }
}

// ─── Assignment List State ────────────────────────────────────────────────────
final assignmentListProvider = StateNotifierProvider<AssignmentListNotifier, AsyncValue<List<AssignmentModel>>>((ref) {
  return AssignmentListNotifier(ref.watch(assignmentRepositoryProvider));
});

class AssignmentListNotifier extends StateNotifier<AsyncValue<List<AssignmentModel>>> {
  final AssignmentRepository _repo;

  // Don't auto-load — screens must call loadAssignments() explicitly
  AssignmentListNotifier(this._repo) : super(const AsyncValue.data([]));

  Future<void> loadAssignments({bool refresh = false}) async {
    if (refresh || state.valueOrNull == null) state = const AsyncValue.loading();
    try {
      final result = await _repo.getAssignments();
      state = AsyncValue.data(result['assignments'] as List<AssignmentModel>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markComplete(String id) async {
    await _repo.markComplete(id);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(
      current.map((a) => a.id == id
          ? AssignmentModel(
              id: a.id, title: a.title, description: a.description, 
              dueDate: a.dueDate, isCompleted: false, isPending: true, 
              isOverdue: a.isOverdue, subject: a.subject, createdAt: a.createdAt
            )
          : a).toList(),
    );
  }
}

// ─── Notification State ───────────────────────────────────────────────────────
final notificationProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return NotificationNotifier(ref, ref.watch(notificationRepositoryProvider));
});

final unreadCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationProvider).valueOrNull ?? [];
  return notifs.where((n) => !n.readStatus).length;
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref ref;
  final NotificationRepository _repo;

  // Don't auto-load — screens must call loadNotifications() explicitly
  NotificationNotifier(this.ref, this._repo) : super(const AsyncValue.data([]));

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh || state.valueOrNull == null) state = const AsyncValue.loading();
    try {
      final result = await _repo.getNotifications();
      state = AsyncValue.data(result['notifications'] as List<NotificationModel>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = AsyncValue.data(
      state.valueOrNull?.map((n) => n.id == id
          ? NotificationModel(id: n.id, title: n.title, body: n.body, type: n.type, priority: n.priority, readStatus: true, deliveredAt: n.deliveredAt, readAt: DateTime.now(), reminderId: n.reminderId, assignmentId: n.assignmentId)
          : n).toList() ?? [],
    );
    ref.invalidate(studentDashboardProvider);
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    ref.invalidate(studentDashboardProvider);
    await loadNotifications(refresh: true);
  }

  Future<void> deleteNotification(String id) async {
    await _repo.deleteNotification(id);
    state = AsyncValue.data(
      state.valueOrNull?.where((n) => n.id != id).toList() ?? [],
    );
    ref.invalidate(studentDashboardProvider);
  }
}

// ─── Dashboard Provider ───────────────────────────────────────────────────────
final studentDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getStudentDashboard();
});

final teacherDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getTeacherDashboard();
});

final adminDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(dashboardRepositoryProvider).getAdminDashboard();
});

// ─── Theme Provider ───────────────────────────────────────────────────────────
final themeProvider = StateProvider<bool>((ref) => false); // false = light
