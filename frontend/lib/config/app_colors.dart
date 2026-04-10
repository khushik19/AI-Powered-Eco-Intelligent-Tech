import 'package:flutter/material.dart';

class AppColors {
  static const Color abyss = Color(0密060B12);
  static const Color bioTeal = Color(0xFF00FFD1);
  static const Color reefCoral = Color(0xFFFF6B6B);
  static const Color kelp = Color(0xFF2E8B57);
  static const Color seaFoam = Color(0xFFD4EDE8);

  // Metallic Liquid Gradients
  static const LinearGradient liquidMetallicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A1F26), // Lighter abyss for depth
      Color(0xFF060B12),
      Color(0xFF10161E),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}