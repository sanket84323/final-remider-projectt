import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';
import '../../providers/app_providers.dart';

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  final String? assignmentId;
  const CreateAssignmentScreen({super.key, this.assignmentId});

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
  final List<String> _selectedClasses = [];
  bool _shouldNotify = true;
  final List<String> _classOptions = AppStrings.studentClasses;

  @override
  void initState() {
    super.initState();
    if (widget.assignmentId != null) {
      _loadAssignment();
    }
  }

  Future<void> _loadAssignment() async {
    setState(() => _isLoading = true);
    try {
      final repo = AssignmentRepository();
      final assignment = await repo.getAssignmentById(widget.assignmentId!);
      setState(() {
        _titleCtrl.text = assignment.title;
        _descCtrl.text = assignment.description;
        _subjectCtrl.text = assignment.subject ?? '';
        _dueDate = assignment.dueDate;
        final classes = (assignment.targetAudience['classNames'] as List?)?.map((c) => c.toString()).toList() ?? [];
        _selectedClasses.clear();
        _selectedClasses.addAll(classes);
        _shouldNotify = false; // Usually don't want to re-notify on edit by default
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading assignment: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    if (_selectedClasses.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one class'))); return; }

    setState(() => _isLoading = true);
    try {
      final repo = AssignmentRepository();
      final data = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'subject': _subjectCtrl.text.trim(),
        'dueDate': _dueDate!.toIso8601String(),
        'shouldNotify': _shouldNotify,
        'targetAudience': {
          'type': 'class',
          'classNames': _selectedClasses,
        },
      };

      if (widget.assignmentId != null) {
        await repo.updateAssignment(widget.assignmentId!, data);
      } else {
        await repo.createAssignment(data);
      }

      ref.invalidate(assignmentListProvider);
      ref.invalidate(teacherDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.assignmentId != null ? '✅ Assignment updated!' : '✅ Assignment created!'), 
            backgroundColor: AppColors.success
          )
        );
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
    final isEdit = widget.assignmentId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Assignment' : 'Create Assignment'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.pop()),
        actions: [
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _submit, 
              child: Text(isEdit ? 'Update' : 'Create', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))
            ),
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
            const SizedBox(height: 24),
            // ─── Multi-Class Selection ──────────────────────────────────────
            const Text('TARGET CLASSES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textHint, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _classOptions.map((className) {
                final isSelected = _selectedClasses.contains(className);
                return FilterChip(
                  label: Text(className, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedClasses.add(className);
                      } else {
                        _selectedClasses.remove(className);
                      }
                    });
                  },
                  selectedColor: AppColors.accent,
                  checkmarkColor: Colors.white,
                  backgroundColor: AppColors.divider.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // ─── Notification Toggle ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: _shouldNotify ? AppColors.success.withOpacity(0.05) : AppColors.divider.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: _shouldNotify ? AppColors.success.withOpacity(0.2) : AppColors.divider),
              ),
              child: SwitchListTile(
                title: const Text('Send Notification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                subtitle: Text(_shouldNotify ? 'Students will be notified immediately.' : 'No notification will be sent.', style: const TextStyle(fontSize: 11, fontFamily: 'Inter')),
                secondary: Icon(_shouldNotify ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: _shouldNotify ? AppColors.success : AppColors.textHint),
                value: _shouldNotify,
                onChanged: (v) => setState(() => _shouldNotify = v),
                activeColor: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
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
              icon: Icon(isEdit ? Icons.save_rounded : Icons.assignment_add),
              label: Text(isEdit ? 'Update Assignment' : 'Create Assignment'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
