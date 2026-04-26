import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../widgets/app_widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationProvider);
    final userRole = ref.watch(authStateProvider).valueOrNull?.role ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationProvider.notifier).loadNotifications(refresh: true),
        child: notifAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.notifications_none_rounded,
                message: 'No notifications yet',
                subtitle: 'Reminders and announcements will appear here',
              );
            }

            // Group by date
            final grouped = <String, List<NotificationModel>>{};
            for (final n in notifications) {
              final key = _dateLabel(n.deliveredAt);
              grouped.putIfAbsent(key, () => []).add(n);
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final date = grouped.keys.elementAt(index);
                final items = grouped[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint, fontFamily: 'Inter', letterSpacing: 0.5)),
                    ),
                    ...items.map((n) {
                      final isAssignment = n.assignmentId != null;
                      final isReminder = n.reminderId != null;

                      void handleTap() {
                        ref.read(notificationProvider.notifier).markAsRead(n.id);
                        
                        if (isAssignment) {
                          if (userRole == 'student') {
                            context.push('/student/assignment/${n.assignmentId}');
                          } else {
                            // Teacher/Admin goes to teacher assignment detail
                            context.push('/teacher-assignment/${n.assignmentId}');
                          }
                        } else if (isReminder) {
                          if (userRole == 'student') {
                            context.push('/student/reminder/${n.reminderId}');
                          } else if (userRole == 'teacher') {
                            context.push('/teacher-receipts/${n.reminderId}');
                          } else {
                             context.push('/admin-announce?id=${n.reminderId}');
                          }
                        }
                      }

                      return Slidable(
                        key: ValueKey(n.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => ref.read(notificationProvider.notifier).deleteNotification(n.id),
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_rounded,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: _NotifTile(
                          notification: n,
                          onTap: handleTap,
                        ),
                      );
                    }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  const _NotifTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.readStatus;
    final priorityColor = notification.priority == 'urgent' ? AppColors.error : notification.priority == 'important' ? AppColors.accent : AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? AppColors.primaryContainer.withOpacity(0.4) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(notification.type), color: priorityColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(notification.title, style: TextStyle(fontSize: 14, fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500, fontFamily: 'Inter', color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (isUnread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                ]),
                const SizedBox(height: 4),
                LinkifiedText(notification.body, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(timeago.format(notification.deliveredAt), style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter')),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'assignment':
      case 'assignment_submission':
      case 'assignment_approval':
        return Icons.assignment_rounded;
      case 'announcement':
      case 'reminder':
        return Icons.campaign_rounded;
      case 'system':
        return Icons.settings_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
