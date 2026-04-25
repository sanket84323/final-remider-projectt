import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';

class StudentAssignmentScreen extends ConsumerStatefulWidget {
  const StudentAssignmentScreen({super.key});
  @override
  ConsumerState<StudentAssignmentScreen> createState() => _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState extends ConsumerState<StudentAssignmentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(assignmentListProvider.notifier).loadAssignments(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(assignmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Assignments'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(assignmentListProvider.notifier).loadAssignments(refresh: true),
        child: assignmentsAsync.when(
          data: (assignments) {
            final pending = assignments.where((a) => !a.isCompleted).toList();
            if (pending.isEmpty) {
              return const Center(child: Text('No pending assignments! 🎉'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, i) {
                final a = pending[i];
                final daysLeft = a.dueDate.difference(DateTime.now()).inDays;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.primaryContainer, child: Icon(Icons.assignment_rounded, color: AppColors.primary)),
                    title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Due: ${DateFormat('d MMM').format(a.dueDate)} · ${a.subject ?? ''}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: (daysLeft <= 1 ? Colors.red : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(daysLeft <= 0 ? 'Today' : '$daysLeft days', style: TextStyle(color: daysLeft <= 1 ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        if (a.isPending)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(Icons.hourglass_empty_rounded, color: AppColors.accent, size: 14),
                          ),
                      ],
                    ),
                    onTap: () => context.push('/student/assignment/${a.id}'),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
