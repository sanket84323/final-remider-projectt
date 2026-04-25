import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';

class AnnouncementScreen extends ConsumerStatefulWidget {
  const AnnouncementScreen({super.key});
  @override
  ConsumerState<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends ConsumerState<AnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'important';
  bool _isLoading = false;

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ReminderRepository().createReminder({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'priority': _priority,
        'category': 'announcement',
        'targetAudience': {'type': 'all'},
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📢 Announcement sent to all students!'), backgroundColor: AppColors.success));
        _titleCtrl.clear();
        _descCtrl.clear();
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
      appBar: AppBar(title: const Text('Send Announcement'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF7B1FA2).withOpacity(0.1), const Color(0xFF7B1FA2).withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(color: const Color(0xFF7B1FA2).withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.campaign_rounded, color: Color(0xFF7B1FA2), size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text('This announcement will be sent to ALL students and teachers across the college.', style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey[700], height: 1.4))),
              ]),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Announcement Title', prefixIcon: Icon(Icons.title_rounded)),
              validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Message', hintText: 'Write your announcement here...', prefixIcon: Icon(Icons.message_outlined)),
              maxLines: 6,
              validator: (v) => v == null || v.isEmpty ? 'Message required' : null,
            ),
            const SizedBox(height: 20),
            const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14)),
            const SizedBox(height: 8),
            Row(children: ['normal', 'important', 'urgent'].map((p) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _priority = p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _priority == p ? _pColor(p) : Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: _priority == p ? _pColor(p) : AppColors.divider),
                    ),
                    child: Text(p.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _priority == p ? Colors.white : AppColors.textSecondary, fontFamily: 'Inter')),
                  ),
                ),
              ),
            )).toList()),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendAnnouncement,
              icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.campaign_rounded),
              label: const Text('Send College-Wide Announcement'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
            ),
          ],
        ),
      ),
    );
  }

  Color _pColor(String p) => p == 'urgent' ? AppColors.error : p == 'important' ? AppColors.accent : AppColors.primary;
}
