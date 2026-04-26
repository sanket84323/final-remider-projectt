import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';
import '../../providers/app_providers.dart';

final _assignmentProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await ApiService().get('/assignments/$id');
  return response.data['data'];
});

class AssignmentSubmissionScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const AssignmentSubmissionScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentSubmissionScreen> createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends ConsumerState<AssignmentSubmissionScreen> {
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitAssignment() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(assignmentRepositoryProvider).markComplete(widget.assignmentId, note: _noteCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully! 🚀'), backgroundColor: AppColors.success),
        );
        ref.invalidate(_assignmentProvider(widget.assignmentId));
        ref.invalidate(studentDashboardProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentAsync = ref.watch(_assignmentProvider(widget.assignmentId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Submit Assignment', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: assignmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (a) {
          final dueDate = DateTime.parse(a['dueDate']);
          final isOverdue = DateTime.now().isAfter(dueDate);
          final isSubmitted = a['isPending'] == true || a['isCompleted'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─── Info Header Card ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A237E), Color(0xFF311B92)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(a['subject']?.toUpperCase() ?? 'ASSIGNMENT', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ),
                    const Spacer(),
                    if (a['isCompleted'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('COMPLETED', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    else if (a['isPending'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                        child: const Text('PENDING APPROVAL', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 16),
                  Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Inter', letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Icon(Icons.person_outline_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text('Professor: ${a['createdBy']['name']}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text('Due Date: ${DateFormat('MMM d, yyyy').format(dueDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // ─── Instructions Section ──────────────────────────────────
              const Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: AppColors.textPrimary)),
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
                  a['description'] ?? 'No additional instructions provided.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6, fontFamily: 'Inter'),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Submission Form ───────────────────────────────────────
              const Text('Submission Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter', color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _noteCtrl,
                  maxLines: 5,
                  enabled: !isSubmitted && !isOverdue,
                  decoration: InputDecoration(
                    hintText: isSubmitted ? 'Already submitted' : 'Enter any notes or your submission link here...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
                    contentPadding: const EdgeInsets.all(20),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ─── Action Button ──────────────────────────────────────────
              // ─── Action Button ──────────────────────────────────────────
              if (!isSubmitted && !isOverdue)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAssignment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                )
              else if (isOverdue && !isSubmitted)
                const Center(
                  child: Text('This assignment is overdue and no longer accepting submissions.', 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                )
              else if (a['isCompleted'] == true)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Assignment Submitted Successfully', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                  ]),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.hourglass_empty_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Pending Teacher Approval', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700)),
                  ]),
                ),

              const SizedBox(height: 40),
            ]),
          );
        },
      ),
    );
  }
}
