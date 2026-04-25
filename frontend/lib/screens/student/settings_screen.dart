import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _SectionHeader(title: 'Notifications'),
          _SettingsTile(icon: Icons.notifications_outlined, title: 'Push Notifications', subtitle: 'Receive alerts for reminders', trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary)),
          _SettingsTile(icon: Icons.priority_high_rounded, title: 'Urgent Alerts', subtitle: 'Full-screen alerts for urgent notices', trailing: Switch(value: true, onChanged: (_) {}, activeColor: AppColors.primary)),
          _SectionHeader(title: 'Data & Storage'),
          _SettingsTile(icon: Icons.storage_outlined, title: 'Offline Cache', subtitle: 'Store recent reminders for offline access', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)),
          _SettingsTile(icon: Icons.delete_outline_rounded, title: 'Clear Cache', subtitle: 'Remove cached data', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)),
          _SectionHeader(title: 'About'),
          _SettingsTile(icon: Icons.info_outline, title: 'App Version', subtitle: '1.0.0 (Build 1)', trailing: null),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', subtitle: '', trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint)),
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
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primary, size: 22),
    title: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
    subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textHint)) : null,
    trailing: trailing,
  );
}
