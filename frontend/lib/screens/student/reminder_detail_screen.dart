import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';
import '../../data/models/models.dart';
import '../../widgets/app_widgets.dart';
import '../../providers/app_providers.dart';

final _reminderDetailProvider = FutureProvider.family<ReminderModel, String>((ref, id) async {
  return ReminderRepository().getReminderById(id);
});

class ReminderDetailScreen extends ConsumerWidget {
  final String reminderId;
  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(_reminderDetailProvider(reminderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: reminderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading reminder: $e')),
        data: (reminder) => _ReminderDetailView(reminder: reminder),
      ),
    );
  }
}

class _ReminderDetailView extends StatelessWidget {
  final ReminderModel reminder;
  const _ReminderDetailView({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(reminder.priority);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Priority & Category Chips ──────────────────────────────────
          Row(children: [
            PriorityBadge(priority: reminder.priority),
            const SizedBox(width: 8),
            _CategoryChip(category: reminder.category),
            if (reminder.isPinned) ...[const SizedBox(width: 8), const Icon(Icons.push_pin_rounded, size: 16, color: AppColors.accent)],
          ]),
          const SizedBox(height: 16),

          // ─── Title ─────────────────────────────────────────────────────
          Text(reminder.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 12),

          // ─── Meta Info ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(children: [
              _MetaRow(icon: Icons.person_rounded, label: 'From', value: reminder.createdBy?.name ?? 'Unknown'),
              const Divider(height: 16),
              _MetaRow(icon: Icons.calendar_today_rounded, label: 'Posted', value: DateFormat('d MMMM yyyy, h:mm a').format(reminder.createdAt)),
              if (reminder.deadlineAt != null) ...[
                const Divider(height: 16),
                _MetaRow(icon: Icons.timer_rounded, label: 'Deadline', value: DateFormat('d MMMM yyyy, h:mm a').format(reminder.deadlineAt!), color: AppColors.error),
              ],
            ]),
          ),
          const SizedBox(height: 20),

          // ─── Urgent Banner ─────────────────────────────────────────────
          if (reminder.priority == 'urgent')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: 10),
                const Expanded(child: Text('⚠️ This is an URGENT notice. Please take immediate action.', style: TextStyle(color: AppColors.error, fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13))),
              ]),
            ),

          // ─── Description ───────────────────────────────────────────────
          const Text('Description', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(reminder.description, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.7)),
          const SizedBox(height: 20),

          // ─── Tags ──────────────────────────────────────────────────────
          if (reminder.tags.isNotEmpty) ...[
            Wrap(spacing: 8, children: reminder.tags.map((tag) => Chip(label: Text('#$tag', style: const TextStyle(fontSize: 12)))).toList()),
            const SizedBox(height: 16),
          ],

          // ─── Attachments ───────────────────────────────────────────────
          if (reminder.attachments.isNotEmpty) ...[
            const Text('Attachments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Inter', color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            ...reminder.attachments.map((a) => _AttachmentTile(attachment: a)),
          ],

          const SizedBox(height: 32),
          
          _MarkAsReadButton(reminder: reminder),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent': return AppColors.error;
      case 'important': return AppColors.accent;
      default: return AppColors.primary;
    }
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _MetaRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: color ?? AppColors.textHint),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: AppColors.textHint, fontFamily: 'Inter')),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color ?? AppColors.textPrimary, fontFamily: 'Inter'))),
    ]);
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
      ),
      child: Text(category.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Inter', letterSpacing: 0.5)),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final AttachmentModel attachment;
  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (await canLaunchUrl(Uri.parse(attachment.url))) {
          await launchUrl(Uri.parse(attachment.url), mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(children: [
          Icon(attachment.isPdf ? Icons.picture_as_pdf_rounded : attachment.isImage ? Icons.image_rounded : Icons.attach_file_rounded, color: attachment.isPdf ? AppColors.error : AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(attachment.originalName, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: AppColors.textPrimary), overflow: TextOverflow.ellipsis)),
          const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

class _MarkAsReadButton extends ConsumerStatefulWidget {
  final ReminderModel reminder;
  const _MarkAsReadButton({required this.reminder});

  @override
  ConsumerState<_MarkAsReadButton> createState() => _MarkAsReadButtonState();
}

class _MarkAsReadButtonState extends ConsumerState<_MarkAsReadButton> {
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    if (widget.reminder.isRead || _isSuccess) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text('You have read this notice', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () async {
          setState(() => _isLoading = true);
          try {
            await ReminderRepository().getReminderById(widget.reminder.id);
            ref.invalidate(studentDashboardProvider);
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isSuccess = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notice marked as read'), behavior: SnackBarBehavior.floating),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check_circle_outline_rounded),
        label: Text(_isLoading ? 'Processing...' : 'Mark as Read', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
