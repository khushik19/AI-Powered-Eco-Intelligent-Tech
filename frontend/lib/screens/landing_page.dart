import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/liquid_glass_card.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.abyss,
      body: Stack(
        children: [
          // Background liquid "blobs" for the Kelp/Sea Foam colors
          Positioned(
            top: -100,
            left: -50,
            child: _LiquidBackgroundBlob(color: AppColors.kelp.withOpacity(0.2)),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "ECO-INTELLIGENT",
                    style: TextStyle(
                      color: AppColors.bioTeal,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      shadows: [
                        Shadow(color: AppColors.bioTeal.withOpacity(0.5), blurRadius: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Main Metallic Container
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          "AI System Status: Active",
                          style: TextStyle(
                            color: AppColors.seaFoam,
                            fontFamily: 'ArchivoBlack',
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: 0.7,
                          backgroundColor: AppColors.abyss,
                          color: AppColors.reefCoral,
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Primary Action Button with Metallic Effect
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bioTeal,
                        foregroundColor: AppColors.abyss,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.bioTeal.withOpacity(0.4),
                      ),
                      child: const Text("INITIALIZE SCAN", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidBackgroundBlob extends StatelessWidget {
  final Color color;
  const _LiquidBackgroundBlob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}