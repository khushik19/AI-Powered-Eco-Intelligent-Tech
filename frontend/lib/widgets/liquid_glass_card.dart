import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
//
//  APPLE LIQUID GLASS (GEL-LIKE TRANSLUCENT OPTICS)
//
//  Key Properties of Apple's Liquid Glass:
//  1. TRANSLUCENCE & CLARITY (Illumination): Background elements are seen
//     clearly through the surface (rather than scattered into a milky blur),
//     creating a rich gel-like feel that reveals what is underneath.
//  2. HIGHLIGHT & LIGHT CASTING: Continuous perimeter specular edge that
//     catches environmental light along the curved bevel.
//  3. SHADOW & DEPTH SEPARATION: Multi-tier floating occlusion that lifts
//     the glass cleanly above the background canvas.
//  4. SUBTLE CHROMATIC TINTING: Translucent tint adapts to theme and brand tones.
//  5. RESTRAINT: Primary showcase on the navigation layer and key hero controls.
//
// ─────────────────────────────────────────────────────────────────────────────

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? tintColor;
  final Color? borderColor;
  final Color? fillColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double blurStrength;
  final bool animated;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.tintColor,
    this.borderColor,
    this.fillColor,
    this.gradient,
    this.onTap,
    this.width,
    this.height,
    this.blurStrength = 14.0, // Gel-like clarity (not milky opaque)
    this.animated = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sheenController;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.animated) _sheenController.repeat();
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = widget.tintColor ??
        widget.borderColor ??
        widget.fillColor ??
        AppColors.tulip;
    final r = widget.borderRadius;

    Widget glass = Container(
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        // ── SHADOW LAYER: Multi-tier physical separation ──
        boxShadow: [
          // 1. Tight contact occlusion
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 5),
          ),
          // 2. Soft ambient depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 40,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
          // 3. Ambient environmental colored glow
          BoxShadow(
            color: tint.withValues(alpha: 0.08),
            blurRadius: 48,
            spreadRadius: -8,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            // ── ILLUMINATION LAYER 1: Translucent Backdrop Smoothing ──
            // Uses crisp 14σ blur so stars & backgrounds are visibly transmitted
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blurStrength,
                  sigmaY: widget.blurStrength,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            // ── ILLUMINATION LAYER 2: Ultra-Translucent Gel Body ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08), // crisp top-left specular
                          Colors.white.withValues(alpha: 0.02), // transparent mid
                          tint.withValues(alpha: 0.03),         // environmental tint
                          Colors.black.withValues(alpha: 0.16), // bottom depth curve
                        ],
                        stops: const [0.0, 0.35, 0.70, 1.0],
                      ),
                ),
              ),
            ),

            // ── HIGHLIGHT LAYER 1: Animated Refraction Sheen ──
            if (widget.animated)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _sheenController,
                  builder: (_, __) => CustomPaint(
                    painter: _GelRefractionSheenPainter(
                      progress: _sheenController.value,
                      tint: tint,
                    ),
                  ),
                ),
              ),

            // ── HIGHLIGHT LAYER 2: Top Edge Internal Glint ──
            Positioned(
              top: 0,
              left: r * 0.4,
              right: r * 0.4,
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.65),
                      Colors.white.withValues(alpha: 0.65),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.25, 0.75, 1.0],
                  ),
                ),
              ),
            ),

            // ── HIGHLIGHT LAYER 3: Curved Perimeter Bevel Border ──
            Positioned.fill(
              child: CustomPaint(
                painter: _GelPerimeterBorderPainter(
                  radius: r,
                  borderColor: widget.borderColor,
                ),
              ),
            ),

            // ── CONTENT ──
            Padding(
              padding: widget.padding ?? const EdgeInsets.all(20),
              child: widget.child,
            ),
          ],
        ),
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: glass,
      );
    }
    return glass;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gel Perimeter Border Painter
// Crisp light-catching edge: bright white highlight at top & top-left curvature,
// smoothly fading along the perimeter for a true liquid glass rim.
// ─────────────────────────────────────────────────────────────────────────────

class _GelPerimeterBorderPainter extends CustomPainter {
  final double radius;
  final Color? borderColor;

  _GelPerimeterBorderPainter({required this.radius, this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = SweepGradient(
        center: const Alignment(-0.6, -0.8),
        startAngle: 0,
        endAngle: pi * 2,
        colors: [
          Colors.white.withValues(alpha: 0.60),  // top-left direct highlight
          Colors.white.withValues(alpha: 0.22),  // right edge light
          Colors.white.withValues(alpha: 0.05),  // bottom shadow edge
          Colors.white.withValues(alpha: 0.18),  // left return
          Colors.white.withValues(alpha: 0.60),  // wrap
        ],
        stops: const [0.0, 0.30, 0.60, 0.85, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(_GelPerimeterBorderPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Gel Refraction Sheen Painter
// Subtle, continuous light transmission moving through the gel medium.
// ─────────────────────────────────────────────────────────────────────────────

class _GelRefractionSheenPainter extends CustomPainter {
  final double progress;
  final Color tint;

  _GelRefractionSheenPainter({required this.progress, required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final t = progress * 2 * pi;
    final waveY = size.height * 0.25 + sin(t) * (size.height * 0.06);

    final path = Path();
    path.moveTo(0, waveY);
    path.quadraticBezierTo(
      size.width * 0.5,
      waveY + cos(t) * 12,
      size.width,
      waveY - sin(t) * 8,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.035),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GelRefractionSheenPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// LiquidGlassButton
// Floating gel action pill with pressed spring kinetics
// ─────────────────────────────────────────────────────────────────────────────

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
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glow = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.tulip;
    final isOutline = widget.isOutline;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: widget.width,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: isOutline
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(
                          alpha: 0.35 + _glow.value * 0.25,
                        ),
                        blurRadius: 24 + _glow.value * 12,
                        spreadRadius: -4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.40),
                        blurRadius: 12,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Translucent backdrop smoothing
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Gel Fill
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: isOutline
                            ? LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.02),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: 0.90),
                                  color.withValues(alpha: 0.70),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                  // Perimeter border highlight
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GelPerimeterBorderPainter(
                        radius: 18,
                        borderColor: isOutline
                            ? color.withValues(alpha: 0.8)
                            : null,
                      ),
                    ),
                  ),
                  // Top rim glint
                  Positioned(
                    top: 0,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 1.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.50),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Label & icon
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: isOutline ? color : Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isOutline ? color : Colors.white,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LiquidGlassNavBar
// Flagship Liquid Glass showcase — floating translucent navigation pill
// with visible background transmission, gel depth, and active illumination.
// ─────────────────────────────────────────────────────────────────────────────

class LiquidGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnim;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _indicatorAnim = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _indicatorController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          // Multi-layer buoyancy shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.60),
              blurRadius: 36,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AppColors.tulip.withValues(alpha: 0.12),
              blurRadius: 48,
              spreadRadius: -8,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.ocean.withValues(alpha: 0.08),
              blurRadius: 32,
              spreadRadius: -6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Stack(
            children: [
              // ── TRANSLUCENCE: 14σ smoothing lets background stars shine through ──
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: const SizedBox.expand(),
                ),
              ),

              // ── GEL BODY: Clear translucent fluid fill ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.10), // bright top-left
                        Colors.white.withValues(alpha: 0.03), // transparent body
                        Colors.black.withValues(alpha: 0.20), // bottom curvature
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // ── HIGHLIGHT: Top rim specular ──
              Positioned(
                top: 0,
                left: 24,
                right: 24,
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.70),
                        Colors.white.withValues(alpha: 0.70),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // ── PERIMETER RIM: Light-catching edge bevel ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _GelPerimeterBorderPainter(radius: 36),
                ),
              ),

              // ── NAV ITEMS ──
              Row(
                children: List.generate(widget.items.length, (i) {
                  final item = widget.items[i];
                  final isSelected = i == widget.currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: _indicatorAnim,
                        builder: (_, __) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Active illuminated pill
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.tulip.withValues(alpha: 0.24)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.tulip.withValues(alpha: 0.45),
                                          width: 0.9,
                                        )
                                      : null,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.tulip.withValues(alpha: 0.28),
                                            blurRadius: 14,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected
                                      ? AppColors.tulip
                                      : Colors.white.withValues(alpha: 0.45),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.tulip
                                      : Colors.white.withValues(alpha: 0.40),
                                ),
                                child: Text(item.label),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LiquidGlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const LiquidGlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LiquidGlassChip
// Translucent pill tag with gel optics and subtle state tint
// ─────────────────────────────────────────────────────────────────────────────

class LiquidGlassChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const LiquidGlassChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.tulip;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.28),
                    blurRadius: 14,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          c.withValues(alpha: 0.32),
                          c.withValues(alpha: 0.16),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                border: Border.all(
                  color: selected
                      ? c.withValues(alpha: 0.60)
                      : Colors.white.withValues(alpha: 0.18),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 13,
                      color: selected
                          ? c
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: selected
                          ? c
                          : Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}