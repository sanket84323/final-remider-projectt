import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _classesProvider = FutureProvider<List<String>>((ref) async {
  final response = await ApiService().get('/departments/69ed6632b8a6312aac7c38e8/classes');
  return List<String>.from(response.data['data']);
});

class ClassManagementScreen extends ConsumerWidget {
  const ClassManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(_classesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Manage Classes'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: classesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (classes) => ListView(
          padding: const EdgeInsets.all(AppDimens.paddingMd),
          children: [
            const Text('AIDS Department Classes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textHint)),
            const SizedBox(height: 16),
            ...classes.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => context.push('/admin-class-students/${Uri.encodeComponent(c)}'),
                leading: const Icon(Icons.class_rounded, color: AppColors.primary),
                title: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                  onPressed: () => _showRemoveClassDialog(context, ref, c, classes),
                ),
              ),
            )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add New Class'),
              onPressed: () => _showAddClassDialog(context, ref),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddClassDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Class'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'e.g. BE A')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isEmpty) return;
              try {
                await ApiService().post('/departments/69ed6632b8a6312aac7c38e8/classes', data: {'className': ctrl.text.trim()});
                ref.invalidate(_classesProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRemoveClassDialog(BuildContext context, WidgetRef ref, String className, List<String> allCheck) {
    final confirmCtrl = TextEditingController();
    String action = 'delete';
    String? targetClass;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Remove $className'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('This action is permanent.', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              const Text('What should happen to the students in this class?', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: action,
                items: const [
                  DropdownMenuItem(value: 'delete', child: Text('Delete all students')),
                  DropdownMenuItem(value: 'move', child: Text('Shift students to another class')),
                ],
                onChanged: (v) => setS(() => action = v!),
              ),
              if (action == 'move') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: targetClass,
                  hint: const Text('Select target class'),
                  items: allCheck.where((c) => c != className).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setS(() => targetClass = v),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Please type "$className" to confirm:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(controller: confirmCtrl, decoration: const InputDecoration(hintText: 'Class Name')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                if (confirmCtrl.text != className) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class name does not match')));
                  return;
                }
                if (action == 'move' && targetClass == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a target class')));
                  return;
                }
                try {
                  await ApiService().delete('/departments/69ed6632b8a6312aac7c38e8/classes', data: {
                    'className': className,
                    'action': action,
                    'targetClass': targetClass
                  });
                  ref.invalidate(_classesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Confirm Removal', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
