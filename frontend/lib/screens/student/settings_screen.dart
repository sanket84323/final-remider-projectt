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
          _SectionHeader(title: 'Support & Contact'),
          _SettingsTile(
            icon: Icons.person_outline_rounded, 
            title: 'Lead Developer', 
            subtitle: 'Sanket Solanke', 
            trailing: const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
            onTap: () => _showDeveloperInfo(context),
          ),
          _SettingsTile(
            icon: Icons.mail_outline_rounded, 
            title: 'Technical Support', 
            subtitle: 'solankesanket8432@gmail.com', 
            trailing: const Icon(Icons.copy_rounded, color: AppColors.textHint, size: 18),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email copied to clipboard')));
            },
          ),
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline, 
            title: 'About CampusSync', 
            subtitle: 'Learn more about the project', 
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            onTap: () => _showAboutDialog(context),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined, 
            title: 'Privacy Policy', 
            subtitle: 'How we handle your data', 
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            onTap: () => _showPrivacyPolicy(context),
          ),
          _SettingsTile(icon: Icons.code_rounded, title: 'App Version', subtitle: '1.0.0 (Build 1)', trailing: null),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CampusSync',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school_rounded, color: AppColors.primary, size: 40),
      children: [
        const Text(
          'CampusSync is an advanced academic management and notification system designed to streamline communication between the HOD, Teachers, and Students.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const Text('• Real-time Department Analytics\n• Secure Assignment Submission\n• Priority Notification System\n• Multi-role Dashboard support', style: TextStyle(fontSize: 13)),
      ],
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Developer Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(radius: 32, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 40)),
            const SizedBox(height: 16),
            const Text('Sanket Solanke', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Text('Lead Full-Stack Developer', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('App Created Date:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const Text('April 26, 2026', style: TextStyle(fontSize: 14, color: AppColors.primary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. CampusSync only collects necessary academic data like your name, email, and class enrollment to facilitate communication. We do not share your personal data with third-party advertisers. All assignment submissions are stored securely and are only accessible by your respective teachers and the department HOD.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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

