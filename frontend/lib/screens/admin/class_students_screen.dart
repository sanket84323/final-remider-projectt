import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/api_service.dart';

final _classStudentsProvider = FutureProvider.family<List<dynamic>, String>((ref, className) async {
  final response = await ApiService().get('/users?role=student&className=${Uri.encodeComponent(className)}');
  return response.data['data'];
});

final _allClassesProvider = FutureProvider<List<String>>((ref) async {
  final response = await ApiService().get('/departments/69ed6632b8a6312aac7c38e8/classes');
  return List<String>.from(response.data['data']);
});

class ClassStudentsScreen extends ConsumerWidget {
  final String className;
  const ClassStudentsScreen({super.key, required this.className});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(_classStudentsProvider(className));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('$className Students'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (students) {
          if (students.isEmpty) {
            return const Center(child: Text('No students found in this class.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final s = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => context.push('/admin-student-analytics/${s['_id']}'),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(s['name'])}&background=random'),
                  ),
                  title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Roll No: ${s['rollNumber'] ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    onPressed: () => _showEditDialog(context, ref, s),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, dynamic student) {
    final nameCtrl = TextEditingController(text: student['name']);
    final rollCtrl = TextEditingController(text: student['rollNumber']);
    String selectedClass = student['className'];

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (ctx, ref, _) {
          final classesAsync = ref.watch(_allClassesProvider);
          return AlertDialog(
            title: const Text('Edit Student Info'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 16),
                TextField(controller: rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number')),
                const SizedBox(height: 16),
                classesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (classes) => DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => selectedClass = v!,
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ApiService().patch('/users/${student['_id']}', data: {
                      'name': nameCtrl.text.trim(),
                      'rollNumber': rollCtrl.text.trim(),
                      'className': selectedClass,
                    });
                    ref.invalidate(_classStudentsProvider(className));
                    if (ctx.mounted) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student updated successfully'), backgroundColor: AppColors.success));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
