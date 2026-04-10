import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../widgets/glass_card.dart';
import 'auth/login_screen.dart';
import 'auth/register_type_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: AppColors.abyss,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
=======
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                // App icon / hero
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonMoss,
                          AppColors.electricCyan,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonMoss.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco, color: Colors.black, size: 52),
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'CleanCosmos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle with gradient shimmer effect
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [AppColors.softGrey, AppColors.neonMoss],
                  ).createShader(bounds),
                  child: Text(
                    'Your AI-powered eco intelligence companion.\nJoin the movement for a cleaner planet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Features teaser
                GlassCard(
                  child: Column(
                    children: [
<<<<<<< HEAD
<<<<<<< HEAD
                      _buildFeatureRow(
                          Icons.qr_code_scanner, 'AI Waste Scanner', AppColors.bioTeal),
                      const Divider(color: Colors.white10),
                      _buildFeatureRow(
                          Icons.bar_chart, 'Eco Report & Score', AppColors.neonMoss),
                      const Divider(color: Colors.white10),
                      _buildFeatureRow(
                          Icons.public, 'Community Challenges', AppColors.seaFoam),
=======
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                      _buildFeatureRow(Icons.qr_code_scanner,
                          'AI Waste Scanner', AppColors.bioTeal),
                      const Divider(color: Colors.white10),
                      _buildFeatureRow(Icons.bar_chart, 'Eco Report & Score',
                          AppColors.neonMoss),
                      const Divider(color: Colors.white10),
                      _buildFeatureRow(Icons.public, 'Community Challenges',
                          AppColors.seaFoam),
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                // Primary CTA
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterTypeScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonMoss,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.neonMoss.withOpacity(0.5),
                  ),
                  child: const Text(
                    'Enter the Cosmos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary CTA
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.neonMoss,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: AppColors.neonMoss, width: 1.5),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Already a Star? Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
    );
  }
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
}
=======
}
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
