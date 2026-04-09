import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class MeetTheStarsScreen extends StatelessWidget {
  const MeetTheStarsScreen({super.key});

  static const _team = [
    {
      'name': 'Khushi Katiyar',
      'role': 'Fits the Flutters',
      'emoji': '📱',
      'color': AppColors.cosmicGreen,
      'bio': 'Crafting every pixel of your cosmic journey.',
    },
    {
      'name': 'Vanshvi Jain',
      'role': "Backend's Back",
      'emoji': '⚙️',
      'color': AppColors.nebulaBlue,
      'bio': 'The engine that powers the cosmos.',
    },
    {
      'name': 'Achal Goyal',
      'role': 'Fires the Base',
      'emoji': '🔥',
      'color': AppColors.cosmicPurple,
      'bio': 'Keeping the data alive across the universe.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        showStardustRain: true,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.stardustGold, AppColors.cosmicPurple],
                      ).createShader(b),
                      child: const Text(
                        'Meet the\nStars ✨',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms),
                    const SizedBox(height: 8),
                    Text(
                      'The constellation that built Clean Cosmos.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _team.length,
                  itemBuilder: (context, i) {
                    final member = _team[i];
                    final color = member['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: GlassCard(
                        padding: const EdgeInsets.all(24),
                        borderColor: color.withOpacity(0.4),
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.08),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        child: Row(
                          children: [
                            // Avatar circle
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.4),
                                    color.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: color.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  member['emoji'] as String,
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: color.withOpacity(0.15),
                                      border: Border.all(
                                          color: color.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      member['role'] as String,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    member['bio'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 200 + i * 150))
                          .slideX(begin: 0.1, end: 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}