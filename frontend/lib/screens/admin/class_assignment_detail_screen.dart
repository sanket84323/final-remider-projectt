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
  const ClassAssignmentDetailScreen({super.key, required this.className});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_classAnalyticsProvider(className));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('$className Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final totalAssignments = data['totalAssignments'] as int;
          final students = data['students'] as List;
          final assignments = data['assignments'] as List;

          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: AppColors.surface,
              appBar: AppBar(
                title: Text('$className Summary'),
                leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
                bottom: const TabBar(
                  tabs: [Tab(text: 'Students'), Tab(text: 'Assignments')],
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                ),
              ),
              body: TabBarView(children: [
                // ─── Student Status View ──────────────────────────────────
                ListView(
                  padding: const EdgeInsets.all(AppDimens.paddingMd),
                  children: [
                    // ─── Highlight: Not Submitted Anything ──────────────────
                    if (students.any((s) => s['submitted'] == 0)) ...[
                      const Text('🚨 Urgent: No Submissions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.error, fontFamily: 'Inter')),
                      const SizedBox(height: 12),
                      ...students.where((s) => s['submitted'] == 0).map((s) => _StudentStatusCard(s: s, status: 'Not Started', color: AppColors.error, allAssignments: assignments)),
                      const SizedBox(height: 24),
                    ],

                    const Text('Student Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 12),
                    ...students.where((s) => s['submitted'] > 0).map((s) {
                      final isDone = s['submitted'] == s['total'] && s['total'] > 0;
                      return _StudentStatusCard(
                        s: s, 
                        status: isDone ? 'All Done' : 'In Progress', 
                        color: isDone ? AppColors.success : AppColors.primary,
                        allAssignments: assignments,
                      );
                    }),
                  ],
                ),

                // ─── Assignments View ─────────────────────────────────────
                ListView(
                  padding: const EdgeInsets.all(AppDimens.paddingMd),
                  children: [
                    Text('Posted for $className', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 12),
                    ...assignments.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('By ${a['createdBy']['name']} • Due: ${a['dueDate'].toString().substring(0, 10)}', style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.assignment_outlined, color: AppColors.primary, size: 20),
                      ),
                    )),
                  ],
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _StudentStatusCard extends StatelessWidget {
  final Map<String, dynamic> s;
  final String status;
  final Color color;
  final List<dynamic> allAssignments;
  const _StudentStatusCard({required this.s, required this.status, required this.color, required this.allAssignments});

  @override
  Widget build(BuildContext context) {
    final double progress = s['total'] > 0 ? s['submitted'] / s['total'] : 0;
    final List<String> submittedIds = List<String>.from(s['submittedIds'] ?? []);
    final List<String> approvedIds = List<String>.from(s['approvedIds'] ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        leading: CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.1), child: Text(s['name'][0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter')),
        subtitle: Text('Roll: ${s['rollNumber'] ?? 'N/A'} • $status', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${s['submitted']}/${s['total']}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
          const Text('total', style: TextStyle(fontSize: 9, color: AppColors.textHint)),
        ]),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Assignment-wise Breakdown', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              ...allAssignments.map((a) {
                final isSubmitted = submittedIds.contains(a['_id']);
                final isApproved = approvedIds.contains(a['_id']);
                
                Color statusColor = AppColors.textHint;
                String statusLabel = 'Not Started';
                IconData statusIcon = Icons.radio_button_unchecked_rounded;

                if (isApproved) {
                  statusColor = AppColors.success;
                  statusLabel = 'Approved';
                  statusIcon = Icons.check_circle_rounded;
                } else if (isSubmitted) {
                  statusColor = AppColors.primary;
                  statusLabel = 'Submitted (Pending)';
                  statusIcon = Icons.hourglass_empty_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a['title'], style: const TextStyle(fontSize: 13))),
                    Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                  ]),
                );
              }),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Overall Progress', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text('${(progress * 100).toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.divider.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
