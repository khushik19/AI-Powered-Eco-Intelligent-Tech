import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// Re-export so screens using glass_card.dart also get LiquidGlassCard.
export 'liquid_glass_card.dart' show LiquidGlassCard, LiquidGlassButton;

/// Legacy alias — kept so screens that use AppButton still compile.
/// This is the same widget as GlassButton.
typedef AppButton = GlassButton;

/// A glassmorphism card used throughout the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? fillColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.borderColor,
    this.fillColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? (fillColor ?? AppColors.glassWhite) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }
}

/// Styled action button used with named params across the app.
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final bool isOutline;

  const GlassButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.bioTeal;

    Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18,
              color: isOutline ? c : AppColors.midnightBlack),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isOutline ? c : AppColors.midnightBlack,
          ),
        ),
      ],
    );

    if (isOutline) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: label,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: AppColors.midnightBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 6,
          shadowColor: c.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: label,
      ),
    );
  }
}