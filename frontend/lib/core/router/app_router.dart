import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/student/student_shell.dart';
import '../../screens/student/student_dashboard.dart';
import '../../screens/student/notification_list_screen.dart';
import '../../screens/student/reminder_detail_screen.dart';

import '../../screens/student/calendar_screen.dart';
import '../../screens/student/profile_screen.dart';
import '../../screens/student/settings_screen.dart';
import '../../screens/student/assignment_list_screen.dart';
import '../../screens/teacher/teacher_shell.dart';
import '../../screens/teacher/teacher_dashboard.dart';
import '../../screens/teacher/create_reminder_screen.dart';
import '../../screens/teacher/create_assignment_screen.dart';
import '../../screens/teacher/scheduled_reminders_screen.dart';
import '../../screens/teacher/read_receipts_screen.dart';
import '../../screens/teacher/teacher_profile_screen.dart';
import '../../screens/teacher/teacher_assignment_detail_screen.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/admin/admin_dashboard.dart';
import '../../screens/admin/user_management_screen.dart';
import '../../screens/admin/department_management_screen.dart';
import '../../screens/admin/announcement_screen.dart';
import '../../screens/admin/analytics_screen.dart';
import '../../screens/admin/class_assignment_detail_screen.dart';
import '../../screens/admin/class_management_screen.dart';
import '../../screens/admin/student_detail_screen.dart';
import '../../screens/shared/assignment_detail_screen.dart';
import '../../screens/admin/teacher_detail_screen.dart';

final _rootNavigatorKey    = GlobalKey<NavigatorState>();
final _studentTab0NavKey   = GlobalKey<NavigatorState>();
final _studentTab1NavKey   = GlobalKey<NavigatorState>();
final _studentTab2NavKey   = GlobalKey<NavigatorState>();
final _studentTab3NavKey   = GlobalKey<NavigatorState>();
final _teacherTab0NavKey   = GlobalKey<NavigatorState>();
final _teacherTab1NavKey   = GlobalKey<NavigatorState>();
final _teacherTab2NavKey   = GlobalKey<NavigatorState>();
final _teacherTab3NavKey   = GlobalKey<NavigatorState>();
final _adminTab0NavKey     = GlobalKey<NavigatorState>();
final _adminTab1NavKey     = GlobalKey<NavigatorState>();
final _adminTab2NavKey     = GlobalKey<NavigatorState>();
final _adminTab3NavKey     = GlobalKey<NavigatorState>();

// ─── RouterNotifier: bridges Riverpod auth state → GoRouter refresh ──────────
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(authStateProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final loc = state.uri.path;

    // Always allow splash and onboarding
    if (loc.startsWith('/splash') || loc.startsWith('/onboarding')) return null;

    // Still loading auth — stay on splash if we are already there, or stay where we are if we are logging in/signing up
    if (authAsync.isLoading) {
      if (loc.startsWith('/login') || loc.startsWith('/signup') || loc.startsWith('/onboarding')) return null;
      return loc.startsWith('/splash') ? null : '/splash';
    }

    final user = authAsync.valueOrNull;
    final isLoggedIn = user != null;
    final role = user?.role;

    // Not logged in → send to login
    if (!isLoggedIn && !loc.startsWith('/login') && !loc.startsWith('/signup') && !loc.startsWith('/forgot-password')) {
      return '/login';
    }

    // Logged in → redirect from auth screens to dashboard
    if (isLoggedIn && (loc.startsWith('/login') || loc.startsWith('/signup') || loc.startsWith('/splash'))) {
      if (role == 'student') return '/student';
      if (role == 'teacher') return '/teacher';
      if (role == 'admin')   return '/admin';
      return '/student'; // Fallback
    }

    // Role-based path protection
    if (isLoggedIn && role == 'student' && loc.startsWith('/teacher')) return '/student';
    if (isLoggedIn && role == 'student' && loc.startsWith('/admin'))   return '/student';
    if (isLoggedIn && role == 'teacher' && loc.startsWith('/admin'))   return '/teacher';
    if (isLoggedIn && role == 'teacher' && loc.startsWith('/student')) return '/teacher';

    return null;
  }
}

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>(
  (ref) => RouterNotifier(ref),
);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ─── Auth Routes ────────────────────────────────────────────────────
      GoRoute(path: '/splash',        builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding',    builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',         builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',          builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

      // ─── Student Shell (4 tabs: Home | Alerts | Calendar | Profile) ────
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) => StudentShell(shell: shell),
        branches: [
          // Tab 0 – Home / Dashboard
          StatefulShellBranch(navigatorKey: _studentTab0NavKey, routes: [
            GoRoute(
              path: '/student',
              builder: (_, __) => const StudentDashboard(),
              routes: [
                GoRoute(path: 'reminder/:id',   builder: (_, s) => ReminderDetailScreen(reminderId: s.pathParameters['id']!)),
                GoRoute(path: 'assignment/:id', builder: (_, s) => AssignmentDetailScreen(assignmentId: s.pathParameters['id']!)),
                GoRoute(path: 'assignments',     builder: (_, __) => const StudentAssignmentScreen()),
                GoRoute(path: 'settings',       builder: (_, __) => const SettingsScreen()),
              ],
            ),
          ]),
          // Tab 1 – Notifications / Alerts
          StatefulShellBranch(navigatorKey: _studentTab1NavKey, routes: [
            GoRoute(path: '/student-alerts', builder: (_, __) => const NotificationListScreen()),
          ]),
          // Tab 2 – Calendar
          StatefulShellBranch(navigatorKey: _studentTab2NavKey, routes: [
            GoRoute(path: '/student-calendar', builder: (_, __) => const CalendarScreen()),
          ]),
          // Tab 3 – Profile
          StatefulShellBranch(navigatorKey: _studentTab3NavKey, routes: [
            GoRoute(path: '/student-profile', builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // ─── Teacher Shell (4 tabs: Dashboard | Create | Scheduled | Profile) ─
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) => TeacherShell(shell: shell),
        branches: [
          // Tab 0 – Dashboard
          StatefulShellBranch(navigatorKey: _teacherTab0NavKey, routes: [
            GoRoute(path: '/teacher', builder: (_, __) => const TeacherDashboard()),
          ]),
          // Tab 1 – Create
          StatefulShellBranch(navigatorKey: _teacherTab1NavKey, routes: [
            GoRoute(
              path: '/teacher-create',
              builder: (_, __) => const CreateReminderScreen(),
              routes: [
                GoRoute(path: 'assignment', builder: (_, __) => const CreateAssignmentScreen()),
              ],
            ),
          ]),
          // Tab 2 – Scheduled
          StatefulShellBranch(navigatorKey: _teacherTab2NavKey, routes: [
            GoRoute(path: '/teacher-scheduled', builder: (_, __) => const ScheduledRemindersScreen()),
          ]),
          // Tab 3 – Profile
          StatefulShellBranch(navigatorKey: _teacherTab3NavKey, routes: [
            GoRoute(path: '/teacher-profile', builder: (_, __) => const TeacherProfileScreen()),
          ]),
        ],
      ),

      // ─── Teacher Detail Routes (Top Level for Reliability) ──────────────
      GoRoute(
        path: '/teacher-assignment/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) {
          final id = s.pathParameters['id'];
          if (id == null || id.isEmpty) return const Scaffold(body: Center(child: Text('Invalid ID')));
          return TeacherAssignmentDetailScreen(assignmentId: id);
        },
      ),
      GoRoute(
        path: '/teacher-receipts/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => ReadReceiptsScreen(reminderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin-class-analytics/:className',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => ClassAssignmentDetailScreen(className: s.pathParameters['className']!),
      ),
      GoRoute(
        path: '/admin-classes',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const ClassManagementScreen(),
      ),
      GoRoute(
        path: '/admin-student-analytics/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => StudentDetailScreen(studentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/assignment-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => AssignmentDetailScreen(assignmentId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin-teacher-analytics/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, s) => TeacherDetailScreen(teacherId: s.pathParameters['id']!),
      ),

      // ─── Admin Shell (4 tabs: Dashboard | Users | Analytics | Announce) ─
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, shell) => AdminShell(shell: shell),
        branches: [
          // Tab 0 – Dashboard
          StatefulShellBranch(navigatorKey: _adminTab0NavKey, routes: [
            GoRoute(
              path: '/admin',
              builder: (_, __) => const AdminDashboard(),
            ),
          ]),
          // Tab 1 – Users
          StatefulShellBranch(navigatorKey: _adminTab1NavKey, routes: [
            GoRoute(path: '/admin-users', builder: (_, __) => const UserManagementScreen()),
          ]),
          // Tab 2 – Analytics
          StatefulShellBranch(navigatorKey: _adminTab2NavKey, routes: [
            GoRoute(path: '/admin-analytics', builder: (_, __) => const AnalyticsScreen()),
          ]),
          // Tab 3 – Announce
          StatefulShellBranch(navigatorKey: _adminTab3NavKey, routes: [
            GoRoute(path: '/admin-announce', builder: (_, __) => const AnnouncementScreen()),
          ]),
        ],
      ),
    ],
  );
});
