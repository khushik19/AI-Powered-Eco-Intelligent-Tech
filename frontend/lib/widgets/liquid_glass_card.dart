import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.abyss,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.bioTeal.withOpacity(0.3),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.abyss,
            AppColors.backgroundSecondary,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bioTeal.withOpacity(0.15),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
