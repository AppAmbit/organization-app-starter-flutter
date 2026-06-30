import 'package:flutter/material.dart';

class AppColors {
  // Status
  static const Color success = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals (literal)
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color gray900 = Color(0xFF111827);
  static const Color gray600 = Color(0xFFAEAEB2);
  static const Color gray500 = Color(0xFF8E8E93);
  static const Color gray400 = Color(0xFF636366);
  static const Color gray350 = Color(0xFF48484A);
  static const Color gray300 = Color(0xFF3A3A3C);
  static const Color gray100 = Color(0xFF2C2C2E);
  static const Color overlayDark = Color(0xDD000000);
  static const Color overlayLight = Color(0x42000000);

  // Brand accent (ʻŌiwi green)
  static const Color accent = Color.fromARGB(255, 3, 189, 0);
  static const Color accentLive = Color.fromARGB(255, 3, 167, 0);

  // Backgrounds
  static const Color background = Color(0xFF141414);
  static const Color surface = Color(0xFF1E1E1E);

  // Text hierarchy
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9999AA);
  static const Color textTertiary = Color(0xFF666680);

  // Notification-specific
  static const Color notificationBorder = Color(0xFF1E3A5F);
  static const Color notificationIconBg = Color(0xFF2563EB);
  static const Color badgeRed = Color(0xFFFF3B30);

  // Carousel
  static const Color carouselDotActive = accent;
  static const Color carouselDotInactive = gray300;

  // Buttons
  static const Color buttonDefault = accent;
}
