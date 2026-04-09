import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/constants.dart';

class LoadingFactWidget extends StatefulWidget {
  const LoadingFactWidget({super.key});

  @override
  State<LoadingFactWidget> createState() => _LoadingFactWidgetState();
}

class _LoadingFactWidgetState extends State<LoadingFactWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late String _fact;

  @override
  void initState() {
    super.initState();
    _fact = AppConstants.sustainabilityFacts[
        Random().nextInt(AppConstants.sustainabilityFacts.length)];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.cosmicGreen,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DID YOU KNOW',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.cosmicGreen,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _fact,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}