import 'package:flutter/material.dart';

class AppColors {
  // Core palette
  static const Color abyss          = Color(0xFF060B12);
  static const Color midnightBlack  = Color(0xFF05070D);
  static const Color neonMoss       = Color(0xFF7CFFB2);
  static const Color electricCyan   = Color(0xFF00E5FF);
  static const Color mutedOlive     = Color(0xFF5A7D6A);
  static const Color softGrey       = Color(0xFFCFCFCF);

  // Semantic backgrounds
  static const Color background          = Color(0xFF05070D);
  static const Color backgroundSecondary = Color(0xFF080C14);

  // Legacy aliases
  static const Color forestGreen  = mutedOlive;
  static const Color oliveGreen   = neonMoss;
  static const Color cream        = softGrey;
  static const Color dustyRose    = Color(0xFF5A7D6A);
  static const Color tealBlue     = electricCyan;
  static const Color cosmicPurple = electricCyan;
  static const Color nebulaBlue   = neonMoss;
  static const Color stardustGold = neonMoss;
  static const Color cosmicGreen  = neonMoss;
  static const Color deepViolet   = mutedOlive;

  // Glass / overlay
  static const Color glassWhite       = Color(0x0DFFFFFF);
  static const Color glassBorder      = Color(0x26FFFFFF);
  static const Color glassWhiteStrong = Color(0x1AFFFFFF);

  // Text
  static const Color textPrimary   = Color(0xFFCFCFCF);
  static const Color textSecondary = Color(0xFF9ECFB8);
  static const Color textMuted     = Color(0xFF5A7D6A);

  // Extra palette
  static const Color bioTeal   = Color(0xFF00E5FF);
  static const Color kelp      = Color(0xFF7CFFB2);
  static const Color reefCoral = Color(0xFFEF476F);
  static const Color seaFoam   = Color(0xFF9ECFB8);

  // Status
  static const Color success = neonMoss;
  static const Color warning = Color(0xFF00E5FF);
  static const Color error   = Color(0xFFEF476F);

  // Star colors
  static const List<Color> starColors = [
    Color(0xFF7CFFB2),
    Color(0xFF00E5FF),
    Color(0xFFCFCFCF),
  ];

  // Metallic Liquid Gradients (kept from stash — non-conflicting addition)
  static const LinearGradient liquidMetallicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1F26),
      Color(0xFF060B12),
      Color(0xFF10161E),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
