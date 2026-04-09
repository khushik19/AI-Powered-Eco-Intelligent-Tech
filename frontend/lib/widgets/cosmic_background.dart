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
  late List<Star> _stars;
  late List<_StardustParticle> _stardustParticles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateStars();
    _generateStardustParticles();

    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _stardustController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  void _generateStars() {
    _stars = List.generate(120, (i) {
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
    _stardustParticles = List.generate(20, (i) {
      return _StardustParticle(
        x: _random.nextDouble(),
        startY: 1.0 + _random.nextDouble() * 0.2,
        radius: _random.nextDouble() * 3 + 1,
        speed: _random.nextDouble() * 0.4 + 0.2,
        phase: _random.nextDouble(),
        color: AppColors.starColors[_random.nextInt(AppColors.starColors.length)],
      );
    });
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    _stardustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep space gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.3, -0.5),
              radius: 1.2,
              colors: [
                Color(0xFF0D0D2B),
                Color(0xFF070718),
                Color(0xFF04040F),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Nebula glow patches
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.cosmicPurple.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.nebulaBlue.withOpacity(0.10),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Animated stars
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
        // Stardust rising particles (shown when collecting stardust)
        if (widget.showStardustRain)
          AnimatedBuilder(
            animation: _stardustController,
            builder: (context, _) {
              return CustomPaint(
                painter: _StardustPainter(
                  particles: _stardustParticles,
                  progress: _stardustController.value,
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
      final opacity = (star.opacity + twinkleValue * star.speed * 0.4)
          .clamp(0.1, 1.0);
      final paint = Paint()
        ..color = star.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      // Glow effect for brighter stars
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
  _StardustParticle({
    required this.x,
    required this.startY,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.color,
  });
}

class _StardustPainter extends CustomPainter {
  final List<_StardustParticle> particles;
  final double progress;

  _StardustPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress + p.phase) % 1.0;
      final y = (1.0 - t * (1.0 + p.speed)) * size.height;
      final x = p.x * size.width + sin(t * pi * 2) * 20;
      final opacity = (1.0 - t) * 0.8;

      if (y < 0) continue;

      final glowPaint = Paint()
        ..color = p.color.withOpacity(opacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2);
      canvas.drawCircle(Offset(x, y), p.radius * 2, glowPaint);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StardustPainter old) => true;
}