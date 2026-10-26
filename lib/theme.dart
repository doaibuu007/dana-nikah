import 'package:flutter/material.dart';

/// Palet warna elegan & romantis (dusty pink / rose gold).
class AppColors {
  static const rose = Color(0xFFB5677A);
  static const roseDark = Color(0xFF8E4A5C);
  static const roseSoft = Color(0xFFF6E3E6);
  static const blush = Color(0xFFE8B4B8);
  static const gold = Color(0xFFC9A27E);
  static const cream = Color(0xFFFFF8F6);
  static const border = Color(0xFFEBD8DC);
  static const ink = Color(0xFF3D2C33);
  static const muted = Color(0xFF8A7A80);
  static const danger = Color(0xFFD1495B);
  static const success = Color(0xFF4F9D7E);
  static const warning = Color(0xFFE0A458);
}

const LinearGradient heroGradient = LinearGradient(
  colors: [Color(0xFFE8B4B8), Color(0xFFB5677A)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Warna untuk grafik & penanda penyetor.
const List<Color> palette = <Color>[
  Color(0xFFB5677A),
  Color(0xFF7A9E9F),
  Color(0xFFD4A373),
  Color(0xFF9C89B8),
  Color(0xFFE5989B),
  Color(0xFF6D8A96),
  Color(0xFFB08968),
  Color(0xFF84A59D),
  Color(0xFFF28482),
  Color(0xFF8E7DBE),
  Color(0xFFC9ADA7),
  Color(0xFF5E6472),
];

Color paletteColor(int index) => palette[index.abs() % palette.length];

ThemeData buildTheme() {
  final base = ColorScheme.fromSeed(seedColor: AppColors.rose);
  final scheme = base.copyWith(
    primary: AppColors.rose,
    onPrimary: Colors.white,
    secondary: AppColors.gold,
    surface: AppColors.cream,
    onSurface: AppColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
  );
}
