// Colors, strings, and app-wide constants
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppColors {
  // ─── Primary (Deep Blue) ────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryContainer = Color(0xFFE3F2FD);

  // ─── Accent (Amber/Orange) ──────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF8F00);
  static const Color accentLight = Color(0xFFFFA000);
  static const Color accentContainer = Color(0xFFFFF8E1);

  // ─── Semantic Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningContainer = Color(0xFFFFFDE7);
  static const Color error = Color(0xFFC62828);
  static const Color errorContainer = Color(0xFFFFEBEE);

  // ─── Priority Colors ─────────────────────────────────────────────────────────
  static const Color priorityNormal = Color(0xFF1565C0);
  static const Color priorityImportant = Color(0xFFFF8F00);
  static const Color priorityUrgent = Color(0xFFC62828);

  // ─── Neutral ─────────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFF8F9FE);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E6F0);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF5A6070);
  static const Color textHint = Color(0xFF9EA8B8);

  // ─── Dark Mode ───────────────────────────────────────────────────────────────
  static const Color darkSurface = Color(0xFF0F1117);
  static const Color darkCard = Color(0xFF1A1D2E);
  static const Color darkCardAlt = Color(0xFF222438);
}

class AppStrings {
  static const String appName = 'CampusSync';
  static const String tagline = 'Secure Academic Management';
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    } else {
      return 'http://127.0.0.1:5000/api';
    }
  }

  static const List<String> studentClasses = [
    'AIDS SE A', 'AIDS SE B', 'AIDS SE C',
    'AIDS TE A', 'AIDS TE B', 'AIDS TE C',
    'AIDS BE A', 'AIDS BE B', 'AIDS BE C'
  ];

  static const String defaultDepartment = 'AIDS';
}

class AppDimens {
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 100.0;

  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  static const double cardElevation = 2.0;
}

class AppIcons {
  static const String logo = 'assets/images/logo.png';
  static const String onboarding1 = 'assets/images/onboarding1.png';
}
