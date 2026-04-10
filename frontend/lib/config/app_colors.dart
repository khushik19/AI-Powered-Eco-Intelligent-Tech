import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const Color abyss = Color(0xFF060B12);
  static const Color bioTeal = Color(0xFF00FFD1);
  static const Color reefCoral = Color(0xFFFF6B6B);
  static const Color kelp = Color(0xFF2E8B57);
  static const Color seaFoam = Color(0xFFD4EDE8);

  // Aliases
  static const Color forestGreen = kelp;
  static const Color oliveGreen = kelp;
  static const Color tealBlue = bioTeal;
  static const Color electricCyan = bioTeal;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = seaFoam;
  static const Color textMuted = Color(0xFF5A626C);
  static const Color glassBorder = Color(0x3300FFD1);
  static const Color glassWhite = Colors.white10;
  static const Color error = reefCoral;
  static const Color cream = seaFoam;
  static const Color dustyRose = reefCoral;

  // Cosmic palette
  static const Color cosmicPurple = Color(0xFF7B61FF);
  static const Color nebulaBlue = bioTeal;
  static const Color stardustGold = Color(0xFFFFD700);

  // Missing colors referenced across the app
  static const Color neonMoss = Color(0xFF39FF14);
  static const Color softGrey = Color(0xFF8A9BA8);
  static const Color background = abyss;
  static const Color backgroundSecondary = Color(0xFF0D1B2A);
  static const Color midnightBlack = Color(0xFF020408);
  static const Color cosmicGreen = Color(0xFF00C896);
  static const Color glassWhiteStrong = Color(0x66FFFFFF);

  // Star colors list for cosmic background
  static const List<Color> starColors = [
    Colors.white,
    bioTeal,
    seaFoam,
    Color(0xFFB0E0FF),
    stardustGold,
  ];
}
