import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _assignmentMasterProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final results = await Future.wait([
      ApiService().get('/analytics/classes').then((r) => r.data['data'] as List).catchError((_) => []),
      ApiService().get('/assignments').then((r) => r.data['data'] as List).catchError((_) => []),
    ]);
    
    return {
      'classes': results[0],
      'assignments': results[1],
    };
  } catch (e) {
    return {'classes': [], 'assignments': []};
  }
});

class ManageAssignmentsScreen extends ConsumerWidget {
  const ManageAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterAsync = ref.watch(_assignmentMasterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('All Assignments', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_assignmentMasterProvider),
          ),
        ],
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final classes = data['classes'] as List;
          final allAssignments = data['assignments'] as List;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final className = classes[index]['name'] ?? 'Unknown';
              final classAssignments = allAssignments.where((a) => a['targetAudience']?['className'] == className).toList();
              final latest = classAssignments.isNotEmpty ? classAssignments.first : null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: InkWell(
                  onTap: () => context.push('/admin-class-analytics/$className?tab=assignments'),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.school_rounded, color: Color(0xFF1A237E), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(className, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), letterSpacing: -0.5)),
                                  Text('Department of AI & DS', style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.3), fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black12),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _InfoChip(label: '${classAssignments.length} Assignments', icon: Icons.assignment_outlined, color: classAssignments.isEmpty ? Colors.grey : Colors.blue),
                            if (classAssignments.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              _InfoChip(label: '${classAssignments.where((a) => (a['completedBy'] as List? ?? []).any((s) => s['status'] == 'pending')).length} To Approve', icon: Icons.pending_actions_rounded, color: Colors.orange),
                            ],
                          ],
                        ),
                        if (latest != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'LATEST: ${latest['title']}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black.withOpacity(0.4), letterSpacing: 1),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                          Text(
                            'NO ASSIGNMENTS UPLOADED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.redAccent.withOpacity(0.5), letterSpacing: 1),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/teacher-create/assignment'),
        label: const Text('New Assignment'),
        icon: const Icon(Icons.add_rounded),
        backgroundColor: const Color(0xFF1A237E),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _InfoChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
