import 'dart:math';
import 'package:flutter/material.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _lastTime = 0.0;
  final List<_Star> _stars = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();

    // Generate 500 random stars (exact replica from portfolio)
    for (int i = 0; i < 500; i++) {
      _stars.add(_Star(
        x: _rnd.nextDouble() * 2.0 - 1.0,
        y: _rnd.nextDouble() * 2.0 - 1.0,
        z: _rnd.nextDouble(),
        baseSize: _rnd.nextDouble() * 0.4 + 0.2,
        speed: _rnd.nextDouble() * 0.03 + 0.01,
        baseOpacity: _rnd.nextDouble() * 0.4 + 0.6,
        color: _getRandomColor(),
      ));
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        final now = DateTime.now().microsecondsSinceEpoch / 1000000.0;
        if (_lastTime > 0.0) {
          final dt = now - _lastTime;
          _updateStars(dt.clamp(0.0, 0.1));
        }
        _lastTime = now;
      });
    _controller.repeat();
  }

  Color _getRandomColor() {
    final colorRand = _rnd.nextDouble();
    if (colorRand < 0.85) {
      return Colors.white;
    } else if (colorRand < 0.93) {
      return const Color(0xFFFFF2D4);
    } else {
      return const Color(0xFFFDE8E8);
    }
  }

  void _updateStars(double dt) {
    for (var star in _stars) {
      star.z -= star.speed * dt;
      if (star.z <= 0.0) {
        star.z = 1.0;
        star.x = _rnd.nextDouble() * 2.0 - 1.0;
        star.y = _rnd.nextDouble() * 2.0 - 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _CosmicPainter(stars: _stars, repaint: _controller),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Star {
  double x;
  double y;
  double z;
  final double baseSize;
  final double speed;
  final double baseOpacity;
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.z,
    required this.baseSize,
    required this.speed,
    required this.baseOpacity,
    required this.color,
  });
}

class _CosmicPainter extends CustomPainter {
  final List<_Star> stars;

  _CosmicPainter({required this.stars, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint();

    // 1. Solid deep obsidian black background
    canvas.drawColor(Colors.black, BlendMode.srcOver);

    // 2. Very subtle central nebula glow (pure & clean)
    final nebulaPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120)
      ..color = const Color(0xFFBC475F).withValues(alpha: 0.02);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.35,
      nebulaPaint,
    );

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // 3. Draw fanning starfield
    for (var star in stars) {
      // 3D to 2D projection fanning outward
      final starX = centerX + (star.x * centerX) / star.z;
      final starY = centerY + (star.y * centerY) / star.z;

      // Skip if completely out of bounds (plus a small buffer)
      if (starX < -10 ||
          starX > size.width + 10 ||
          starY < -10 ||
          starY > size.height + 10) {
        continue;
      }

      // Apparent size stays very small and sharp
      final finalSize = (star.baseSize / star.z).clamp(0.2, 2.2);

      // Smooth opacity curve: sin(z * pi) is 0 at z=1.0 (birth) and 0 at z=0.0 (death),
      // ensuring stars fade in from the background and fade out smoothly before disappearing
      double opacity = star.baseOpacity * sin(star.z * pi);
      opacity = opacity.clamp(0.0, 1.0);

      paint.color = star.color.withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(starX, starY),
        finalSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicPainter oldDelegate) => false;
}