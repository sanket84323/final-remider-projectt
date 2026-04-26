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
              expandedHeight: 200,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF311B92),
              title: const Text('HOD Executive Portal', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 18)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () => context.push('/student/settings'),
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
                      colors: [Color(0xFF311B92), Color(0xFF4527A0), Color(0xFF512DA8)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40,
                        top: -20,
                        child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05)),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(AppDimens.paddingMd),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, 
                            mainAxisAlignment: MainAxisAlignment.end, 
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('DEPARTMENT HEAD', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Inter')),
                              ),
                              const SizedBox(height: 8),
                              const Text('Dr. Bhagyashree Dhakulkar', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: -0.5)),
                              const Text('Artificial Intelligence and Data Science', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E88E5), Color(0xFF1976D2)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1976D2).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text('Engagement Rate', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$readRate', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                      const Text('%', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
            _ActionBtn(icon: Icons.manage_accounts_rounded, label: 'Management', color: AppColors.primary, onTap: () => context.push('/admin-users')),
            _ActionBtn(icon: Icons.campaign_rounded, label: 'Announce', color: const Color(0xFF7B1FA2), onTap: () => context.push('/admin-announce')),
            _ActionBtn(icon: Icons.bar_chart_rounded, label: 'Analytics', color: const Color(0xFF00897B), onTap: () => context.push('/admin-analytics')),
            _ActionBtn(icon: Icons.class_rounded, label: 'Manage Classes', color: AppColors.accent, onTap: () => context.push('/admin-classes')),
          ],
        ),
      ),

      const SizedBox(height: 80),
    ]);
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
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.08)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10), 
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), 
          child: Icon(icon, color: color, size: 28)
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter', letterSpacing: -0.5)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.5), fontFamily: 'Inter', fontWeight: FontWeight.w700, letterSpacing: 0.2)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: color.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter'))),
            Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.3), size: 12),
          ],
        ),
      ),
    );
  }
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
