import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authStateProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
      final role = ref.read(authStateProvider).valueOrNull?.role;
      if (mounted && role != null) {
        if (role == 'student') context.go('/student');
        else if (role == 'teacher') context.go('/teacher');
        else if (role == 'admin') context.go('/admin');
        else context.go('/student');
      }
    } catch (e) {
      if (mounted) {
        setState(() { _errorMessage = _parseError(e.toString()); });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _parseError(String error) {
    if (error.contains('Exception: ')) {
      return error.split('Exception: ').last.trim();
    }
    if (error.contains('401') || error.contains('Invalid')) return 'Invalid email or password';
    if (error.contains('connection')) return 'Unable to connect to server';
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // ─── Header ──────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Welcome back 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              const Text('Sign in to your CampusSync account', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter')),
              const SizedBox(height: 36),

              // ─── Error Banner ─────────────────────────────────────────────
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontFamily: 'Inter'))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── Form ─────────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Enter your college email',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go('/signup'),
                          child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Demo Credentials ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      const Text('Demo Credentials', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'Inter', fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    _credTile('Admin', 'admin@campussync.edu', 'Admin@123'),
                    _credTile('Teacher', 'anita@campussync.edu', 'Teacher@123'),
                    _credTile('Student', 'arjun@student.edu', 'Student@123'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _credTile(String role, String email, String pass) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: GestureDetector(
      onTap: () {
        _emailCtrl.text = email;
        _passCtrl.text = pass;
      },
      child: Text('• $role: $email / $pass', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontFamily: 'Inter')),
    ),
  );
}
