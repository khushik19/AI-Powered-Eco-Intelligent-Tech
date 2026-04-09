import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_colors.dart';
import '../widgets/cosmic_background.dart';
import '../widgets/glass_card.dart';
import 'auth/login_screen.dart';
import 'auth/register_type_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                // Logo + app name row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.cosmicPurple, AppColors.nebulaBlue],
                        ),
                      ),
                      child: const Center(
                        child: Text('🌌', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'CLEAN COSMOS',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 48),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, AppColors.nebulaBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'Every action\ncounts in the\ncosmos.',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 700.ms)
                    .slideX(begin: -0.1, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Track your sustainability journey,\nearn stardust, and help heal the planet.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const Spacer(),
                // Action buttons
                GlassButton(
                  text: 'Enter the Cosmos',
                  icon: Icons.rocket_launch_outlined,
                  color: AppColors.cosmicPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterTypeScreen(),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 16),
                GlassButton(
                  text: 'Already a Star? Login',
                  isOutline: true,
                  color: AppColors.nebulaBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}