import 'package:flutter/material.dart';

abstract final class Palette {
  static const forest = Color(0xFF243B32),
      ivory = Color(0xFFF8F4EC),
      gold = Color(0xFFC9AC78),
      cream = Color(0xFFEDE3D3),
      sage = Color(0xFFA3B5A0),
      brown = Color(0xFF49352D);
}

ThemeData weddingTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Palette.forest,
      surface: Palette.ivory,
    ),
    scaffoldBackgroundColor: Palette.ivory,
    fontFamily: 'DM Sans',
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: Palette.forest, displayColor: Palette.forest)
        .copyWith(
          displayLarge: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 54,
            height: 1.08,
            color: Palette.forest,
          ),
          headlineLarge: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 40,
            height: 1.12,
            color: Palette.forest,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 30,
            height: 1.15,
            color: Palette.forest,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Cormorant Garamond',
            fontSize: 25,
            color: Palette.forest,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'DM Sans',
            fontSize: 14,
            height: 1.65,
            color: Palette.forest,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.ivory,
      foregroundColor: Palette.forest,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.sage),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.forest,
        foregroundColor: Palette.ivory,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Palette.ivory,
      indicatorColor: Palette.cream,
      height: 76,
    ),
    dividerTheme: const DividerThemeData(color: Palette.cream),
  );
}
