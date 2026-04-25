import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'data/services/api_service.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (optional - skipped if not configured)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init skipped (not configured): $e');
    // App continues without Firebase - push notifications won't work
    // but all other features remain functional
  }

  // Initialize Hive for offline cache
  await Hive.initFlutter();
  await Hive.openBox('reminders_cache');
  await Hive.openBox('settings');

  // Initialize API service
  ApiService().init();

  runApp(const ProviderScope(child: CampusSyncApp()));
}

class CampusSyncApp extends ConsumerWidget {
  const CampusSyncApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'CampusSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
