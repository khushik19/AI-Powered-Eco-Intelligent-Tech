<<<<<<< HEAD
<<<<<<< HEAD
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
=======
// glass_card.dart — wraps LiquidGlassCard so all existing screens
// automatically get the iOS 26 liquid glass effect with zero import changes.
export 'liquid_glass_card.dart' show LiquidGlassCard, LiquidGlassButton;

import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import 'liquid_glass_card.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurStrength;
  final Color? borderColor;
  final Color? fillColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final Gradient? gradient;
>>>>>>> 9a1a991c4a0ff6488c71bc926a7e96f24c21bd19
=======
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// ignore: unused_import
import 'liquid_glass_card.dart'; // kept for backward-compat re-exports

/// A glassmorphism card. Accepts all the params used across the app.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? borderColor;
  final Color? fillColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd

  const GlassCard({
    super.key,
    required this.child,
<<<<<<< HEAD
<<<<<<< HEAD
    this.padding,
    this.borderRadius = 16.0,
=======
    this.borderRadius = 22,
    this.padding,
    this.margin,
    this.blurStrength = 28,
    this.borderColor,
    this.fillColor,
    this.onTap,
    this.width,
    this.height,
    this.gradient,
>>>>>>> 9a1a991c4a0ff6488c71bc926a7e96f24c21bd19
=======
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.borderColor,
    this.fillColor,
    this.gradient,
    this.onTap,
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
  });

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
<<<<<<< HEAD
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      child: child,
    );
  }
}
=======
    final tint =
        fillColor ?? borderColor?.withOpacity(1.0) ?? AppColors.electricCyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: tint.withOpacity(0.12),
              blurRadius: 28,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Heavy backdrop blur
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: blurStrength, sigmaY: blurStrength),
                child: Container(color: Colors.transparent),
              ),
              // Dark tinted fill
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.midnightBlack.withOpacity(0.70),
                          AppColors.midnightBlack.withOpacity(0.50),
                          tint.withOpacity(0.07),
                        ],
                        stops: const [0.0, 0.65, 1.0],
                      ),
                ),
              ),
              // Specular highlight
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: borderRadius * 1.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(borderRadius)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.26),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              // Left edge rim
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(borderRadius)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.40),
                        Colors.white.withOpacity(0.04),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: borderColor ?? Colors.white.withOpacity(0.13),
                    width: 1.0,
                  ),
                ),
              ),
              // Bottom depth shadow
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: borderRadius,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(borderRadius)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.20),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// GlassButton — uses new palette; primary buttons glow neon
class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool isOutline;
  final double width;
  final IconData? icon;
=======
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

/// A styled action button — solid or outline variant.
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  final bool isOutline;
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd

  const GlassButton({
    super.key,
    required this.text,
    required this.onTap,
<<<<<<< HEAD
    this.color,
    this.isOutline = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.electricCyan;
    // For filled buttons on the new palette, label is dark (midnight black)
    final labelColor =
        widget.isOutline ? color : AppColors.midnightBlack;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.isOutline
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 22,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.transparent),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: widget.isOutline
                        ? LinearGradient(
                            colors: [
                              AppColors.midnightBlack.withOpacity(0.55),
                              AppColors.midnightBlack.withOpacity(0.38),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.92),
                              color.withOpacity(0.68),
                            ],
                          ),
                    border: Border.all(
                      color: widget.isOutline
                          ? color.withOpacity(0.75)
                          : Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.30),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: labelColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.text,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: labelColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
=======
    this.icon,
    this.color,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.bioTeal;
    final label = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isOutline ? c : AppColors.midnightBlack),
              const SizedBox(width: 8),
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
          )
        : Text(
            text,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isOutline ? c : AppColors.midnightBlack,
            ),
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
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
      ),
    );
  }
}
<<<<<<< HEAD
>>>>>>> 9a1a991c4a0ff6488c71bc926a7e96f24c21bd19
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
