import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;

  const LiquidGlassCard({
    super.key, 
    required this.child, 
    this.width, 
    this.height
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.abyss, // Dark base
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          width: 2,
          color: AppColors.bioTeal.withOpacity(0.3), // Thin teal "wire" edge
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2630), // Metallic sheen
            AppColors.abyss,
          ],
        ),
        boxShadow: [
          // The "Liquid" glow effect
          BoxShadow(
            color: AppColors.bioTeal.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: -10,
          ),
          // Sharp specular reflection
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            offset: const Offset(-5, -5),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}