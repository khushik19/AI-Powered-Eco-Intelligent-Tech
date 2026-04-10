import 'package:flutter/material.dart';

class AppColors {
  // New Brand Palette
  static const Color forestGreen = Color(0xFF0A3323);   // primary dark green
  static const Color oliveGreen = Color(0xFF839958);    // secondary olive
  static const Color cream = Color(0xFFF7F4D5);         // light cream/background text
  static const Color dustyRose = Color(0xFFD3968C);     // accent rose
  static const Color tealBlue = Color(0xFF105666);      // deep teal

  // Backgrounds (keep cosmic dark feel, tinted with new palette)
  static const Color background = Color(0xFF040F08);
  static const Color backgroundSecondary = Color(0xFF081A0E);

  // Aliases for easy migration
  static const Color cosmicPurple = tealBlue;
  static const Color nebulaBlue = oliveGreen;
  static const Color stardustGold = cream;
  static const Color cosmicGreen = oliveGreen;
  static const Color deepViolet = forestGreen;

  // Glass effect
  static const Color glassWhite = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x26FFFFFF);
  static const Color glassWhiteStrong = Color(0x1AFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFF7F4D5);    // cream
  static const Color textSecondary = Color(0xFFB8C99A);  // light olive
  static const Color textMuted = Color(0xFF6B8A72);

  // Status
  static const Color success = Color(0xFF839958);
  static const Color warning = Color(0xFFD3968C);
  static const Color error = Color(0xFFEF476F);

  // Star colors for animation
  static const List<Color> starColors = [
    Color(0xFFF7F4D5),
    Color(0xFF839958),
    Color(0xFF105666),
    Color(0xFF0A3323),
    Color(0xFFD3968C),
  ];
}