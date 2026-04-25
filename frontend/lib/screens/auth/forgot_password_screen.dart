import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _isLoading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingLg),
        child: _sent ? _SuccessView(email: _emailCtrl.text) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Enter your college email and we\'ll send you a link to reset your password.', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 15, height: 1.5)),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) : const Text('Send Reset Link'),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: AppColors.successContainer, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Email Sent!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          Text('We\'ve sent password reset instructions to\n$email', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          OutlinedButton(onPressed: () => context.go('/login'), child: const Text('Back to Login')),
        ],
      ),
    );
  }
}
