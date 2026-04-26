import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _adminAnnouncementsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiService().get('/reminders');
  return response.data['data'] as List;
});

class ManageAnnouncementsScreen extends ConsumerWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(_adminAnnouncementsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Manage Announcements', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_adminAnnouncementsProvider),
          ),
        ],
      ),
      body: announcementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No announcements found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) => _AnnouncementTile(announcement: list[i]),
          );
        },
      ),
    );
  }
}

class _AnnouncementTile extends ConsumerWidget {
  final Map<String, dynamic> announcement;
  const _AnnouncementTile({required this.announcement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String id = announcement['_id'];
    final String title = announcement['title'] ?? 'Untitled';
    final String priority = announcement['priority'] ?? 'normal';
    final DateTime createdAt = DateTime.parse(announcement['createdAt']);
    
    Color priorityColor = Colors.green;
    if (priority == 'urgent') priorityColor = Colors.red;
    if (priority == 'important') priorityColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            width: 4,
            decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2)),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF2D3436))),
          subtitle: Text(
            'Sent: ${DateFormat('MMM d, h:mm a').format(createdAt)}\nTarget: ${announcement['targetAudience']?['type'] ?? 'all'}',
            style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.4)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.grey, size: 20),
                onPressed: () => _showDetails(context),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                onPressed: () => context.push('/admin-announce?id=$id'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _getPriorityColor().withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  announcement['priority']?.toUpperCase() ?? 'NORMAL', 
                  style: TextStyle(color: _getPriorityColor(), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ),
              const Spacer(),
              Text(DateFormat('MMM d, yyyy').format(DateTime.parse(announcement['createdAt'])), style: const TextStyle(color: Colors.black26, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            Text(announcement['title'] ?? 'Untitled', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), fontFamily: 'Inter')),
            const SizedBox(height: 12),
            Text('To: ${announcement['targetAudience']?['type']?.toString().toUpperCase() ?? 'ALL STUDENTS'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black38)),
            const Divider(height: 32),
            const Text('MESSAGE CONTENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1)),
            const SizedBox(height: 12),
            Text(
              announcement['description'] ?? 'No description provided.', 
              style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.7), height: 1.6, fontWeight: FontWeight.w500)
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    final p = announcement['priority'];
    if (p == 'urgent') return Colors.red;
    if (p == 'important') return Colors.orange;
    return Colors.green;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: const Text('This will remove it from all students dashboards. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ApiService().delete('/reminders/${announcement['_id']}');
                Navigator.pop(ctx);
                ref.invalidate(_adminAnnouncementsProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
