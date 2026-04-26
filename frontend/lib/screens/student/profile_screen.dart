import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0D47A1), Color(0xFF1976D2)])),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40),
                    CircleAvatar(radius: 44, backgroundImage: NetworkImage(user.displayAvatar), backgroundColor: Colors.white24),
                    const SizedBox(height: 12),
                    Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    Text(user.role.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontFamily: 'Inter', letterSpacing: 1)),
                  ]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingMd),
                child: Column(children: [
                  _InfoCard(items: [
                    _InfoItem(icon: Icons.email_outlined, label: 'Email', value: user.email),
                    if (user.className != null) _InfoItem(icon: Icons.class_outlined, label: 'Class', value: user.className!.replaceAll('AIDS ', '')),
                    _InfoItem(icon: Icons.business_outlined, label: 'Department', value: 'AIDS'),
                    if (user.rollNumber != null) _InfoItem(icon: Icons.badge_outlined, label: 'Roll Number', value: user.rollNumber!),
                  ]),
                  const SizedBox(height: 16),
                  _ActionCard(items: [
                    _ActionItem(icon: Icons.settings_outlined, label: 'Settings', onTap: () => context.push('/student/settings')),
                    _ActionItem(icon: Icons.notifications_outlined, label: 'Notification Preferences', onTap: () => _showNotificationPreferences(context, ref)),
                    _ActionItem(icon: Icons.lock_outlined, label: 'Change Password', onTap: () => _showChangePassword(context, ref)),
                    _ActionItem(icon: Icons.help_outline, label: 'Help & Support', onTap: () => _showHelpSupport(context, ref)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref.read(authStateProvider.notifier).logout();
                        if (context.mounted) context.go('/login');
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  void _showNotificationPreferences(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              value: true,
              onChanged: (v) {},
              activeColor: AppColors.primary,
            ),
            SwitchListTile(
              title: const Text('Email Alerts', style: TextStyle(fontFamily: 'Inter', fontSize: 14)),
              value: false,
              onChanged: (v) {},
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Save Changes')),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isLoading = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (newPassCtrl.text != confirmPassCtrl.text) {
                  setDialogState(() => error = 'Passwords do not match');
                  return;
                }
                if (newPassCtrl.text.length < 6) {
                  setDialogState(() => error = 'Password must be at least 6 characters');
                  return;
                }

                setDialogState(() {
                  isLoading = true;
                  error = null;
                });

                try {
                  await ref.read(authStateProvider.notifier).changePassword(
                    oldPassCtrl.text,
                    newPassCtrl.text,
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    setDialogState(() {
                      isLoading = false;
                      error = e.toString().contains('Exception: ') ? e.toString().split('Exception: ').last : 'Failed to change password';
                    });
                  }
                }
              },
              child: isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.help_outline, color: AppColors.primary), SizedBox(width: 8), Text('Help & Support', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600))]),
        content: const Text('For assistance, please contact the IT Helpdesk at:\n\n📧 support@campussync.edu\n📞 +1 (800) 123-4567\n\nOffice Hours: Mon-Fri, 9AM - 5PM', style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: AppColors.divider)),
    child: Column(children: items.map((item) {
      final isLast = item == items.last;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Icon(item.icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 12),
            Text(item.label, style: const TextStyle(color: AppColors.textHint, fontFamily: 'Inter', fontSize: 13)),
            const Spacer(),
            Text(item.value, style: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Inter', fontSize: 13)),
          ]),
        ),
        if (!isLast) const Divider(height: 1, indent: 48),
      ]);
    }).toList()),
  );
}

class _InfoItem { final IconData icon; final String label; final String value; const _InfoItem({required this.icon, required this.label, required this.value}); }

class _ActionCard extends StatelessWidget {
  final List<_ActionItem> items;
  const _ActionCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppDimens.radiusLg), border: Border.all(color: AppColors.divider)),
    child: Column(children: items.map((item) {
      final isLast = item == items.last;
      return Column(children: [
        ListTile(leading: Icon(item.icon, color: AppColors.textSecondary), title: Text(item.label, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)), trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint), onTap: item.onTap),
        if (!isLast) const Divider(height: 1, indent: 56),
      ]);
    }).toList()),
  );
}

class _ActionItem { final IconData icon; final String label; final VoidCallback onTap; const _ActionItem({required this.icon, required this.label, required this.onTap}); }
