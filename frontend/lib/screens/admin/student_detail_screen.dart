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
      backgroundColor: const Color(0xFFF8F9FE),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Scaffold(
          appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => context.pop())),
          body: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ],
          )),
        ),
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
              // ─── Premium Glassmorphic Header ───────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0D47A1),
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                  onPressed: () => context.pop(),
                ),
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
                            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1E88E5)],
                          ),
                        ),
                      ),
                      Positioned(top: -50, right: -50, child: CircleAvatar(radius: 120, backgroundColor: Colors.white.withOpacity(0.05))),
                      Positioned(bottom: -30, left: -20, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.03))),
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'avatar_${student['_id']}',
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                                ),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(student['name'] ?? '')}&background=1565C0&color=fff&size=256'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(student['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
                              child: Text(student['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Scoreboard Highlights ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Row(children: [
                    Expanded(child: _ScoreCard(title: 'Engagement', score: readRate, icon: Icons.bolt_rounded, color: const Color(0xFF673AB7))),
                    const SizedBox(width: 16),
                    Expanded(child: _ScoreCard(title: 'Consistency', score: submissionRate, icon: Icons.auto_awesome_rounded, color: const Color(0xFF00BFA5))),
                  ]),
                ),
              ),

              // ─── Detailed Info Grid ──────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Student Identity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _InfoTile(label: 'CLASS', value: student['className'] ?? 'N/A', icon: Icons.class_rounded, color: Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _InfoTile(label: 'ROLL NO', value: student['rollNumber'] ?? 'N/A', icon: Icons.badge_rounded, color: Colors.orange)),
                    ]),
                    const SizedBox(height: 12),
                    _InfoTile(
                      label: 'DEPARTMENT', 
                      value: student['department']?['name'] ?? 'General', 
                      icon: Icons.account_balance_rounded, 
                      color: Colors.purple,
                      fullWidth: true,
                    ),
                  ]),
                ),
              ),

              // ─── Learning Journey Header ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Learning Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: AppColors.textPrimary)),
                      Text('Assignments & Submissions', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500)),
                    ]),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('${assignments.length} Total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                  ]),
                ),
              ),

              // ─── Modern Assignment List ──────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: assignments.isEmpty 
                  ? const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No assignments tracked yet', style: TextStyle(color: AppColors.textHint)))))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final a = assignments[index];
                          final status = a['status'] as String;
                          final dueDate = DateTime.parse(a['dueDate']);
                          
                          Color statusColor;
                          String statusLabel;
                          if (status == 'approved') { 
                            statusColor = const Color(0xFF00C853); 
                            statusLabel = 'APPROVED';
                          } else if (status == 'submitted') { 
                            statusColor = const Color(0xFFFFAB00); 
                            statusLabel = 'PENDING REVIEW';
                          } else { 
                            statusColor = const Color(0xFFFF1744); 
                            statusLabel = 'MISSING';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                              border: Border.all(color: Colors.black.withOpacity(0.02)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 45, height: 45,
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                child: Icon(status == 'approved' ? Icons.task_alt_rounded : status == 'submitted' ? Icons.history_edu_rounded : Icons.warning_amber_rounded, color: statusColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(a['title'] ?? 'Assignment', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2D3436))),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.person_outline_rounded, size: 12, color: Colors.black.withOpacity(0.4)),
                                    const SizedBox(width: 4),
                                    Text(a['teacher'] ?? 'Unknown Teacher', style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500)),
                                  ]),
                                ]),
                              ),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                                const SizedBox(height: 4),
                                Text(DateFormat('MMM d').format(dueDate), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF636E72))),
                              ]),
                            ]),
                          );
                        },
                        childCount: assignments.length,
                      ),
                    ),
              ),

              // ─── Intelligence Card ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A237E), Color(0xFF311B92)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
                    ),
                    child: Column(children: [
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.psychology_rounded, color: Colors.white, size: 30),
                        const SizedBox(width: 12),
                        const Text('AI Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
                      ]),
                      const SizedBox(height: 20),
                      Text(
                        'This student maintains a ${submissionRate}% completion rate. Their current status is ${submissionRate >= 80 ? 'EXEMPLARY' : submissionRate >= 50 ? 'SATISFACTORY' : 'REQUIRES INTERVENTION'}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.6, fontWeight: FontWeight.w400, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 24),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _StatBox(label: 'Alerts Seen', value: '${stats['readNotifications']}', color: Colors.cyanAccent),
                        _StatBox(label: 'Success Rate', value: '$submissionRate%', color: Colors.greenAccent),
                        _StatBox(label: 'Pending', value: '${stats['pending']}', color: Colors.orangeAccent),
                      ]),
                    ]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 50)),
            ],
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final IconData icon;
  final Color color;
  const _ScoreCard({required this.title, required this.score, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 75, height: 75,
            child: CircularProgressIndicator(
              value: score / 100, 
              strokeWidth: 8, 
              backgroundColor: color.withOpacity(0.08), 
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Icon(icon, color: color, size: 30),
        ]),
        const SizedBox(height: 16),
        Text('$score%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, fontFamily: 'Inter')),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ]),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool fullWidth;
  const _InfoTile({required this.label, required this.value, required this.icon, required this.color, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 1.0)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2D3436))),
          ]),
        ),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    ]);
  }
}
