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
import 'package:flutter_slidable/flutter_slidable.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});
  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}
class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  String _selectedCategory = 'all';
  bool _isSelectionMode = false;
  final Set<String> _selectedReminders = {};

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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) _selectedReminders.clear();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedReminders.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected?'),
        content: Text('Delete ${_selectedReminders.length} items from your view?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in _selectedReminders) {
        await ref.read(notificationProvider.notifier).deleteNotification(id);
      }
      _toggleSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final dashboardAsync = ref.watch(studentDashboardProvider);

    return Scaffold(
      floatingActionButton: _isSelectionMode && _selectedReminders.isNotEmpty
        ? FloatingActionButton.extended(
            onPressed: _deleteSelected,
            backgroundColor: AppColors.error,
            label: Text('Delete (${_selectedReminders.length})'),
            icon: const Icon(Icons.delete_sweep_rounded),
          )
        : null,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studentDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A237E), Color(0xFF3949AB), Color(0xFF5C6BC0)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -20,
                        child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
                      ),
                      SafeArea(
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
                                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      authState.when(
                                        data: (user) => Text(
                                          user?.name ?? 'Student', 
                                          style: const TextStyle(
                                            color: Colors.white, 
                                            fontSize: 26, 
                                            fontWeight: FontWeight.w800, 
                                            fontFamily: 'Inter',
                                            letterSpacing: -0.5,
                                          )
                                        ),
                                        loading: () => const Text('Loading...', style: TextStyle(color: Colors.white, fontSize: 26)),
                                        error: (_, __) => const SizedBox(),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/student-alerts'),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12), 
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('Department Hub', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              backgroundColor: const Color(0xFF1A237E),
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
                  data: (data) => _DashboardContent(
                    data: data, 
                    selectedCategory: _selectedCategory,
                    isSelectionMode: _isSelectionMode,
                    selectedReminders: _selectedReminders,
                    onToggle: (id) => setState(() {
                      if (_selectedReminders.contains(id)) _selectedReminders.remove(id);
                      else _selectedReminders.add(id);
                    }),
                    onToggleSelection: _toggleSelectionMode,
                  ),
                  loading: () => dashboardAsync.hasValue 
                      ? _DashboardContent(
                          data: dashboardAsync.value!, 
                          selectedCategory: _selectedCategory,
                          isSelectionMode: _isSelectionMode,
                          selectedReminders: _selectedReminders,
                          onToggle: (id) => setState(() {
                            if (_selectedReminders.contains(id)) _selectedReminders.remove(id);
                            else _selectedReminders.add(id);
                          }),
                          onToggleSelection: _toggleSelectionMode,
                        )
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

class _DashboardContent extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String selectedCategory;
  final bool isSelectionMode;
  final Set<String> selectedReminders;
  final Function(String) onToggle;
  final VoidCallback onToggleSelection;

  const _DashboardContent({
    required this.data, 
    required this.selectedCategory,
    this.isSelectionMode = false,
    this.selectedReminders = const {},
    required this.onToggle,
    required this.onToggleSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = data['stats'] ?? {};
    final rawReminders = (data['latestReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];
    final upcomingAssignments = (data['upcomingAssignments'] as List?)?.map((a) => AssignmentModel.fromJson(a)).toList() ?? [];
    final pinnedReminders = (data['pinnedReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];

    final latestReminders = selectedCategory == 'all' 
        ? rawReminders 
        : rawReminders.where((r) => r.category == selectedCategory).toList();

    final unreadReminders = rawReminders.where((r) => !r.isRead).take(3).toList();
    final pendingAssignments = upcomingAssignments.where((a) => !a.isCompleted && !a.isPending).take(3).toList();

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
                label: 'Unread Reminders',
                color: AppColors.accent,
                onTap: () => context.go('/student-alerts'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                icon: Icons.assignment_outlined,
                value: '${stats['pendingAssignments'] ?? 0}',
                label: 'Pending Assignment',
                color: AppColors.primary,
                onTap: () => context.push('/student/assignments'),
              )),
            ],
          ),
        ),

        // ─── Pinned Notices ───────────────────────────────────────────────
        if (pinnedReminders.isNotEmpty) ...[
          _SectionHeader(title: '📌 Pinned Notices', onSeeAll: () => context.go('/student-alerts')),
          ...pinnedReminders.map((r) => Slidable(
            key: ValueKey('pinned_${r.id}'),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) {
                    if (r.notificationId != null) {
                      ref.read(notificationProvider.notifier).deleteNotification(r.notificationId!);
                    }
                  },
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                ),
              ],
            ),
            child: _ReminderCard(
              reminder: r, 
              isSelected: selectedReminders.contains(r.notificationId),
              isSelectionMode: isSelectionMode,
              onSelect: () => onToggle(r.notificationId!),
              onTap: () {
                if (isSelectionMode) {
                  onToggle(r.notificationId!);
                } else {
                  context.push('/student/reminder/${r.id}');
                }
              }
            ),
          )),
        ],

        // ─── Latest Reminders ─────────────────────────────────────────────
        _SectionHeader(
          title: '🔔 Latest Reminders', 
          onSeeAll: () => context.go('/student-alerts'),
          trailing: TextButton.icon(
            onPressed: onToggleSelection,
            icon: Icon(isSelectionMode ? Icons.done_all_rounded : Icons.checklist_rounded, size: 16),
            label: Text(isSelectionMode ? 'Done' : 'Select', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        if (latestReminders.isEmpty)
          const EmptyStateWidget(icon: Icons.notifications_none, message: 'No reminders yet')
        else
          ...latestReminders.map((r) => Slidable(
            key: ValueKey(r.id),
            enabled: !isSelectionMode,
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) {
                    if (r.notificationId != null) {
                      ref.read(notificationProvider.notifier).deleteNotification(r.notificationId!);
                    }
                  },
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                ),
              ],
            ),
            child: _ReminderCard(
              reminder: r, 
              isSelected: selectedReminders.contains(r.notificationId),
              isSelectionMode: isSelectionMode,
              onSelect: () => onToggle(r.notificationId!),
              onTap: () {
                if (isSelectionMode) {
                  onToggle(r.notificationId!);
                } else {
                  context.push('/student/reminder/${r.id}');
                }
              }
            ),
          )),

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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2), 
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter', letterSpacing: -0.5)),
                Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontFamily: 'Inter', fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.onSeeAll, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary)),
          Row(
            children: [
              if (trailing != null) ...[
                trailing!,
                if (onSeeAll != null) const SizedBox(width: 12),
              ],
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: const Text('See all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelect;

  const _ReminderCard({
    required this.reminder, 
    required this.onTap,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(reminder.priority);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.05),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected, 
                  onChanged: (_) => onSelect?.call(),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 6,
                height: 50,
                decoration: BoxDecoration(
                  color: priorityColor, 
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [BoxShadow(color: priorityColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ModernPriorityBadge(priority: reminder.priority),
                        const Spacer(),
                        if (reminder.isPinned)
                          const Icon(Icons.push_pin_rounded, size: 16, color: Color(0xFFFFA000)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reminder.title, 
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w700, 
                        fontFamily: 'Inter', 
                        color: Color(0xFF1A1F36),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: Colors.black.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          reminder.createdBy?.name ?? 'Admin',
                          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5), fontFamily: 'Inter', fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.black.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('d MMM').format(reminder.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5), fontFamily: 'Inter', fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode) 
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent': return const Color(0xFFE53935);
      case 'important': return const Color(0xFFFB8C00);
      default: return const Color(0xFF43A047);
    }
  }
}

class _ModernPriorityBadge extends StatelessWidget {
  final String priority;
  const _ModernPriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, fontFamily: 'Inter'),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'urgent': return const Color(0xFFE53935);
      case 'important': return const Color(0xFFFB8C00);
      default: return const Color(0xFF43A047);
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
