import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/app_providers.dart';

class CreateReminderScreen extends ConsumerStatefulWidget {
  final String? reminderId;
  const CreateReminderScreen({super.key, this.reminderId});

  @override
  ConsumerState<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends ConsumerState<CreateReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _priority = 'normal';
  String _category = 'reminder';
  String _audienceType = 'all';
  String? _selectedClassDropdown;
  String? _customClass;
  final List<String> _classOptions = AppStrings.studentClasses;
  DateTime? _scheduledAt;
  DateTime? _deadlineAt;
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.reminderId != null) {
      _loadReminder();
    }
  }

  Future<void> _loadReminder() async {
    setState(() => _isLoading = true);
    try {
      final repo = ReminderRepository();
      final reminder = await repo.getReminderById(widget.reminderId!);
      setState(() {
        _titleCtrl.text = reminder.title;
        _descCtrl.text = reminder.description;
        _priority = reminder.priority;
        _category = reminder.category;
        _audienceType = reminder.targetAudience['type'] ?? 'all';
        _selectedClassDropdown = reminder.targetAudience['className'];
        _scheduledAt = reminder.scheduledAt;
        _deadlineAt = reminder.deadlineAt;
        _isPinned = reminder.isPinned;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading reminder: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final _priorities = ['normal', 'important', 'urgent'];
  final _categories = ['reminder', 'announcement', 'notice', 'event', 'exam', 'timetable'];
  final _audienceTypes = ['all', 'class', 'department'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ReminderRepository();
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'category': _category,
        'targetAudience': {
          'type': _audienceType,
          if (_selectedClassDropdown != null && (_audienceType == 'class' || _audienceType == 'section')) 
            'className': _selectedClassDropdown == 'Other' ? _customClass : _selectedClassDropdown,
        },
        if (_scheduledAt != null) 'scheduledAt': _scheduledAt!.toIso8601String(),
        if (_deadlineAt != null) 'deadlineAt': _deadlineAt!.toIso8601String(),
        'isPinned': _isPinned,
      };

      if (widget.reminderId != null) {
        await repo.updateReminder(widget.reminderId!, data);
      } else {
        await repo.createReminder(data);
      }

      ref.invalidate(teacherDashboardProvider);
      ref.invalidate(reminderListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.reminderId != null 
                ? '✅ Reminder updated!' 
                : (_scheduledAt != null ? '⏰ Reminder scheduled!' : '✅ Reminder sent!')), 
              backgroundColor: AppColors.success
            ),
          );
          context.go('/teacher');
        }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime({required bool isScheduled}) async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() { if (isScheduled) _scheduledAt = result; else _deadlineAt = result; });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.reminderId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Reminder' : 'Create Reminder'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _submit, 
              child: Text(isEdit ? 'Update' : 'Send', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          children: [
            // ─── Title ─────────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'Enter reminder title', prefixIcon: Icon(Icons.title_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
              maxLength: 200,
            ),
            const SizedBox(height: 16),

            // ─── Description ───────────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Enter detailed description...', prefixIcon: Icon(Icons.description_outlined)),
              maxLines: 5,
              validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
            ),
            const SizedBox(height: 20),

            // ─── Priority ──────────────────────────────────────────────────
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14)),
            const SizedBox(height: 8),
            Row(children: _priorities.map((p) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _priority == p ? _priorityColor(p) : Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: _priority == p ? _priorityColor(p) : AppColors.divider),
                    ),
                    child: Text(p.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _priority == p ? Colors.white : AppColors.textSecondary, fontFamily: 'Inter')),
                  ),
                ),
              ),
            )).toList()),
            const SizedBox(height: 16),

            // ─── Category ──────────────────────────────────────────────────
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),

              if (_audienceType == 'class') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedClassDropdown,
                  decoration: const InputDecoration(labelText: 'Target Class', prefixIcon: Icon(Icons.class_outlined)),
                  items: _classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedClassDropdown = v),
                ),
                if (_selectedClassDropdown == 'Other') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Custom Class Name (e.g. CS-3A)', prefixIcon: Icon(Icons.class_outlined)),
                    onChanged: (v) => _customClass = v,
                  ),
                ],
              ],
              if (_audienceType == 'department') ...[
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: AppStrings.defaultDepartment,
                  decoration: const InputDecoration(labelText: 'Target Department', prefixIcon: Icon(Icons.business_rounded)),
                  readOnly: true, // Only AIDS for now as per request
                ),
              ],
            const SizedBox(height: 20),

            // ─── Options Row ───────────────────────────────────────────────
            Row(children: [
              Expanded(child: _DateTimeTile(
                label: _scheduledAt == null ? 'Schedule for later' : 'Scheduled: ${DateFormat('d MMM, h:mm a').format(_scheduledAt!)}',
                icon: Icons.schedule_rounded,
                onTap: () => _pickDateTime(isScheduled: true),
                isSet: _scheduledAt != null,
                onClear: () => setState(() => _scheduledAt = null),
              )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _DateTimeTile(
                label: _deadlineAt == null ? 'Set deadline (optional)' : 'Deadline: ${DateFormat('d MMM, h:mm a').format(_deadlineAt!)}',
                icon: Icons.timer_outlined,
                onTap: () => _pickDateTime(isScheduled: false),
                isSet: _deadlineAt != null,
                onClear: () => setState(() => _deadlineAt = null),
              )),
            ]),
            const SizedBox(height: 16),

            // ─── Pin Toggle ────────────────────────────────────────────────
            SwitchListTile(
              value: _isPinned,
              onChanged: (v) => setState(() => _isPinned = v),
              title: const Text('Pin this reminder', style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Pinned reminders appear at the top of dashboards', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
              secondary: const Icon(Icons.push_pin_rounded, color: AppColors.accent),
              activeColor: AppColors.accent,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: Icon(_scheduledAt != null ? Icons.schedule_rounded : Icons.send_rounded),
              label: Text(_scheduledAt != null ? 'Schedule Reminder' : 'Send Now'),
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String p) => p == 'urgent' ? AppColors.error : p == 'important' ? AppColors.accent : AppColors.primary;
  String _audienceLabel(String a) => a == 'all' ? '📢 All Students' : a == 'class' ? '🏫 Specific Class' : '🏛️ Department';
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isSet;
  final VoidCallback onClear;
  const _DateTimeTile({required this.label, required this.icon, required this.onTap, required this.isSet, required this.onClear});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isSet ? AppColors.primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: isSet ? AppColors.primary.withOpacity(0.3) : AppColors.divider),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: isSet ? AppColors.primary : AppColors.textHint),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontFamily: 'Inter', color: isSet ? AppColors.primary : AppColors.textSecondary, fontWeight: isSet ? FontWeight.w500 : FontWeight.w400))),
        if (isSet) GestureDetector(onTap: onClear, child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary)),
      ]),
    ),
  );
}
