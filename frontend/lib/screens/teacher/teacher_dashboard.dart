import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../widgets/app_widgets.dart';

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {

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
              expandedHeight: 180,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF1A237E),
              title: const Text('Faculty Command Center', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () => context.push('/teacher-profile'),
                ),
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
                      colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF4527A0)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -10,
                        child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.04)),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.paddingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Academic Session 2026-27', 
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600, letterSpacing: 1),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  authState.whenData((user) => Text(
                                    user?.name ?? 'Faculty Member', 
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 26, 
                                      fontWeight: FontWeight.w800, 
                                      fontFamily: 'Inter',
                                      letterSpacing: -0.5,
                                    )
                                  )).valueOrNull ?? const SizedBox(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      DateFormat('d MMM').format(DateTime.now()), 
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w700)
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: dashboardAsync.maybeWhen(
                data: (data) => _TeacherDashboardContent(data: data),
                loading: () => dashboardAsync.hasValue 
                    ? _TeacherDashboardContent(data: dashboardAsync.value!)
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

class _TeacherDashboardContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const _TeacherDashboardContent({required this.data});

  @override
  ConsumerState<_TeacherDashboardContent> createState() => _TeacherDashboardContentState();
}

class _TeacherDashboardContentState extends ConsumerState<_TeacherDashboardContent> {
  String _scheduledSearch = '';
  String _sentSearch = '';
  String _assignmentSearch = '';

  bool _isSearchingScheduled = false;
  bool _isSearchingSent = false;
  bool _isSearchingAssignments = false;
  bool _isSearchingHistory = false;
  String _historySearch = '';

  Future<void> _confirmDelete(BuildContext context, String type, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this $type? This action cannot be undone.', style: const TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (type == 'reminder') {
          await ReminderRepository().deleteReminder(id);
        } else {
          await AssignmentRepository().deleteAssignment(id);
        }
        ref.invalidate(teacherDashboardProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Post deleted successfully'), backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final stats = widget.data['stats'] ?? {};
      final allAssignments = (widget.data['assignments'] as List?)?.map((a) => AssignmentModel.fromJson(a)).toList() ?? [];
      final allReminders = (widget.data['recentReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];
      final allScheduled = (widget.data['scheduledReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];

      final assignments = allAssignments.where((a) => a.title.toLowerCase().contains(_assignmentSearch.toLowerCase())).toList();
      final recentReminders = allReminders.where((r) => r.title.toLowerCase().contains(_sentSearch.toLowerCase())).toList();
      final scheduledReminders = allScheduled.where((r) => r.title.toLowerCase().contains(_scheduledSearch.toLowerCase())).toList();

      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 1024;

          final statsCrossCount = isMobile ? 2 : (isTablet ? 3 : 3);
          final actionCrossCount = isMobile ? 2 : (isTablet ? 2 : 2);
          
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ─── Stats Row ───────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppDimens.paddingMd),
                  child: GridView.count(
                    crossAxisCount: statsCrossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.2 : 1.6,
                    children: [
                      _StatCard(value: '${stats['totalReminders'] ?? 0}', label: 'Notices', icon: Icons.send_rounded, color: const Color(0xFF00897B)),
                      _StatCard(value: '${allAssignments.length}', label: 'Assignments', icon: Icons.assignment_rounded, color: AppColors.primary),
                      _StatCard(value: '${stats['scheduledCount'] ?? 0}', label: 'Scheduled', icon: Icons.schedule_rounded, color: AppColors.accent),
                    ],
                  ),
                ),

                // ─── Quick Actions ───────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: actionCrossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isMobile ? 1.8 : 3.0,
                    children: [
                      _QuickAction(icon: Icons.notifications_active_rounded, label: 'New Notice', color: AppColors.primary, onTap: () => context.go('/teacher-create')),
                      _QuickAction(icon: Icons.assignment_add, label: 'New Task', color: AppColors.accent, onTap: () => context.go('/teacher-create/assignment')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Scheduled Notices ────────────────────────────────────────────────
                if (allScheduled.isNotEmpty) ...[
                  _SectionHeader(
                    title: '📅 Scheduled Notices', 
                    onSearch: () => setState(() => _isSearchingScheduled = !_isSearchingScheduled),
                  ),
                  if (_isSearchingScheduled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _scheduledSearch = v),
                        decoration: InputDecoration(
                          hintText: 'Search scheduled...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  
                  if (scheduledReminders.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text('No matching scheduled notices', style: TextStyle(color: AppColors.textHint)))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : 2,
                        childAspectRatio: isMobile ? 4.5 : 5.0,
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: scheduledReminders.length,
                      itemBuilder: (ctx, i) => _ReminderRow(reminder: scheduledReminders[i], onTap: () => {}),
                    ),
                ],

                // ─── Recent Sent Notices ────────────────────────────────────────────────
                _SectionHeader(
                  title: 'Recent Sent Notices', 
                  action: 'View all', 
                  onAction: () => context.go('/teacher-scheduled'),
                  onSearch: () => setState(() => _isSearchingSent = !_isSearchingSent),
                ),
                if (_isSearchingSent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _sentSearch = v),
                      decoration: InputDecoration(
                        hintText: 'Search sent notices...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (recentReminders.isEmpty)
                  const EmptyStateWidget(icon: Icons.notifications_none, message: 'No reminders found')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : 2,
                      childAspectRatio: isMobile ? 4.5 : 5.0,
                      mainAxisSpacing: 0,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: recentReminders.length,
                    itemBuilder: (ctx, i) => _ReminderRow(
                      reminder: recentReminders[i], 
                      onTap: () => context.push('/teacher-receipts/${recentReminders[i].id}'),
                    ),
                  ),

                // ─── Content Management ──────────────────────────────────────────────
                _SectionHeader(
                  title: '🗂️ Manage Your Posts',
                  onSearch: () => setState(() => _isSearchingHistory = !_isSearchingHistory),
                ),
                if (_isSearchingHistory)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      onChanged: (v) => setState(() => _historySearch = v),
                      decoration: InputDecoration(
                        hintText: 'Search history...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                
                // Combine and filter for the dashboard view
                () {
                  final List<dynamic> history = [...allReminders, ...allAssignments];
                  final filteredHistory = history.where((item) {
                    if (item == null) return false;
                    final String title = item is ReminderModel ? item.title : (item is AssignmentModel ? item.title : '');
                    return title.toLowerCase().contains(_historySearch.toLowerCase());
                  }).toList();

                  if (history.isEmpty) {
                    return const EmptyStateWidget(icon: Icons.inventory_2_outlined, message: 'No posts yet');
                  }

                  if (filteredHistory.isEmpty && _historySearch.isNotEmpty) {
                    return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No matching posts found')));
                  }

                  return Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredHistory.length.clamp(0, 5),
                        itemBuilder: (ctx, i) {
                          final item = filteredHistory[i];
                          if (item is ReminderModel) {
                            return _ManagementRow(
                              title: item.title,
                              subtitle: 'Notice • ${DateFormat('d MMM').format(item.createdAt)}',
                              icon: Icons.campaign_rounded,
                              color: AppColors.primary,
                              onView: () => context.push('/teacher-receipts/${item.id}'),
                              onEdit: () => context.push('/teacher-edit-reminder/${item.id}'),
                              onDelete: () => _confirmDelete(context, 'reminder', item.id),
                            );
                          } else {
                            final a = item as AssignmentModel;
                            return _ManagementRow(
                              title: a.title,
                              subtitle: 'Assignment • Due ${DateFormat('d MMM').format(a.dueDate)}',
                              icon: Icons.assignment_rounded,
                              color: AppColors.accent,
                              onView: () => context.push('/teacher-assignment/${a.id}'),
                              onEdit: () => context.push('/teacher-edit-assignment/${a.id}'),
                              onDelete: () => _confirmDelete(context, 'assignment', a.id),
                            );
                          }
                        },
                      ),
                      if (filteredHistory.length > 5)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => context.push('/teacher-manage-all'),
                              child: const Text('See More Posts', style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                            ),
                          ),
                        ),
                    ],
                  );
                }(),

                const SizedBox(height: 80),
              ]),
            ),
          );
        },
      );
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
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(20), 
      border: Border.all(color: color.withOpacity(0.1)),
      boxShadow: [BoxShadow(color: color.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter', letterSpacing: -0.5)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'Inter', fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        ),
      ],
    ),
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
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter')),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback? onSearch;
  const _SectionHeader({required this.title, this.action, this.onAction, this.onSearch});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary)),
      Row(
        children: [
          if (onSearch != null)
            IconButton(
              icon: const Icon(Icons.search, size: 20, color: AppColors.primary),
              onPressed: onSearch,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (action != null) ...[
            const SizedBox(width: 12),
            GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500))),
          ],
        ],
      ),
    ]),
  );
}

class _ManagementRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManagementRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'Inter')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                onPressed: onView,
                tooltip: 'View',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                onPressed: onEdit,
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: onDelete,
                tooltip: 'Delete',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback onTap;
  const _ReminderRow({required this.reminder, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          _ModernPriorityBadge(priority: reminder.priority),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reminder.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 10, color: Colors.black.withOpacity(0.4)),
                const SizedBox(width: 4),
                Text(DateFormat('d MMM, h:mm a').format(reminder.createdAt), style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.4), fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              ],
            ),
          ])),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/teacher-receipts/${reminder.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1).withOpacity(0.08), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0D47A1).withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 12, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 4),
                  Text('Insights', style: TextStyle(fontSize: 11, color: Color(0xFF0D47A1), fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                ],
              ),
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
