import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

class TeacherAssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const TeacherAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<TeacherAssignmentDetailScreen> createState() => _TeacherAssignmentDetailScreenState();
}

class _TeacherAssignmentDetailScreenState extends ConsumerState<TeacherAssignmentDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService().get('/assignments/${widget.assignmentId}');
      if (response.data['success'] == true) {
        setState(() { 
          _data = response.data['data']; 
          _loading = false; 
        });
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _markStudentComplete(String studentId) async {
    try {
      final response = await ApiService().post('/assignments/mark-student-complete', data: {
        'assignmentId': widget.assignmentId,
        'studentId': studentId,
      });
      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Action successful'), backgroundColor: AppColors.success));
        }
        _loadData();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to update');
      }
    } catch (e) {
      String msg = e.toString();
      if (e is DioException) {
        msg = e.response?.data['message'] ?? e.message ?? e.toString();
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $msg')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    try {
      if (_data == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Assignment Details')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Could not load assignment details'),
                TextButton(onPressed: _loadData, child: const Text('Retry')),
              ],
            ),
          ),
        );
      }

      final assignment = _data!;
      
      // Parse completion status map
      final completedByList = assignment['completedBy'] as List? ?? [];
      final Map<String, String> completionStatus = {};
      for (var c in completedByList) {
        try {
          final userIdData = c['userId'];
          final id = userIdData is Map ? userIdData['_id']?.toString() : userIdData?.toString();
          if (id != null) {
            completionStatus[id] = c['status']?.toString() ?? 'completed';
          }
        } catch (_) {}
      }

      final allStudents = (assignment['allTargetedStudents'] as List? ?? []);

      return Scaffold(
        appBar: AppBar(title: Text(assignment['title'] ?? 'Assignment Details')),
        body: Column(
          children: [
            _OverviewCard(assignment: assignment),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Student Submissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${completionStatus.values.where((v) => v == 'completed').length}/${allStudents.length} Approved', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: allStudents.isEmpty 
                ? const Center(child: Text('No students found for this class'))
                : ListView.builder(
                    itemCount: allStudents.length,
                    itemBuilder: (ctx, i) {
                      final student = allStudents[i];
                      final sId = student['_id']?.toString() ?? '';
                      final status = completionStatus[sId]; // null, 'pending', or 'completed'
                      final isDone = status == 'completed';
                      final isPending = status == 'pending';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDone 
                              ? AppColors.successContainer 
                              : (isPending ? AppColors.accent.withOpacity(0.2) : AppColors.primaryContainer),
                          child: Text(student['name']?[0] ?? 'S', 
                              style: TextStyle(color: isDone ? AppColors.success : (isPending ? AppColors.accent : AppColors.primary))),
                        ),
                        title: Text(student['name'] ?? 'Unknown Student'),
                        subtitle: Text('Roll: ${student['rollNumber'] ?? 'N/A'} · ${student['className'] ?? ''}'),
                        trailing: SizedBox(
                          width: 100,
                          child: isDone 
                            ? const Align(alignment: Alignment.centerRight, child: Icon(Icons.check_circle, color: AppColors.success))
                            : ElevatedButton(
                                onPressed: sId.isEmpty ? null : () => _markStudentComplete(sId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPending ? AppColors.accent : AppColors.primary, 
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 36),
                                ),
                                child: Text(isPending ? 'Approve' : 'Mark Done', 
                                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                              ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('A layout error occurred: $e\n\nPlease try refreshing.'),
        )),
      );
    }
  }
}

class _OverviewCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  const _OverviewCard({required this.assignment});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'Targeted', value: '${(assignment['allTargetedStudents'] as List?)?.length ?? 0}'),
        _Stat(label: 'Completed', value: '${(assignment['completedBy'] as List?)?.length ?? 0}', color: Colors.green),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(color: Colors.grey)),
  ]);
}
