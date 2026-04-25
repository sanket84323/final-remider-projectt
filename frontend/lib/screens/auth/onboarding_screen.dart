import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFF1565C0),
      title: 'Real-Time Notifications',
      subtitle: 'Get instant alerts for reminders, assignments, and important announcements from your teachers.',
    ),
    _OnboardingPage(
      icon: Icons.assignment_rounded,
      color: const Color(0xFF00897B),
      title: 'Track Assignments',
      subtitle: 'Never miss a deadline. View, track, and mark assignments complete — all in one place.',
    ),
    _OnboardingPage(
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFFFF8F00),
      title: 'Smart Calendar',
      subtitle: 'View all your exams, tasks, and events in a beautiful calendar. Stay ahead of your schedule.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Skip', style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Inter')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingXl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: page.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 72, color: page.color),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, fontFamily: 'Inter', color: AppColors.textPrimary, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingLg),
              child: _currentPage == _pages.length - 1
                  ? ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Get Started'),
                    )
                  : ElevatedButton(
                      onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: const Text('Next'),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _OnboardingPage({required this.icon, required this.color, required this.title, required this.subtitle});
}
