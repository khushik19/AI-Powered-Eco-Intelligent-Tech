import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// iOS 26 / visionOS-style Liquid Glass card.
/// Layered blur + refraction noise + specular rim + inner glow
/// to achieve the "metallic liquid" look from image reference.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double blurStrength;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 26,
    this.padding,
    this.margin,
    this.tintColor,
    this.onTap,
    this.width,
    this.height,
    this.blurStrength = 28,
  });

  @override
  Widget build(BuildContext context) {
    final tint = tintColor ?? AppColors.electricCyan;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // Outer glow — the "liquid" halo
          boxShadow: [
            BoxShadow(
              color: tint.withOpacity(0.18),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.neonMoss.withOpacity(0.08),
              blurRadius: 60,
              spreadRadius: -8,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // ── Layer 1: Heavy backdrop blur (frosted glass base) ──────────
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurStrength,
                  sigmaY: blurStrength,
                ),
                child: Container(color: Colors.transparent),
              ),

              // ── Layer 2: Dark tinted fill (midnight black base) ────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.midnightBlack.withOpacity(0.72),
                      AppColors.midnightBlack.withOpacity(0.55),
                      tint.withOpacity(0.06),
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),

              // ── Layer 3: Specular top-left shine (the "glass" sheen) ───────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: borderRadius * 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.28),
                        Colors.white.withOpacity(0.06),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Layer 4: Left-edge rim light (liquid glass side glow) ──────
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                child: Container(
                  width: 1.5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.45),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Layer 5: Outer border (glass edge) ────────────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                    width: 1.2,
                  ),
                ),
              ),

              // ── Layer 6: Bottom depth shadow (inner depth illusion) ────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: borderRadius * 1.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(borderRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.22),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
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

/// Liquid Glass Button — pill-shaped with neon glow press effect
class LiquidGlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final bool isOutline;
  final double width;
  final IconData? icon;

  const LiquidGlassButton({
    super.key,
    required this.text,
    required this.onTap,
    this.color,
    this.isOutline = false,
    this.width = double.infinity,
    this.icon,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
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
    final labelColor = widget.isOutline ? color : AppColors.midnightBlack;

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
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Blur base
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(color: Colors.transparent),
                ),
                // Gradient fill
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: widget.isOutline
                        ? LinearGradient(
                            colors: [
                              AppColors.midnightBlack.withOpacity(0.6),
                              AppColors.midnightBlack.withOpacity(0.4),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              color.withOpacity(0.90),
                              color.withOpacity(0.65),
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
                // Specular top highlight
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
                // Label
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
