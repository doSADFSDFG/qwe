import 'package:flutter/material.dart';

ThemeData buildPosTheme() {
  const seedColor = Color(0xFF5BA8FF);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    fontFamily: 'Noto Sans KR',
  );

  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF5F6FA),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.black87,
      displayColor: Colors.black87,
    ).copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 2,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.06)),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: seedColor, width: 1.8),
      ),
    ),
    tabBarTheme: base.tabBarTheme.copyWith(
      indicator: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.black54,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
    ),
  );
}
