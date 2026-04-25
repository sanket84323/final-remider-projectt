import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _assignmentProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final response = await ApiService().get('/assignments/$id');
  return response.data['data'];
});

class AssignmentDetailScreen extends ConsumerWidget {
  final String assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentAsync = ref.watch(_assignmentProvider(assignmentId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Assignment Detail'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: assignmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (a) {
          final dueDate = DateTime.parse(a['dueDate']);
          final isOverdue = DateTime.now().isAfter(dueDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─── Header Card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1E88E5)]),
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                      child: Text(a['category']?.toUpperCase() ?? 'GENERAL', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(6)),
                        child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.person_pin_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text('Posted by: ${a['createdBy']['name']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.timer_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text('Due: ${DateFormat('MMM d, yyyy • h:mm a').format(dueDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ]),
              ),

              const SizedBox(height: 24),

              // ─── Description Section ────────────────────────────────────
              const Text('Task Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                child: Text(
                  a['description'] ?? 'No description provided.',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.6, fontFamily: 'Inter'),
                ),
              ),

              const SizedBox(height: 24),

              // ─── Attachments Section ────────────────────────────────────
              if (a['attachments'] != null && (a['attachments'] as List).isNotEmpty) ...[
                const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(height: 12),
                ...(a['attachments'] as List).map((att) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary),
                    title: Text(att['name'] ?? 'File Attachment', style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.download_rounded),
                    onTap: () {}, // Link to actual file
                  ),
                )),
                const SizedBox(height: 24),
              ],

              // ─── Target Students Info ───────────────────────────────────
              const Text('Targeted Students', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                child: Row(children: [
                  const Icon(Icons.groups_rounded, color: AppColors.textHint),
                  const SizedBox(width: 12),
                  Text(
                    a['targetAudience']['type'] == 'all' ? 'Entire Department' : 'Class: ${a['targetAudience']['className']}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
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
