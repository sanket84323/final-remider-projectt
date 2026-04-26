import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';
import '../../data/models/models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

final _assignmentDetailProvider = FutureProvider.family<AssignmentModel, String>((ref, id) async {
  return AssignmentRepository().getAssignmentById(id);
});

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen> {
  bool _isMarking = false;

  Future<void> _markComplete(AssignmentModel assignment) async {
    setState(() => _isMarking = true);
    try {
      await ref.read(assignmentListProvider.notifier).markComplete(assignment.id);
      ref.invalidate(_assignmentDetailProvider(widget.assignmentId));
      ref.invalidate(studentDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Marked as completed!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentAsync = ref.watch(_assignmentDetailProvider(widget.assignmentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignment Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: assignmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (assignment) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // ─── Due Date Card ─────────────────────────────────────
                  _DueDateCard(assignment: assignment),
                  const SizedBox(height: 16),

                  // ─── Title ─────────────────────────────────────────────
                  Text(assignment.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  if (assignment.subject != null)
                    Text(assignment.subject!, style: const TextStyle(fontSize: 14, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),

                  // ─── Meta ──────────────────────────────────────────────
                  _MetaRow(label: 'Assigned by', value: assignment.createdBy?.name ?? 'Teacher'),
                  const SizedBox(height: 6),
                  _MetaRow(label: 'Posted on', value: DateFormat('d MMM yyyy').format(assignment.createdAt)),
                  const SizedBox(height: 20),

                  // ─── Description ───────────────────────────────────────
                  const Text('Instructions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  const SizedBox(height: 10),
                  LinkifiedText(assignment.description, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.7)),
                  const SizedBox(height: 20),

                  // ─── Attachments ───────────────────────────────────────
                  if (assignment.attachments.isNotEmpty) ...[
                    const Text('Attachments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                    const SizedBox(height: 10),
                    ...assignment.attachments.map((a) => _AttachmentRow(attachment: a)),
                  ],
                ]),
              ),
            ),

            // ─── Bottom Action ─────────────────────────────────────────────
            if (assignment.isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                decoration: BoxDecoration(color: AppColors.successContainer, border: Border(top: BorderSide(color: AppColors.success.withOpacity(0.2)))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  const Text('Assignment Completed & Approved', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ]),
              )
            else if (assignment.isPending)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.1), border: Border(top: BorderSide(color: AppColors.accent.withOpacity(0.2)))),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.hourglass_empty_rounded, color: AppColors.accent, size: 20),
                  const SizedBox(width: 8),
                  const Text('Pending until your teacher approve it', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                ]),
              )
            else if (!assignment.isOverdue)
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.divider)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isMarking ? null : () => _markComplete(assignment),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd))),
                    child: _isMarking ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Mark as Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DueDateCard extends StatelessWidget {
  final AssignmentModel assignment;
  const _DueDateCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalDays = assignment.dueDate.difference(assignment.createdAt).inHours.toDouble();
    final remaining = assignment.dueDate.difference(now).inHours.toDouble();
    final percent = totalDays > 0 ? (1 - (remaining / totalDays)).clamp(0.0, 1.0) : 1.0;
    final daysLeft = assignment.dueDate.difference(now).inDays;
    final color = assignment.isOverdue ? AppColors.error : daysLeft <= 1 ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.08), color.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        CircularPercentIndicator(
          radius: 36,
          lineWidth: 5,
          percent: percent,
          center: Icon(assignment.isOverdue ? Icons.warning_rounded : Icons.timer_rounded, color: color, size: 24),
          progressColor: color,
          backgroundColor: color.withOpacity(0.1),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(assignment.isOverdue ? '⏰ OVERDUE' : '📅 Due Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'Inter', letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(DateFormat('d MMM yyyy, h:mm a').format(assignment.dueDate), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          Text(assignment.isOverdue ? 'Deadline passed' : daysLeft == 0 ? 'Due today!' : '$daysLeft days remaining', style: TextStyle(fontSize: 13, color: color, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetaRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text('$label: ', style: const TextStyle(color: AppColors.textHint, fontFamily: 'Inter', fontSize: 13)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Inter', fontSize: 13, color: AppColors.textPrimary)),
  ]);
}

class _AttachmentRow extends StatelessWidget {
  final AttachmentModel attachment;
  const _AttachmentRow({required this.attachment});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppDimens.radiusMd), border: Border.all(color: AppColors.divider)),
    child: Row(children: [
      Icon(attachment.isPdf ? Icons.picture_as_pdf_rounded : Icons.attach_file_rounded, color: AppColors.primary, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(attachment.originalName, style: const TextStyle(fontSize: 13, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
    ]),
  );
}
