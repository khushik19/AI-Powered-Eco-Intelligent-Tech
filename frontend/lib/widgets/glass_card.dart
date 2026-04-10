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

  const GlassCard({
    super.key,
    required this.child,
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
  });

  @override
  Widget build(BuildContext context) {
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

  const GlassButton({
    super.key,
    required this.text,
    required this.onTap,
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
      ),
    );
  }
}
