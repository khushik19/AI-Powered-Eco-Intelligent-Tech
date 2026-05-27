import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../widgets/cosmic_background.dart';
import 'auth/login_screen.dart';
import 'auth/register_type_screen.dart';
import '../services/auth_service.dart';
import 'home/home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isLoading = false;

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

  Future<void> _loginAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final userData = await AuthService.signInAnonymously();
      if (!mounted) return;
      if (userData != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(userData: userData)),
          (_) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Guest login failed: $e. Falling back to offline guest session.');

      final mockGuestData = {
        'uid': 'mock_guest_${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Guest Explorer',
        'email': 'guest@cleancosmos.app',
        'phone': '',
        'city': 'Cosmos',
        'state': 'Space',
        'country': 'Universe',
        'institution': '',
        'collegeId': null,
        'role': 'individual',
        'stardust': 0,
        'weeklyStreak': 0,
        'totalActions': 0,
        'lastActionDate': null,
        'createdAt': DateTime.now().toIso8601String(),
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected in Offline Guest Mode', style: TextStyle(fontFamily: 'Outfit')),
          backgroundColor: AppColors.bioTeal,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userData: mockGuestData)),
        (_) => false,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
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
                        gradient: const LinearGradient(
                          colors: [AppColors.bioTeal, AppColors.kelp],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.bioTeal.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.eco,
                              color: Colors.black,
                              size: 52),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Clean Cosmos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.softGrey, AppColors.bioTeal],
                    ).createShader(bounds),
                    child: const Text(
                      'Your AI-powered eco intelligence companion.\nJoin the movement for a cleaner planet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Outfit',
                        height: 1.6,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  // Primary CTA — Register
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterTypeScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bioTeal,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.bioTeal.withOpacity(0.5),
                      ),
                      child: const Text(
                        'Enter the Cosmos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Secondary CTA — Login
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.bioTeal,
                        side: const BorderSide(
                            color: AppColors.bioTeal, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Already a Star? Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tertiary CTA — Explore as Guest
                  SizedBox(
                    height: 56,
                    child: TextButton(
                      onPressed: _isLoading ? null : _loginAsGuest,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.bioTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bioTeal),
                            )
                          : const Text(
                              'Explore as Guest',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                                letterSpacing: 0.5,
                              ),
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
}