import 'package:flutter/material.dart';

final class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF6C3FC5);

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
