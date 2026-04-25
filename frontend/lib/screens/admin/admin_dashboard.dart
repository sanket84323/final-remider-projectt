import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(adminDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 150,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)])),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimens.paddingMd),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                        const Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
                        authState.whenData((u) => Text(u?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter'))).valueOrNull ?? const SizedBox(),
                        Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontFamily: 'Inter')),
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
              ],
            ),
            SliverToBoxAdapter(
              child: dashAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Padding(padding: const EdgeInsets.all(32), child: Text('Error: $e')),
                data: (data) => _AdminDashContent(data: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashContent extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AdminDashContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final stats = data['stats'] ?? {};
    final readRate = data['readRate'] ?? '0';
    final recentActivity = data['recentActivity'] as List? ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ─── KPI Grid ───────────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.all(AppDimens.paddingMd),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
          children: [
            _KpiCard(icon: Icons.people_rounded, label: 'Total Users', value: '${stats['totalUsers'] ?? 0}', color: const Color(0xFF7B1FA2)),
            _KpiCard(icon: Icons.school_rounded, label: 'Students', value: '${stats['totalStudents'] ?? 0}', color: AppColors.primary),
            _KpiCard(icon: Icons.notifications_rounded, label: 'Reminders Sent', value: '${stats['totalReminders'] ?? 0}', color: const Color(0xFF00897B)),
            _KpiCard(icon: Icons.assignment_rounded, label: 'Assignments', value: '${stats['totalAssignments'] ?? 0}', color: AppColors.accent),
          ],
        ),
      ),

      // ─── Read Rate Card ──────────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Row(children: [
            const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Notification Read Rate', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Inter')),
              Text('$readRate%', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            ]),
          ]),
        ),
      ),

      // ─── Quick Actions ───────────────────────────────────────────────────
      const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _ActionBtn(icon: Icons.person_add_rounded, label: 'Add User', color: AppColors.primary, onTap: () => context.go('/admin-users')),
            _ActionBtn(icon: Icons.campaign_rounded, label: 'Announce', color: const Color(0xFF7B1FA2), onTap: () => context.go('/admin-announce')),
            _ActionBtn(icon: Icons.bar_chart_rounded, label: 'Analytics', color: const Color(0xFF00897B), onTap: () => context.go('/admin-analytics')),
            _ActionBtn(icon: Icons.business_rounded, label: 'Dept & Classes', color: AppColors.accent, onTap: () => context.push('/admin/departments')),
          ],
        ),
      ),

      // ─── Recent Activity ─────────────────────────────────────────────────
      const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
      ...recentActivity.take(8).map((log) => _ActivityTile(log: log)),
      const SizedBox(height: 80),
    ]);
  }

  Widget _ActionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Builder(builder: (context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color, fontFamily: 'Inter')),
        ]),
      ),
    ));
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _KpiCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      border: Border.all(color: AppColors.divider),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter')),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter')),
      ]),
    ]),
  );
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> log;
  const _ActivityTile({required this.log});
  @override
  Widget build(BuildContext context) {
    final user = log['userId'] as Map?;
    return ListTile(
      leading: CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?['name'] ?? '')}&background=1565C0&color=fff&size=64'), backgroundColor: AppColors.primaryContainer),
      title: Text(log['action'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
      subtitle: Text(user?['name'] ?? 'Unknown', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
    );
  }
}
