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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final isTablet = width >= 600 && width < 1024;
        
        final kpiCrossCount = isMobile ? 2 : (width < 900 ? 2 : 4);
        final kpiRatio = isMobile ? 1.4 : (isTablet ? 1.8 : 2.0);
        
        final actionCrossCount = isMobile ? 2 : (isTablet ? 2 : 4);
        final actionRatio = isMobile ? 2.0 : 2.5;

        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 32),

              // ─── Announcements Card (Clickable) ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: () => context.push('/admin-manage-announcements'),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00897B), Color(0xFF00695C)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: const Color(0xFF00897B).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 12))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(22)),
                        child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 24),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('COMMUNICATION CENTER', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 6),
                        Text('${stats['globalStats']?['totalReminders'] ?? 0} Active Broadcasts', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                      ])),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                    ]),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Overall Engagement (Non-Clickable) ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF673AB7).withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.auto_graph_rounded, color: Color(0xFF673AB7), size: 32),
                    ),
                    const SizedBox(height: 20),
                    const Text('DEPARTMENT READ RATE', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Text(
                      '${stats['globalStats']?['readRate'] ?? 0}%', 
                      style: const TextStyle(color: Color(0xFF1A237E), fontSize: 56, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -2)
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _getEngagementMessage(stats['globalStats']?['readRate'] ?? 0),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)
                      ),
                    ),
                  ]),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Quick Actions ───────────────────────────────────────────────────
              const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: actionCrossCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: actionRatio,
                  children: [
                    _ActionBtn(icon: Icons.manage_accounts_rounded, label: 'Management', color: AppColors.primary, onTap: () => context.push('/admin-users')),
                    _ActionBtn(icon: Icons.campaign_rounded, label: 'Announce', color: const Color(0xFF7B1FA2), onTap: () => context.push('/admin-announce')),
                    _ActionBtn(icon: Icons.bar_chart_rounded, label: 'Analytics', color: const Color(0xFF00897B), onTap: () => context.push('/admin-analytics')),
                    _ActionBtn(icon: Icons.class_rounded, label: 'Manage Classes', color: AppColors.accent, onTap: () => context.push('/admin-classes')),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ]),
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _KpiCard({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), 
              child: FittedBox(child: Icon(icon, color: color, size: 42)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, fontFamily: 'Inter', letterSpacing: -1.0))),
                FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.6), fontFamily: 'Inter', fontWeight: FontWeight.w800, letterSpacing: 0.1))),
              ],
            ),
          ),
        ],
      ),
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
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Flexible(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: FittedBox(child: Icon(icon, color: color, size: 48)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter')),
              ),
            ),
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

class _InsightStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _InsightStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Column(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(height: 8),
    Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
    Text(label.toUpperCase(), style: TextStyle(color: Colors.black26, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
  ]);
}

String _getEngagementMessage(int rate) {
  if (rate <= 30) return 'Communication needs attention. Try sending reminders for important notices.';
  if (rate <= 60) return 'Steady engagement. Your announcements are reaching a good portion of students.';
  if (rate <= 85) return 'Great job! The department is highly responsive to your broadcasts.';
  return 'Outstanding! Your communication strategy is world-class.';
}
