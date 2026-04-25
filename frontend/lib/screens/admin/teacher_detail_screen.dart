import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _teacherAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await ApiService().get('/analytics/teacher/$id');
  return response.data['data'];
});

class TeacherDetailScreen extends ConsumerStatefulWidget {
  final String teacherId;
  const TeacherDetailScreen({super.key, required this.teacherId});

  @override
  ConsumerState<TeacherDetailScreen> createState() => _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends ConsumerState<TeacherDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(_teacherAnalyticsProvider(widget.teacherId));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
        data: (data) {
          final teacher = data['teacher'];
          final stats = data['stats'];
          final assignments = data['assignments'] as List? ?? [];
          final reminders = data['reminders'] as List? ?? [];
          final submissionRate = stats['overallSubmissionRate'] as int;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Header ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF1A237E),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A237E), Color(0xFF311B92), Color(0xFF512DA8)],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(teacher['name'] ?? '')}&background=311B92&color=fff&size=128'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(teacher['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '${teacher['department']['name']} • TEACHER',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Scoreboard ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _StatCircle(label: 'Reminders', value: '${stats['totalReminders']}', color: Colors.blueAccent, icon: Icons.campaign_rounded),
                        _StatCircle(label: 'Assignments', value: '${stats['totalAssignments']}', color: Colors.deepPurpleAccent, icon: Icons.assignment_rounded),
                        _StatCircle(label: 'Sub. Rate', value: '$submissionRate%', color: Colors.greenAccent.shade700, icon: Icons.trending_up_rounded),
                      ]),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'This teacher has achieved a $submissionRate% student submission rate across all posted assignments.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      ),
                    ]),
                  ),
                ),
              ),

              // ─── Tabs for Activity ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textHint,
                      indicatorColor: AppColors.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(text: 'Assignments'),
                        Tab(text: 'Reminders'),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── List Content ───────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverFillRemaining(
                  hasScrollBody: false,
                  child: [
                    // Assignments Tab
                    Column(children: assignments.map((a) => _ActivityCard(
                      title: a['title'],
                      subtitle: 'Target: ${a['targeted']} students',
                      trailing: '${a['rate']}% Sub.',
                      color: Colors.deepPurpleAccent,
                      icon: Icons.assignment_rounded,
                      onTap: () => context.push('/assignment-detail/${a['_id']}'),
                    )).toList()),
                    // Reminders Tab
                    Column(children: reminders.map((r) => _ActivityCard(
                      title: r['title'],
                      subtitle: DateFormat('MMM d, yyyy').format(DateTime.parse(r['createdAt'])),
                      trailing: r['priority'].toString().toUpperCase(),
                      color: Colors.blueAccent,
                      icon: Icons.campaign_rounded,
                      onTap: () {},
                    )).toList()),
                  ][_tabController.index],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          );
        },
      ),
    );
  }
}

class _StatCircle extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCircle({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color, fontFamily: 'Inter')),
      Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
    ]);
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ActivityCard({required this.title, required this.subtitle, required this.trailing, required this.color, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Inter')),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter')),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(trailing, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
        ),
      ),
    );
  }
}
