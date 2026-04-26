import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../../widgets/app_widgets.dart';

class ManagePostsScreen extends ConsumerStatefulWidget {
  const ManagePostsScreen({super.key});

  @override
  ConsumerState<ManagePostsScreen> createState() => _ManagePostsScreenState();
}

class _ManagePostsScreenState extends ConsumerState<ManagePostsScreen> {
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(teacherDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(hintText: 'Search notices & assignments...', border: InputBorder.none),
            )
          : const Text('All My Posts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(teacherDashboardProvider),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          final allAssignments = (data['assignments'] as List?)?.map((a) => AssignmentModel.fromJson(a)).toList() ?? [];
          final allReminders = (data['recentReminders'] as List?)?.map((r) => ReminderModel.fromJson(r)).toList() ?? [];
          
          // Combine and Sort by date
          final List<dynamic> combined = [...allReminders, ...allAssignments];
          combined.sort((a, b) {
            final dateA = a is ReminderModel ? a.createdAt : (a as AssignmentModel).dueDate;
            final dateB = b is ReminderModel ? b.createdAt : (b as AssignmentModel).dueDate;
            return dateB.compareTo(dateA);
          });

          final filtered = combined.where((item) {
            final title = item is ReminderModel ? item.title : (item as AssignmentModel).title;
            return title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (filtered.isEmpty) {
            return const EmptyStateWidget(icon: Icons.search_off_rounded, message: 'No posts found matching your search');
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final item = filtered[i];
              final bool isReminder = item is ReminderModel;
              
              return _HistoryCard(
                item: item,
                isReminder: isReminder,
                onDelete: () => _confirmDelete(context, isReminder ? 'reminder' : 'assignment', item.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String type, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this $type? This action cannot be undone.', style: const TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        if (type == 'reminder') {
          await ReminderRepository().deleteReminder(id);
        } else {
          await AssignmentRepository().deleteAssignment(id);
        }
        ref.invalidate(teacherDashboardProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Post deleted successfully'), backgroundColor: AppColors.success));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
        }
      }
    }
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic item;
  final bool isReminder;
  final VoidCallback onDelete;

  const _HistoryCard({required this.item, required this.isReminder, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final title = isReminder ? item.title : item.title;
    final date = isReminder ? item.createdAt : item.dueDate;
    final color = isReminder ? AppColors.primary : AppColors.accent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isReminder ? Icons.campaign_rounded : Icons.assignment_rounded, color: color, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter'), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            isReminder 
              ? 'Notice • ${DateFormat('d MMM yyyy').format(date)}'
              : 'Assignment • Due ${DateFormat('d MMM yyyy').format(date)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Inter'),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
                onPressed: () => context.push(isReminder ? '/teacher-receipts/${item.id}' : '/teacher-assignment/${item.id}'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.accent),
                onPressed: () => context.push(isReminder ? '/teacher-edit-reminder/${item.id}' : '/teacher-edit-assignment/${item.id}'),
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
