import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    // Load calendar data when tab opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(reminderListProvider).valueOrNull?.isEmpty ?? true) {
        ref.read(reminderListProvider.notifier).loadReminders(refresh: true);
      }
      if (ref.read(assignmentListProvider).valueOrNull?.isEmpty ?? true) {
        ref.read(assignmentListProvider.notifier).loadAssignments(refresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderListProvider);
    final assignmentsAsync = ref.watch(assignmentListProvider);

    // Build event map
    final Map<DateTime, List<dynamic>> events = {};
    remindersAsync.whenData((reminders) {
      for (final r in reminders) {
        final day = DateTime.utc(r.createdAt.year, r.createdAt.month, r.createdAt.day);
        events.putIfAbsent(day, () => []).add(r);
        if (r.deadlineAt != null) {
          final deadlineDay = DateTime.utc(r.deadlineAt!.year, r.deadlineAt!.month, r.deadlineAt!.day);
          events.putIfAbsent(deadlineDay, () => []).add({'type': 'deadline', 'title': '⏰ ${r.title}'});
        }
      }
    });
    assignmentsAsync.whenData((assignments) {
      for (final a in assignments) {
        final day = DateTime.utc(a.dueDate.year, a.dueDate.month, a.dueDate.day);
        events.putIfAbsent(day, () => []).add(a);
      }
    });

    List<dynamic> selectedEvents = [];
    if (_selectedDay != null) {
      final key = DateTime.utc(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      selectedEvents = events[key] ?? [];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) {
              final key = DateTime.utc(day.year, day.month, day.day);
              return events[key] ?? [];
            },
            onDaySelected: (selected, focused) => setState(() { _selectedDay = selected; _focusedDay = focused; }),
            onFormatChanged: (f) => setState(() => _format = f),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: AppColors.primaryLight.withOpacity(0.3), shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              markerDecoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              markersMaxCount: 3,
              weekendTextStyle: const TextStyle(color: AppColors.error),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.all(Radius.circular(20))),
              formatButtonTextStyle: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w600),
              titleTextStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const Divider(height: 1),

          // ─── Day Events ────────────────────────────────────────────────
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.event_available_rounded, color: AppColors.textHint, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        _selectedDay != null ? 'No events on ${DateFormat('d MMM').format(_selectedDay!)}' : 'Select a date',
                        style: const TextStyle(color: AppColors.textHint, fontFamily: 'Inter'),
                      ),
                    ]),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final event = selectedEvents[i];
                      if (event is ReminderModel) {
                        return _EventTile(
                          icon: Icons.notifications_rounded,
                          color: _priorityColor(event.priority),
                          title: event.title,
                          subtitle: '${event.priority.toUpperCase()} · ${event.createdBy?.name ?? ''}',
                          onTap: () => context.push('/student/reminder/${event.id}'),
                        );
                      } else if (event is AssignmentModel) {
                        return _EventTile(
                          icon: Icons.assignment_rounded,
                          color: AppColors.accent,
                          title: event.title,
                          subtitle: 'Due ${DateFormat('h:mm a').format(event.dueDate)} · ${event.subject ?? ''}',
                          onTap: () => context.push('/student/assignment/${event.id}'),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String p) => p == 'urgent' ? AppColors.error : p == 'important' ? AppColors.accent : AppColors.primary;
}

class _EventTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _EventTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontFamily: 'Inter')),
          ])),
          Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
        ]),
      ),
    );
  }
}
