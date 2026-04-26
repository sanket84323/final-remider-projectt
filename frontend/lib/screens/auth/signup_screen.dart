import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'student';
  String? _selectedClassDropdown;
  final List<String> _classOptions = AppStrings.studentClasses;

  @override
  void initState() {
    super.initState();
    _sectionCtrl.text = AppStrings.defaultDepartment;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _classCtrl.dispose();
    _sectionCtrl.dispose();
    _rollCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await ref.read(authStateProvider.notifier).register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        role: _selectedRole,
        className: _selectedRole == 'student' 
            ? (_selectedClassDropdown == 'Other' || _selectedClassDropdown == null ? _classCtrl.text.trim() : _selectedClassDropdown) 
            : null,
        section: _selectedRole == 'student' && _sectionCtrl.text.isNotEmpty ? _sectionCtrl.text.trim() : null,
        rollNumber: _selectedRole == 'student' && _rollCtrl.text.isNotEmpty ? _rollCtrl.text.trim() : null,
      );
      
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
    if (error.contains('409') || error.contains('already exists')) return 'An account with this email already exists';
    if (error.contains('400') || error.contains('Validation')) return 'Please check your input and try again';
    if (error.contains('connection')) return 'Unable to connect to server';
    return 'Registration failed. Please try again.';
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
              const SizedBox(height: 20),
              // ─── Back Button ──────────────────────────────────────────────
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: AppColors.primary, size: 22),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Header ──────────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              const Text('Student Registration ✨', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary, letterSpacing: -0.3)),
              const SizedBox(height: 8),
              const Text('Create your account to stay connected', style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontFamily: 'Inter')),
              const SizedBox(height: 28),

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

              // Role selection removed - signup is for students only
              const SizedBox(height: 8),

              // ─── Form ─────────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outlined),
                        hintText: 'Enter your full name',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (v.trim().length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                        hintText: 'Min. 6 characters',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),

                    // ─── Student-only fields ────────────────────────────────
                    if (_selectedRole == 'student') ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.primary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Mandatory: Please add your class details to complete registration', style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.8), fontFamily: 'Inter'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedClassDropdown,
                              decoration: const InputDecoration(
                                labelText: 'Class',
                                prefixIcon: Icon(Icons.class_rounded),
                              ),
                              items: _classOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setState(() => _selectedClassDropdown = val),
                              validator: (v) => v == null ? 'Class is required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sectionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                hintText: 'AIDS',
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedClassDropdown == 'Other') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _classCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Custom Class Name',
                            prefixIcon: Icon(Icons.class_outlined),
                            hintText: 'e.g. CS-3A',
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _rollCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Roll Number',
                          prefixIcon: Icon(Icons.badge_outlined),
                          hintText: 'e.g. CS21001',
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Roll Number is required' : null,
                      ),
                    ],

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Create Account'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter', fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: const Text('Sign In', style: TextStyle(color: AppColors.primary, fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
