import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    // Navigate after auth check
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  void _navigate() {
    final authState = ref.read(authStateProvider);
    // If still loading, wait for it to resolve then navigate
    if (authState.isLoading) {
      // Listen for auth to complete
      ref.listenManual(authStateProvider, (_, next) {
        if (!next.isLoading && mounted) {
          _doNavigate(next.valueOrNull);
        }
      });
      return;
    }
    _doNavigate(authState.valueOrNull);
  }

  void _doNavigate(dynamic user) {
    if (!mounted) return;
    if (user == null) {
      context.go('/onboarding');
    } else if (user.role == 'student') {
      context.go('/student');
    } else if (user.role == 'teacher') {
      context.go('/teacher');
    } else {
      context.go('/admin');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF1976D2)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.school_rounded, size: 56, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'CampusSync',
                    style: TextStyle(
                      fontSize: 34, fontWeight: FontWeight.w700,
                      color: Colors.white, fontFamily: 'Inter', letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Academic Management',
                    style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 60),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.white.withOpacity(0.7),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
