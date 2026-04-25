import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

final _departmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDepartments();
});

final _classesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getClasses();
});

class DepartmentManagementScreen extends ConsumerStatefulWidget {
  const DepartmentManagementScreen({super.key});
  @override
  ConsumerState<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends ConsumerState<DepartmentManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Structure'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Departments'),
            Tab(text: 'Classes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DepartmentList(),
          _ClassList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0 ? _showAddDeptDialog() : _showAddClassDialog(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddDeptDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Department'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Artificial Intelligence)')),
          const SizedBox(height: 12),
          TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Code (e.g. AIDS)')),
          const SizedBox(height: 12),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).createDepartment({
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'description': descCtrl.text.trim(),
                });
                ref.invalidate(_departmentsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog() {
    final nameCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    String? selectedDept;
    
    showDialog(
      context: context,
      builder: (ctx) => Consumer(builder: (ctx, ref, _) {
        final deptsAsync = ref.watch(_departmentsProvider);
        return deptsAsync.when(
          data: (depts) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
            title: const Text('Add Class'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Class Name (e.g. SE)')),
              const SizedBox(height: 12),
              TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'Section (e.g. A)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedDept,
                decoration: const InputDecoration(labelText: 'Department'),
                items: depts.map((d) => DropdownMenuItem(value: d['_id'].toString(), child: Text(d['code']))).toList(),
                onChanged: (v) => setS(() => selectedDept = v),
              ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDept == null) return;
                  try {
                    await ref.read(adminRepositoryProvider).createClass({
                      'name': nameCtrl.text.trim(),
                      'section': sectionCtrl.text.trim().toUpperCase(),
                      'department': selectedDept,
                    });
                    ref.invalidate(_classesProvider);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Create'),
              ),
            ],
          )),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading depts: $e')),
        );
      }),
    );
  }
}

class _DepartmentList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(_departmentsProvider);
    return deptsAsync.when(
      data: (depts) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: depts.length,
        itemBuilder: (ctx, i) {
          final d = depts[i];
          return Card(
            child: ListTile(
              title: Text(d['name']),
              subtitle: Text(d['code']),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  await ref.read(adminRepositoryProvider).deleteDepartment(d['_id']);
                  ref.invalidate(_departmentsProvider);
                },
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ClassList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(_classesProvider);
    return classesAsync.when(
      data: (classes) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: classes.length,
        itemBuilder: (ctx, i) {
          final c = classes[i];
          return Card(
            child: ListTile(
              title: Text('${c['name']} - ${c['section']}'),
              subtitle: Text(c['department']?['code'] ?? 'No Dept'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  await ref.read(adminRepositoryProvider).deleteClass(c['_id']);
                  ref.invalidate(_classesProvider);
                },
              ),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
