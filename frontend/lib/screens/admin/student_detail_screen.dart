import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _studentAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await ApiService().get('/analytics/student/$id');
  return response.data['data'];
});

class StudentDetailScreen extends ConsumerWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_studentAnalyticsProvider(studentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
        data: (data) {
          final student = data['student'];
          final stats = data['stats'];
          final assignments = data['assignments'] as List? ?? [];
          final readRate = stats['readRate'] as int;
          final submissionRate = stats['totalAssignments'] > 0 
              ? (stats['submitted'] / stats['totalAssignments'] * 100).round() 
              : 0;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Premium Animated Header ───────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0D47A1),
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
                            colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0, left: 0, right: 0, height: 100,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Hero(
                            tag: 'avatar_${student['_id']}',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(student['name'] ?? '')}&background=1565C0&color=fff&size=128'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(student['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '${student['className']} • ROLL: ${student['rollNumber'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
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
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(children: [
                    Expanded(child: _CircularScoreCard(title: 'Engagement', score: readRate, color: const Color(0xFF7B1FA2), icon: Icons.bolt_rounded)),
                    const SizedBox(width: 16),
                    Expanded(child: _CircularScoreCard(title: 'Submissions', score: submissionRate, color: const Color(0xFF00897B), icon: Icons.auto_awesome_rounded)),
                  ]),
                ),
              ),

              // ─── Stats Grid ──────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.count(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.5,
                  children: [
                    _CompactStat(label: 'Reminders Read', value: '${stats['readNotifications']}', icon: Icons.done_all_rounded, color: Colors.blueGrey),
                    _CompactStat(label: 'Pending Tasks', value: '${stats['pending']}', icon: Icons.pending_actions_rounded, color: Colors.orange),
                  ],
                ),
              ),

              // ─── Learning Journey Header ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Learning Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: AppColors.textPrimary)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('${assignments.length} Total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ]),
                ),
              ),

              // ─── Assignment List ─────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final a = assignments[index];
                      final status = a['status'] as String;
                      final dueDate = DateTime.parse(a['dueDate']);
                      
                      Color statusColor;
                      IconData statusIcon;
                      String statusLabel;
                      if (status == 'approved') { 
                        statusColor = AppColors.success; 
                        statusIcon = Icons.check_circle_rounded;
                        statusLabel = 'SUBMITTED';
                      } else if (status == 'submitted') { 
                        statusColor = Colors.amber.shade700; 
                        statusIcon = Icons.stars_rounded;
                        statusLabel = 'UNDER REVIEW';
                      } else { 
                        statusColor = AppColors.error; 
                        statusIcon = Icons.info_outline_rounded;
                        statusLabel = 'PENDING';
                      }

                      return InkWell(
                        onTap: () => context.push('/assignment-detail/${a['_id']}'),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            child: IntrinsicHeight(
                              child: Row(children: [
                                Container(width: 6, color: statusColor),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter')),
                                        const SizedBox(height: 6),
                                        Row(children: [
                                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
                                          const SizedBox(width: 4),
                                          Text(DateFormat('MMM d, h:mm a').format(dueDate), style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter')),
                                        ]),
                                      ])),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Icon(statusIcon, color: statusColor, size: 20),
                                        const SizedBox(height: 4),
                                        Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                      ]),
                                    ]),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: assignments.length,
                  ),
                ),
              ),

              // ─── Intelligence Card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0D47A1)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF0D47A1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(children: [
                      const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 32),
                      const SizedBox(height: 16),
                      const Text('Performance Intelligence', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Text(
                        'Based on recent activity, this student is ${submissionRate >= 80 ? 'EXCELLING' : submissionRate >= 50 ? 'STABLE' : 'AT RISK'} in their academic submissions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _MinimalIndicator(label: 'Engagement', value: '$readRate%', color: Colors.purpleAccent),
                        _MinimalIndicator(label: 'Completion', value: '$submissionRate%', color: Colors.greenAccent),
                      ]),
                    ]),
                  ),
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

class _CircularScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final Color color;
  final IconData icon;
  const _CircularScoreCard({required this.title, required this.score, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 70, height: 70, child: CircularProgressIndicator(value: score / 100, strokeWidth: 8, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color))),
          Icon(icon, color: color, size: 28),
        ]),
        const SizedBox(height: 16),
        Text('$score%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, fontFamily: 'Inter')),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ]),
    );
  }
}

class _CompactStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _CompactStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textHint, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        ]),
      ]),
    );
  }
}

class _MinimalIndicator extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MinimalIndicator({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
    ]);
  }
}
