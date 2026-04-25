import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/app_providers.dart';

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  ConsumerState<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends ConsumerState<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _selectedClassDropdown;
  final List<String> _classOptions = ['All Classes', ...AppStrings.studentClasses];

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 3)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 23, minute: 59));
    if (time == null || !mounted) return;
    setState(() => _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dueDate == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a due date'))); return; }

    setState(() => _isLoading = true);
    try {
      await AssignmentRepository().createAssignment({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'dueDate': _dueDate!.toIso8601String(),
        'targetAudience': {
          'type': (_selectedClassDropdown == 'All Classes' || _selectedClassDropdown == null) 
              ? 'all' 
              : 'class',
          if (_selectedClassDropdown != 'All Classes' && _selectedClassDropdown != null) 
            'className': _selectedClassDropdown == 'Other' ? _classCtrl.text.trim() : _selectedClassDropdown,
        },
      });
      ref.invalidate(assignmentListProvider);
      ref.invalidate(teacherDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Assignment created!'), backgroundColor: AppColors.success));
        context.go('/teacher');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(onPressed: _submit, child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Assignment Title', prefixIcon: Icon(Icons.assignment_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject (optional)', prefixIcon: Icon(Icons.book_outlined)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Instructions', hintText: 'Describe the assignment in detail...', prefixIcon: Icon(Icons.description_outlined)),
              maxLines: 6,
              validator: (v) => v == null || v.isEmpty ? 'Description required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedClassDropdown,
              decoration: const InputDecoration(
                labelText: 'Target Class',
                prefixIcon: Icon(Icons.class_outlined),
              ),
              items: _classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedClassDropdown = val),
            ),
            if (_selectedClassDropdown == 'Other') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _classCtrl,
                decoration: const InputDecoration(labelText: 'Custom Class Name', prefixIcon: Icon(Icons.class_outlined)),
              ),
            ],
            const SizedBox(height: 20),
            // ─── Due Date Picker ────────────────────────────────────────────
            GestureDetector(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _dueDate != null ? AppColors.accentContainer : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: _dueDate != null ? AppColors.accent : AppColors.divider),
                ),
                child: Row(children: [
                  Icon(Icons.event_rounded, color: _dueDate != null ? AppColors.accent : AppColors.textHint),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Due Date & Time', style: TextStyle(fontSize: 12, color: _dueDate != null ? AppColors.accent : AppColors.textHint, fontFamily: 'Inter')),
                    Text(
                      _dueDate == null ? 'Tap to set due date' : DateFormat('EEEE, d MMM yyyy · h:mm a').format(_dueDate!),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dueDate != null ? AppColors.accent : AppColors.textSecondary, fontFamily: 'Inter'),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: const Icon(Icons.assignment_add),
              label: const Text('Create Assignment'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
