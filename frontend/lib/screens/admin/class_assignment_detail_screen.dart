import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _classAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, className) async {
  final response = await ApiService().get('/analytics/class/${Uri.encodeComponent(className)}');
  return response.data['data'];
});

class ClassAssignmentDetailScreen extends ConsumerWidget {
  final String className;
  final String? initialTab;
  const ClassAssignmentDetailScreen({super.key, required this.className, this.initialTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_classAnalyticsProvider(className));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final students = data['students'] as List;
          final assignments = data['assignments'] as List;
          
          double totalProgress = 0.0;
          for (var s in students) {
            final double t = (s['total'] as num?)?.toDouble() ?? 0.0;
            final double sb = (s['submitted'] as num?)?.toDouble() ?? 0.0;
            if (t > 0) totalProgress += (sb / t);
          }
          final double avgProgress = students.isEmpty ? 0.0 : totalProgress / students.length;

          return DefaultTabController(
            length: 2,
            initialIndex: initialTab == 'assignments' ? 1 : 0,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 240,
                  pinned: true,
                  stretch: true,
                  backgroundColor: const Color(0xFF1A237E),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                        ),
                      ),
                      child: Stack(children: [
                        Positioned(right: -30, top: -20, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withOpacity(0.05))),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text(className.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              ),
                              const SizedBox(height: 12),
                              const Text('Class Analytics', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5)),
                              const SizedBox(height: 16),
                              Row(children: [
                                _HeaderStat(label: 'Students', value: '${students.length}'),
                                const SizedBox(width: 24),
                                _HeaderStat(label: 'Avg. Progress', value: '${(avgProgress * 100).toStringAsFixed(0)}%'),
                              ]),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                      child: const TabBar(
                        tabs: [Tab(text: 'Student Roster'), Tab(text: 'Assignments')],
                        labelColor: Color(0xFF1A237E),
                        unselectedLabelColor: Colors.black26,
                        indicatorColor: Color(0xFF1A237E),
                        indicatorWeight: 3,
                        labelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, fontFamily: 'Inter'),
                      ),
                    ),
                  ),
                ),
              ],
              body: TabBarView(children: [
                // ─── Student Roster View ──────────────────────────────────
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  itemCount: students.length,
                  itemBuilder: (ctx, i) => _StudentStatusCard(
                    s: students[i], 
                    allAssignments: assignments,
                    className: className,
                  ),
                ),

                // ─── Assignments View ─────────────────────────────────────
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  itemCount: assignments.length,
                  itemBuilder: (ctx, i) {
                    final a = assignments[i];
                    return InkWell(
                      onTap: () => context.push('/assignment-detail/${a['_id']}'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.assignment_outlined, color: Color(0xFF1A237E), size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF2D3436))),
                            Text('By ${a['createdBy']['name']} • Due ${a['dueDate'].toString().substring(0, 10)}', style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.4))),
                          ])),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.black12),
                        ]),
                      ),
                    );
                  },
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500)),
  ]);
}

class _StudentStatusCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> s;
  final List<dynamic> allAssignments;
  final String className;
  const _StudentStatusCard({required this.s, required this.allAssignments, required this.className});

  @override
  ConsumerState<_StudentStatusCard> createState() => _StudentStatusCardState();
}

class _StudentStatusCardState extends ConsumerState<_StudentStatusCard> {
  bool _isApproving = false;

  Future<void> _approveSubmission(String assignmentId) async {
    setState(() => _isApproving = true);
    try {
      await ApiService().post('/assignments/mark-student-complete', data: {
        'assignmentId': assignmentId,
        'studentId': widget.s['id'],
        'status': 'completed'
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submission approved successfully!'), backgroundColor: AppColors.success));
        ref.invalidate(_classAnalyticsProvider(widget.className));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.s['total'] > 0 ? widget.s['submitted'] / widget.s['total'] : 0;
    final List<String> submittedIds = List<String>.from(widget.s['submittedIds'] ?? []);
    final List<String> approvedIds = List<String>.from(widget.s['approvedIds'] ?? []);
    final Color color = progress >= 1.0 ? AppColors.success : progress >= 0.5 ? AppColors.primary : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.1),
          child: Text(widget.s['name'][0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ),
        title: Text(widget.s['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF2D3436))),
        subtitle: Text('Roll No: ${widget.s['rollNumber'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4), fontWeight: FontWeight.w500)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('${widget.s['submitted']}/${widget.s['total']}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
          Text('COMPLETED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(height: 32),
              const Text('ASSIGNMENT BREAKDOWN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Colors.black38)),
              const SizedBox(height: 16),
              ...widget.allAssignments.map((a) {
                final isSubmitted = submittedIds.contains(a['_id']);
                final isApproved = approvedIds.contains(a['_id']);
                
                Color statusColor = Colors.black12;
                String statusLabel = 'NOT STARTED';
                if (isApproved) { statusColor = AppColors.success; statusLabel = 'APPROVED'; }
                else if (isSubmitted) { statusColor = AppColors.primary; statusLabel = 'PENDING'; }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(children: [
                    Icon(isApproved ? Icons.check_circle_rounded : isSubmitted ? Icons.hourglass_top_rounded : Icons.radio_button_off_rounded, size: 18, color: statusColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text(a['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2D3436)))),
                    if (isSubmitted && !isApproved)
                      TextButton(
                        onPressed: _isApproving ? null : () => _approveSubmission(a['_id']),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isApproving 
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('APPROVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      )
                    else
                      Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5)),
                  ]),
                );
              }),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.black.withOpacity(0.05), valueColor: AlwaysStoppedAnimation<Color>(color)),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
