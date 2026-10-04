import 'package:flutter/material.dart';

/// 应用主题（Material 3）
abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E6FFF)),
    );
  }
}
