import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _offlineCache = true;

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop())),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            value: isDark,
            onChanged: (val) => ref.read(themeProvider.notifier).state = val,
            title: const Text('Dark Mode', style: TextStyle(fontFamily: 'Inter')),
            subtitle: const Text('Switch between light and dark theme', style: TextStyle(fontFamily: 'Inter', fontSize: 12)),
            secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
            activeColor: AppColors.primary,
          ),
          _SectionHeader(title: 'Security'),
          _SettingsTile(
            icon: Icons.lock_open_rounded, 
            title: 'Change Password', 
            subtitle: 'Update your login credentials',
            onTap: () => context.push('/forgot-password'),
          ),
          _SettingsTile(
            icon: Icons.security_rounded, 
            title: 'Reset Login Keys', 
            subtitle: 'Force logout from all other devices',
            onTap: () => _showConfirmation(context, 'Reset Security Keys?', 'This will sign you out of all other devices.', () {}),
          ),
          _SectionHeader(title: 'Notifications'),
          _SettingsTile(icon: Icons.notifications_outlined, title: 'Push Notifications', subtitle: 'Receive alerts for reminders', trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary)),
          _SettingsTile(icon: Icons.priority_high_rounded, title: 'Urgent Alerts', subtitle: 'Full-screen alerts for urgent notices', trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary)),
          _SectionHeader(title: 'Data & Storage'),
          _SettingsTile(
            icon: Icons.storage_outlined, 
            title: 'Offline Cache', 
            subtitle: 'Store recent reminders for offline access', 
            trailing: Switch(
              value: _offlineCache, 
              onChanged: (v) => setState(() => _offlineCache = v),
              activeColor: AppColors.primary,
            )
          ),
          _SettingsTile(
            icon: Icons.delete_outline_rounded, 
            title: 'Clear Cache', 
            subtitle: 'Remove cached data and logout', 
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            onTap: () => _showConfirmation(context, 'Clear All Cache?', 'This will remove all offline data and log you out for security.', () async {
              await ref.read(authStateProvider.notifier).logout();
              if (mounted) context.go('/login');
            }),
          ),
          _SectionHeader(title: 'About'),
          _SettingsTile(icon: Icons.info_outline, title: 'App Version', subtitle: '1.0.0 (Build 1)', trailing: null),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', subtitle: '', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)),
        ],
      ),
    );
  }

  void _showConfirmation(BuildContext context, String title, String msg, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: const Text('Confirm', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint, fontFamily: 'Inter', letterSpacing: 0.8)),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: AppColors.primary, size: 22),
    title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
    subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)) : null,
    trailing: trailing,
  );
}

