import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../widgets/app_widgets.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});
  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  String _selectedCategory = 'all';
  final _categories = [
    {'id': 'all', 'label': 'All', 'icon': Icons.grid_view_rounded},
    {'id': 'announcement', 'label': 'Announcements', 'icon': Icons.campaign_outlined},
    {'id': 'reminder', 'label': 'Reminders', 'icon': Icons.notifications_outlined},
    {'id': 'event', 'label': 'Events', 'icon': Icons.event_outlined},
    {'id': 'exam', 'label': 'Exams', 'icon': Icons.assignment_outlined},
    {'id': 'timetable', 'label': 'Timetable', 'icon': Icons.calendar_today_outlined},
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final dashboardAsync = ref.watch(studentDashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _greeting(),
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontFamily: 'Inter'),
                                  ),
                                  authState.when(
                                    data: (user) => Text(user?.name ?? 'Student', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                                    loading: () => const Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 22)),
                                    error: (_, __) => const SizedBox(),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => context.go('/student-alerts'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.search_rounded, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('EEEE, d MMMM').format(DateTime.now()),
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text('CampusSync', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),

            // ─── Category Filter ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.only(top: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedCategory = cat['id'] as String),
                        label: Text(cat['label'] as String),
                        avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : AppColors.primary),
                        backgroundColor: Colors.white,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontFamily: 'Inter'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.divider)),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: const ValueKey('student_dashboard_content'),
                child: dashboardAsync.maybeWhen(
                  data: (data) => _DashboardContent(data: data, selectedCategory: _selectedCategory),
                  loading: () => dashboardAsync.hasValue 
                      ? _DashboardContent(data: dashboardAsync.value!, selectedCategory: _selectedCategory)
                      : const _DashboardSkeleton(),
                  error: (e, _) => _ErrorView(message: e.toString(), onRetry: () => ref.invalidate(studentDashboardProvider)),
                  orElse: () => const _DashboardSkeleton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }
}

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String selectedCategory;
  const _DashboardContent({required this.data, required this.selectedCategory});

  @override
  Widget build(BuildContext context) {
    final stats = data['stats'] ?? {};
    final rawReminders = (data['latestReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];
    final upcomingAssignments = (data['upcomingAssignments'] as List?)?.map((a) => AssignmentModel.fromJson(a)).toList() ?? [];
    final pinnedReminders = (data['pinnedReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];

    final latestReminders = selectedCategory == 'all' 
        ? rawReminders 
        : rawReminders.where((r) => r.category == selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Stats Row ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          child: Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.notifications_active_rounded,
                value: '${stats['unreadNotifications'] ?? 0}',
                label: 'Unread',
                color: AppColors.accent,
                onTap: () => context.go('/student-alerts'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.assignment_outlined,
                value: '${stats['pendingAssignments'] ?? 0}',
                label: 'Pending',
                color: AppColors.primary,
                onTap: () => context.push('/student/assignments'), // We'll add this route
              )),
            ],
          ),
        ),

        // ─── Pinned Notices ───────────────────────────────────────────────
        if (pinnedReminders.isNotEmpty) ...[
          _SectionHeader(title: '📌 Pinned Notices', onSeeAll: () => context.go('/student-alerts')),
          ...pinnedReminders.map((r) => _ReminderCard(reminder: r, onTap: () => context.push('/student/reminder/${r.id}'))),
        ],

        // ─── Latest Reminders ─────────────────────────────────────────────
        _SectionHeader(title: '🔔 Latest Reminders', onSeeAll: () => context.go('/student-alerts')),
        if (latestReminders.isEmpty)
          const EmptyStateWidget(icon: Icons.notifications_none, message: 'No reminders yet')
        else
          ...latestReminders.map((r) => _ReminderCard(reminder: r, onTap: () => context.push('/student/reminder/${r.id}'))),

        // ─── Upcoming Assignments ─────────────────────────────────────────
        _SectionHeader(title: '📚 Upcoming Assignments', onSeeAll: null),
        if (upcomingAssignments.isEmpty)
          const EmptyStateWidget(icon: Icons.assignment_outlined, message: 'No upcoming assignments')
        else
          ...upcomingAssignments.map((a) => _AssignmentCard(assignment: a, onTap: () => context.push('/student/assignment/${a.id}'))),

        const SizedBox(height: 80),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter')),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary)),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text('See all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  const _ReminderCard({required this.reminder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(reminder.priority);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PriorityBadge(priority: reminder.priority),
                        if (reminder.isPinned) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.accent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(reminder.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${reminder.createdBy?.name ?? 'Unknown'} • ${DateFormat('d MMM').format(reminder.createdAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'Inter')),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent': return AppColors.priorityUrgent;
      case 'important': return AppColors.priorityImportant;
      default: return AppColors.priorityNormal;
    }
  }
}

class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onTap;
  const _AssignmentCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    final urgency = daysLeft <= 1 ? AppColors.error : daysLeft <= 3 ? AppColors.warning : AppColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            border: Border.all(color: AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.assignment_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(assignment.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(assignment.subject ?? 'Assignment', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: urgency.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  daysLeft == 0 ? 'Today!' : daysLeft == 1 ? 'Tomorrow' : '$daysLeft days',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: urgency, fontFamily: 'Inter'),
                ),
              ),
              if (assignment.isCompleted)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                )
              else if (assignment.isPending)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.hourglass_empty_rounded, color: AppColors.accent, size: 16),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: List.generate(4, (i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
      ))),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(height: 60),
        const Icon(Icons.wifi_off_rounded, color: AppColors.textHint, size: 48),
        const SizedBox(height: 16),
        const Text('Unable to load dashboard', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    );
  }
}
