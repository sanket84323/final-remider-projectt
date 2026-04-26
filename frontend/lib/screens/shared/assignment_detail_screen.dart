import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';

final _assignmentDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final assignmentResponse = await ApiService().get('/assignments/$id');
  final assignment = assignmentResponse.data['data'];
  
  // If it's a class assignment, fetch all students in that class to show a full roster
  if (assignment['targetAudience']?['type'] == 'class') {
    final className = assignment['targetAudience']['className'];
    final studentsResponse = await ApiService().get('/analytics/class/$className');
    return {
      'assignment': assignment,
      'classStudents': studentsResponse.data['data']['students'] as List,
    };
  }
  
  return {'assignment': assignment, 'classStudents': []};
});

class AssignmentDetailScreen extends ConsumerWidget {
  final String assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_assignmentDetailProvider(assignmentId));
    final authState = ref.watch(authStateProvider);
    final userRole = authState.valueOrNull?.role;
    final isAdminOrTeacher = userRole == 'admin' || userRole == 'teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Assignment Intelligence', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => ref.invalidate(_assignmentDetailProvider(assignmentId))),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final a = data['assignment'] as Map;
          final classStudents = data['classStudents'] as List;
          
          final dueDate = DateTime.parse(a['dueDate']);
          final isOverdue = DateTime.now().isAfter(dueDate);
          final submissions = a['completedBy'] as List? ?? [];
          
          final completedCount = submissions.where((s) => s['status'] == 'completed').length;
          final pendingCount = submissions.where((s) => s['status'] == 'pending').length;
          final totalStudents = classStudents.length > 0 ? classStudents.length : submissions.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─── Header Card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF303F9F)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(a['category']?.toUpperCase() ?? 'ASSIGNMENT', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                    const Spacer(),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(8)),
                        child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Inter', letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.person_pin_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text('By ${a['createdBy']['name']}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const Icon(Icons.timer_rounded, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMM d').format(dueDate), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // ─── Submission Stats (Admin/Teacher Only) ─────────────────
              if (isAdminOrTeacher) ...[
                const Text('Submission Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: Color(0xFF1A237E))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _StatCard(label: 'Assigned', value: '$totalStudents', color: const Color(0xFF1A237E), icon: Icons.groups_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(label: 'Pending', value: '$pendingCount', color: Colors.orange, icon: Icons.hourglass_empty_rounded)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(label: 'Completed', value: '$completedCount', color: Colors.green, icon: Icons.check_circle_outline_rounded)),
                ]),
                const SizedBox(height: 24),
              ],

              // ─── Description Section ────────────────────────────────────
              const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: Color(0xFF1A237E))),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: Text(
                  a['description'] ?? 'No description provided.',
                  style: TextStyle(fontSize: 14, color: Colors.black.withOpacity(0.7), height: 1.6, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Student Status List (Admin/Teacher Only) ──────────────
              if (isAdminOrTeacher) ...[
                const Text('Student Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: Color(0xFF1A237E))),
                const SizedBox(height: 12),
                if (totalStudents == 0)
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      Icon(Icons.info_outline_rounded, color: Colors.black.withOpacity(0.1), size: 32),
                      const SizedBox(height: 12),
                      Text('No students have been assigned to this task yet.', style: TextStyle(color: Colors.black.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalStudents,
                    itemBuilder: (context, i) {
                      Map student;
                      String status = 'not_started';

                      if (classStudents.isNotEmpty) {
                        student = classStudents[i];
                        final sub = submissions.firstWhere((s) => s['userId']?['_id'] == student['_id'], orElse: () => null);
                        if (sub != null) {
                          status = sub['status'] ?? 'pending';
                        }
                      } else {
                        final sub = submissions[i];
                        student = sub['userId'] as Map? ?? {};
                        status = sub['status'] ?? 'pending';
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.02)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(status).withOpacity(0.1),
                            child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 18),
                          ),
                          title: Text(student['name'] ?? 'Unknown Student', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(
                            'Status: ${status.replaceAll('_', ' ').toUpperCase()}', 
                            style: TextStyle(fontSize: 11, color: _getStatusColor(status), fontWeight: FontWeight.w900, letterSpacing: 0.5)
                          ),
                          trailing: status == 'pending' && userRole == 'admin' 
                            ? ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await ApiService().post('/assignments/$assignmentId/approve', data: {'studentId': student['_id']});
                                    ref.invalidate(_assignmentDetailProvider(assignmentId));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved! ✅'), backgroundColor: Colors.green));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('APPROVE'),
                              )
                            : null,
                        ),
                      );
                    },
                  ),
              ],

              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle_rounded;
      case 'pending': return Icons.hourglass_top_rounded;
      default: return Icons.radio_button_unchecked_rounded;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ]),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Inter')),
    ]),
  );
}
