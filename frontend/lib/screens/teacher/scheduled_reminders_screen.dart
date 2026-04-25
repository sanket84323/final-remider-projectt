import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../widgets/app_widgets.dart';

class ScheduledRemindersScreen extends ConsumerStatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  ConsumerState<ScheduledRemindersScreen> createState() => _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState extends ConsumerState<ScheduledRemindersScreen> {
  @override
  void initState() {
    super.initState();
    // Load reminders when tab becomes active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderListProvider.notifier).loadReminders(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(reminderListProvider.notifier).loadReminders(refresh: true),
          ),
        ],
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Error: $e', style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter'), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(reminderListProvider.notifier).loadReminders(refresh: true),
              child: const Text('Retry'),
            ),
          ]),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.notifications_none,
              message: 'No reminders sent yet',
              subtitle: 'Create a reminder to notify your students',
              action: ElevatedButton.icon(
                onPressed: () => context.go('/teacher-create'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create Reminder'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: reminders.length,
            itemBuilder: (context, i) {
              final r = reminders[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _priorityColor(r.priority).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_categoryIcon(r.category), color: _priorityColor(r.priority), size: 20),
                    ),
                    title: Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        PriorityBadge(priority: r.priority),
                        const SizedBox(height: 2),
                        Text(DateFormat('d MMM yyyy • hh:mm a').format(r.createdAt), style: const TextStyle(fontSize: 11, fontFamily: 'Inter', color: AppColors.textHint)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                          tooltip: 'Read Receipts',
                          onPressed: () => context.push('/teacher/receipts/${r.id}'),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent': return AppColors.priorityUrgent;
      case 'important': return AppColors.priorityImportant;
      default: return AppColors.priorityNormal;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'exam': return Icons.quiz_rounded;
      case 'announcement': return Icons.campaign_rounded;
      case 'event': return Icons.event_rounded;
      case 'timetable': return Icons.schedule_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}
