import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'register_screen.dart';

class RegisterTypeScreen extends StatelessWidget {
  const RegisterTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final types = [
      {
        'type': 'individual',
        'title': 'Individual',
        'subtitle': 'A solo cosmic explorer',
        'iconData': Icons.star,
        'color': AppColors.oliveGreen,
      },
      {
        'type': 'student_employee',
        'title': 'Student / Employee',
        'subtitle': 'Part of an institution or org',
        'iconData': Icons.star,          // changed from graduation cap emoji
        'color': AppColors.tealBlue,
      },
      {
        'type': 'college_org',
        'title': 'College / Organisation',
        'subtitle': 'Lead a constellation of change',
        'iconData': Icons.star,
        'color': AppColors.dustyRose,
      },
    ];

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Who are\nyou in the\ncosmos?',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  'Select your role to get started.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                ...types.asMap().entries.map((entry) {
                  final i = entry.key;
                  final t = entry.value;
                  final color = t['color'] as Color;
                  final iconData = t['iconData'] as IconData;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterScreen(
                            registrationType: t['type'] as String,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      borderColor: color.withOpacity(0.4),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.15),
                              border: Border.all(
                                color: color.withOpacity(0.4),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                iconData,
                                color: color,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['title'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t['subtitle'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: color,
                            size: 16,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(
                            delay: Duration(milliseconds: 300 + i * 120))
                        .slideX(begin: 0.1, end: 0),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}