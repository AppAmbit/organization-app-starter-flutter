import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme textTheme(BuildContext context) =>
      GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

  static ThemeData light(TextTheme textTheme) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.white,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.white,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            letterSpacing: -0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.gray500,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        ),
      );

  static ThemeData dark(TextTheme textTheme) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: textTheme.apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.surface,
          titleTextStyle: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.gray500,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
        ),
        dividerColor: AppColors.gray300,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.gray400,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.accent.withValues(alpha: 0.4)
                : AppColors.gray300,
          ),
        ),
      );
}
