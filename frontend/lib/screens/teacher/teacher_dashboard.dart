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

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final dashboardAsync = ref.watch(teacherDashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(teacherDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF004D40), Color(0xFF00897B)])),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingMd),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                        const Text('Teacher Portal', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            authState.whenData((user) => Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter'))).valueOrNull ?? const SizedBox(),
                            Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'Inter')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: TextField(
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search notices or assignments...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                              prefixIcon: Icon(Icons.search, color: Colors.white54, size: 20),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
                IconButton(
                  onPressed: () => context.go('/teacher-create'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: dashboardAsync.maybeWhen(
                data: (data) => _TeacherDashboardContent(data: data, search: _searchQuery),
                loading: () => dashboardAsync.hasValue 
                    ? _TeacherDashboardContent(data: dashboardAsync.value!, search: _searchQuery)
                    : const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e'))),
                orElse: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/teacher-create'),
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Reminder', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _TeacherDashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String search;
  const _TeacherDashboardContent({required this.data, required this.search});

  @override
  Widget build(BuildContext context) {
    try {
      final stats = data['stats'] ?? {};
      final allAssignments = (data['assignments'] as List?)?.map((a) => AssignmentModel.fromJson(a)).toList() ?? [];
      final allReminders = (data['recentReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];
      final allScheduled = (data['scheduledReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];

      final assignments = allAssignments.where((a) => a.title.toLowerCase().contains(search.toLowerCase())).toList();
      final recentReminders = allReminders.where((r) => r.title.toLowerCase().contains(search.toLowerCase())).toList();
      final scheduledReminders = allScheduled.where((r) => r.title.toLowerCase().contains(search.toLowerCase())).toList();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ─── Stats Row ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          child: Row(children: [
            Expanded(child: _StatCard(value: '${stats['totalReminders'] ?? 0}', label: 'Notices', icon: Icons.send_rounded, color: const Color(0xFF00897B))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '${assignments.length}', label: 'Assignments', icon: Icons.assignment_rounded, color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '${stats['scheduledCount'] ?? 0}', label: 'Scheduled', icon: Icons.schedule_rounded, color: AppColors.accent)),
          ]),
        ),

        // ─── Quick Actions ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Expanded(child: _QuickAction(icon: Icons.notifications_active_rounded, label: 'New Notice', color: AppColors.primary, onTap: () => context.go('/teacher-create'))),
            const SizedBox(width: 12),
            Expanded(child: _QuickAction(icon: Icons.assignment_add, label: 'New Task', color: AppColors.accent, onTap: () => context.go('/teacher-create/assignment'))),
          ]),
        ),
        const SizedBox(height: 8),

        // ─── Scheduled Notices ────────────────────────────────────────────────
        if (scheduledReminders.isNotEmpty) ...[
          _SectionHeader(title: '📅 Scheduled Notices', action: null, onAction: null),
          ...scheduledReminders.map((r) => _ReminderRow(
            reminder: r, 
            onTap: () => {}, // No receipts for future notices yet
          )),
        ],

        // ─── Recent Sent Notices ────────────────────────────────────────────────
        _SectionHeader(title: 'Recent Sent Notices', action: 'View all', onAction: () => context.go('/teacher-scheduled')),
        if (recentReminders.isEmpty)
          const EmptyStateWidget(icon: Icons.notifications_none, message: 'No reminders sent yet')
        else
          ...recentReminders.map((r) => _ReminderRow(
            reminder: r, 
            onTap: () => context.push('/teacher-receipts/${r.id}'),
          )),

        // ─── Assignments ──────────────────────────────────────────────
        _SectionHeader(title: 'Active Assignments', action: null, onAction: null),
        if (assignments.isEmpty)
          const EmptyStateWidget(icon: Icons.event_available, message: 'No assignments created yet')
        else
          ...assignments.map((a) => _DeadlineRow(
            assignment: a, 
            onTap: () {
              final path = '/teacher-assignment/${a.id}';
              context.push(path);
            },
          )),

        const SizedBox(height: 80),
      ]);
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.bug_report, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Dashboard failed to render: $e', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter')),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter'), textAlign: TextAlign.center),
    ]),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: AppColors.divider), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
        Icon(Icons.arrow_forward_rounded, color: color, size: 16),
      ]),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary)),
      if (action != null)
        GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500))),
    ]),
  );
}

class _ReminderRow extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  const _ReminderRow({required this.reminder, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: AppColors.divider)),
        child: Row(children: [
          PriorityBadge(priority: reminder.priority),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(DateFormat('d MMM · h:mm a').format(reminder.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter')),
          ])),
          GestureDetector(
            onTap: () => context.push('/teacher-receipts/${reminder.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(20)),
              child: const Text('Receipts', style: TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _DeadlineRow extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onTap;
  const _DeadlineRow({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysLeft = assignment.dueDate.difference(DateTime.now()).inDays;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: AppColors.divider)),
          child: Row(children: [
            const Icon(Icons.assignment_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(assignment.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${assignment.completedCount} completed · ${assignment.subject ?? ''}', style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter')),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (daysLeft <= 1 ? AppColors.error : AppColors.success).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(daysLeft < 0 ? 'Ended' : daysLeft == 0 ? 'Today' : '$daysLeft days', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: daysLeft <= 1 ? AppColors.error : AppColors.success, fontFamily: 'Inter')),
            ),
          ]),
        ),
      ),
    );
  }
}
