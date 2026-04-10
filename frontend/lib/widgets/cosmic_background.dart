import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class Star {
  double x, y, radius, opacity, speed;
  Color color;
  Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.speed,
    required this.color,
  });
}

class CosmicBackground extends StatefulWidget {
  final Widget child;
  final bool showStardustRain;

  const CosmicBackground({
    super.key,
    required this.child,
    this.showStardustRain = false,
  });

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin {
  late AnimationController _twinkleController;
  late AnimationController _stardustController;
  late AnimationController _driftController;
  late List<Star> _stars;
  late List<_StardustParticle> _stardustParticles;
  late List<_StreakParticle> _streakParticles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateStars();
    _generateStardustParticles();
    _generateStreakParticles();

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _stardustController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Slow nebula drift — always on
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  void _generateStars() {
    _stars = List.generate(140, (i) {
      return Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        radius: _random.nextDouble() * 1.8 + 0.4,
        opacity: _random.nextDouble() * 0.7 + 0.3,
        speed: _random.nextDouble() * 0.3 + 0.1,
        color: AppColors.starColors[_random.nextInt(AppColors.starColors.length)],
      );
    });
  }

  void _generateStardustParticles() {
    _stardustParticles = List.generate(25, (i) {
      return _StardustParticle(
        x: _random.nextDouble(),
        startY: 1.0 + _random.nextDouble() * 0.2,
        radius: _random.nextDouble() * 2.5 + 0.8,
        speed: _random.nextDouble() * 0.35 + 0.15,
        phase: _random.nextDouble(),
        color: AppColors.starColors[_random.nextInt(AppColors.starColors.length)],
        isStardust: true,
      );
    });
  }

  void _generateStreakParticles() {
    // Streak fire particles — always shown subtly
    _streakParticles = List.generate(8, (i) {
      return _StreakParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        length: _random.nextDouble() * 40 + 20,
        angle: -0.3 + _random.nextDouble() * 0.2,
        speed: _random.nextDouble() * 0.2 + 0.1,
        phase: _random.nextDouble(),
        color: i.isEven
            ? AppColors.dustyRose.withOpacity(0.6)
            : AppColors.cream.withOpacity(0.5),
      );
    });
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _stardustController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep space gradient — new palette
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.5),
              radius: 1.3,
              colors: [
                Color(0xFF0D2418),
                Color(0xFF071410),
                Color(0xFF040F08),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Nebula glow — teal/olive
        AnimatedBuilder(
          animation: _driftController,
          builder: (context, _) {
            final drift = sin(_driftController.value * 2 * pi) * 20;
            return Stack(
              children: [
                Positioned(
                  top: -80 + drift,
                  right: -60,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.tealBlue.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100 - drift,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.oliveGreen.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 200 + drift * 0.5,
                  left: 60,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.forestGreen.withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        // Animated star field — always on
        AnimatedBuilder(
          animation: _twinkleController,
          builder: (context, _) {
            return CustomPaint(
              painter: _StarFieldPainter(
                stars: _stars,
                twinkleValue: _twinkleController.value,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        // Streak fire — always subtly present
        AnimatedBuilder(
          animation: _stardustController,
          builder: (context, _) {
            return CustomPaint(
              painter: _StreakPainter(
                particles: _streakParticles,
                progress: _stardustController.value,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        // Stardust particles — always on (more prominent with showStardustRain)
        AnimatedBuilder(
          animation: _stardustController,
          builder: (context, _) {
            return CustomPaint(
              painter: _StardustPainter(
                particles: _stardustParticles,
                progress: _stardustController.value,
                prominent: widget.showStardustRain,
              ),
              child: const SizedBox.expand(),
            );
          },
        ),
        // Main content
        widget.child,
      ],
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  final double twinkleValue;

  _StarFieldPainter({required this.stars, required this.twinkleValue});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final opacity =
          (star.opacity + twinkleValue * star.speed * 0.4).clamp(0.1, 1.0);
      final paint = Paint()
        ..color = star.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      if (star.radius > 1.4) {
        final glowPaint = Paint()
          ..color = star.color.withOpacity(opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.radius * 2.5,
          glowPaint,
        );
      }
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarFieldPainter old) => true;
}

class _StardustParticle {
  double x, startY, radius, speed, phase;
  Color color;
  bool isStardust;
  _StardustParticle({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
    this.isStardust = true,
  });
}

class _StardustPainter extends CustomPainter {
  final List<_StardustParticle> particles;
  final double progress;
  final bool prominent;

  _StardustPainter(
      {required this.particles,
      required this.progress,
      this.prominent = false});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phase) % 1.0;
      final y = (1.0 - t * (1.0 + p.speed)) * size.height;
      final x = p.x * size.width + sin(t * pi * 2) * 18;
      final opacity = prominent
          ? (1.0 - t) * 0.9
          : (1.0 - t) * 0.35; // subtle when not prominent

      if (y < 0) continue;

      // Stardust glow
      final glowPaint = Paint()
        ..color = p.color.withOpacity(opacity * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2.5);
      canvas.drawCircle(Offset(x, y), p.radius * 2.5, glowPaint);

      // 4-point star shape for stardust
      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      _drawStarDust(canvas, Offset(x, y), p.radius, paint);
    }
  }

  void _drawStarDust(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    // Simple diamond/star shape
    path.moveTo(center.dx, center.dy - r);
    path.lineTo(center.dx + r * 0.3, center.dy - r * 0.3);
    path.lineTo(center.dx + r, center.dy);
    path.lineTo(center.dx + r * 0.3, center.dy + r * 0.3);
    path.lineTo(center.dx, center.dy + r);
    path.lineTo(center.dx - r * 0.3, center.dy + r * 0.3);
    path.lineTo(center.dx - r, center.dy);
    path.lineTo(center.dx - r * 0.3, center.dy - r * 0.3);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StardustPainter old) => true;
}

class _StreakParticle {
  double x, y, length, angle, speed, phase;
  Color color;
  _StreakParticle({
    required this.x,
    required this.y,
    required this.length,
    required this.angle,
    required this.speed,
    required this.phase,
    required this.color,
  });
}

class _StreakPainter extends CustomPainter {
  final List<_StreakParticle> particles;
  final double progress;

  _StreakPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final opacity = (sin(t * pi)).clamp(0.0, 1.0) * 0.5;

      final startX = p.x * size.width + t * size.width * 0.3;
      final startY = p.y * size.height;
      final endX = startX + cos(p.angle) * p.length;
      final endY = startY + sin(p.angle) * p.length;

      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            p.color.withOpacity(opacity),
            p.color.withOpacity(0),
          ],
        ).createShader(Rect.fromPoints(
          Offset(startX, startY),
          Offset(endX, endY),
        ))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(_StreakPainter old) => true;
}