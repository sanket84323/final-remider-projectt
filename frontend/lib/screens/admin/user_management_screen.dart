import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/api_service.dart';
import '../../providers/app_providers.dart';

final _usersProvider = FutureProvider.family<List<dynamic>, String>((ref, filterKey) async {
  final parts = filterKey.split('|');
  final role = parts[0];
  final search = parts[1];
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getUsers(role: role, search: search);
});

final _departmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(adminRepositoryProvider).getDepartments();
});

final _classesProvider = FutureProvider<List<String>>((ref) async {
  final response = await ApiService().get('/departments/69ed0cdf876ade57f7981861/classes');
  return List<String>.from(response.data['data']);
});

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});
  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  String _selectedRole = 'student';
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filterKey = '$_selectedRole|$_search';
    final usersAsync = ref.watch(_usersProvider(filterKey));

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddUserDialog(context),
            tooltip: 'Add User',
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search & Filter ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppDimens.paddingMd),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); }) : null,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              Row(children: ['student', 'teacher'].map((role) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedRole = role),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _selectedRole == role ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      border: Border.all(color: _selectedRole == role ? AppColors.primary : AppColors.divider),
                    ),
                    child: Text(role[0].toUpperCase() + role.substring(1), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedRole == role ? Colors.white : AppColors.textSecondary, fontFamily: 'Inter')),
                  ),
                ),
              )).toList()),
            ]),
          ),
          // ─── User List ─────────────────────────────────────────────────
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (users) {
                if (users.isEmpty) return const Center(child: Text('No users found', style: TextStyle(color: AppColors.textHint, fontFamily: 'Inter')));
                
                // ─── Grouping for Students ──────────────────────────────────
                if (_selectedRole == 'student') {
                  final Map<String, List<dynamic>> groups = {};
                  for (var u in users) {
                    final cls = u['className'] ?? 'Unassigned';
                    groups.putIfAbsent(cls, () => []).add(u);
                  }
                  
                  final sortedKeys = groups.keys.toList()..sort((a, b) {
                    int getPriority(String s) {
                      if (s.contains('SE')) return 1;
                      if (s.contains('TE')) return 2;
                      if (s.contains('BE')) return 3;
                      return 99;
                    }
                    final pA = getPriority(a);
                    final pB = getPriority(b);
                    if (pA != pB) return pA.compareTo(pB);
                    return a.compareTo(b); // Then alphabetically (A, B, C)
                  });
                  
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, groupIdx) {
                      final className = sortedKeys[groupIdx];
                      final classUsers = groups[className]!;
                      
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: AppColors.divider.withOpacity(0.3),
                          child: Text('CLASS: $className', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.2)),
                        ),
                        ...classUsers.map((user) => InkWell(
                          onTap: () => context.push('/admin-student-analytics/${user['_id']}'),
                          child: _UserTile(user: user, onDelete: () => _confirmDelete(user)),
                        )),
                      ]);
                    },
                  );
                }

                // ─── Flat list for Teachers ──────────────────────────────────
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: users.length,
                  itemBuilder: (context, i) => InkWell(
                    onTap: () => context.push('/admin-teacher-analytics/${users[i]['_id']}'),
                    child: _UserTile(user: users[i], onDelete: () => _confirmDelete(users[i])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    String role = 'student';
    String? selectedClass;
    String? selectedDeptId;
    
    // sectionCtrl.text = AppStrings.defaultDepartment; // No longer needed as we use dropdown

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add New User', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['student', 'teacher'].map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1)))).toList(),
                onChanged: (v) => setS(() => role = v!),
              ),
              const SizedBox(height: 12),
              // ─── Fixed Department (AIDS) ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                child: const Row(children: [
                  Icon(Icons.business_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('AIDS Department', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              if (role == 'student') ...[
                Consumer(builder: (ctx, ref, _) {
                  final classesAsync = ref.watch(_classesProvider);
                  return classesAsync.when(
                    data: (classes) => DropdownButtonFormField<String>(
                      value: selectedClass,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setS(() => selectedClass = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error loading classes'),
                  );
                }),
                const SizedBox(height: 12),
                TextField(controller: rollCtrl, decoration: const InputDecoration(labelText: 'Roll Number')),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }
                try {
                  await ref.read(adminRepositoryProvider).createUser({
                    'name': nameCtrl.text,
                    'email': emailCtrl.text.trim(),
                    'password': passCtrl.text,
                    'role': role,
                    'department': '69ed0cdf876ade57f7981861', // AIDS Dept ID
                    if (role == 'student') ...{
                      'className': selectedClass ?? '',
                      'rollNumber': rollCtrl.text,
                    }
                  });
                  ref.invalidate(_usersProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created!'), backgroundColor: AppColors.success));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['name']}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(adminRepositoryProvider).deleteUser(user['_id']);
                ref.invalidate(_usersProvider);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deleted'), backgroundColor: AppColors.success));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final dynamic user;
  final VoidCallback onDelete;
  const _UserTile({required this.user, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(user['name'] ?? '')}&background=1565C0&color=fff&size=64'),
        radius: 22,
      ),
      title: Text(user['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14)),
      subtitle: Text(user['email'] ?? '', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _RoleChip(role: user['role'] ?? ''),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') onDelete();
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
          ],
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint),
        ),
      ]),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});
  @override
  Widget build(BuildContext context) {
    final color = role == 'admin' ? const Color(0xFF7B1FA2) : role == 'teacher' ? const Color(0xFF00897B) : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppDimens.radiusFull)),
      child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter')),
    );
  }
}
