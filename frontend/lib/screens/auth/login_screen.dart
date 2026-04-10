import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
<<<<<<< HEAD
<<<<<<< HEAD
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with your actual auth logic
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
=======
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userData = await AuthService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
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
      final msg = e.toString();
      if (msg.contains('user-not-found') || msg.contains('wrong-password')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found. Please sign up.')),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const RegisterTypeScreen()));
          }
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $msg')));
      }
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
      backgroundColor: AppColors.abyss,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
=======
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo / Title
              Icon(Icons.eco, color: AppColors.bioTeal, size: 64),
              const SizedBox(height: 16),
              Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
              ),
              Text(
                'Login to your cosmos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              // Email field
              GlassCard(
<<<<<<< HEAD
<<<<<<< HEAD
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
=======
                const SizedBox(height: 40),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Colors.white, AppColors.nebulaBlue],
                  ).createShader(b),
                  child: const Text(
                    'Welcome\nBack, Star ✨',
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
                  'Log back into your cosmos.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                TextFormField(
>>>>>>> 9a1a991c4a0ff6488c71bc926a7e96f24c21bd19
=======
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    icon: Icon(Icons.email_outlined, color: AppColors.bioTeal),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Password field
              GlassCard(
<<<<<<< HEAD
<<<<<<< HEAD
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
=======
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(color: AppColors.textMuted),
                    border: InputBorder.none,
                    icon: Icon(Icons.lock_outline, color: AppColors.bioTeal),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Login button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cosmicGreen,
                  foregroundColor: AppColors.midnightBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Register link
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(color: AppColors.bioTeal),
                ),
              ),
            ],
<<<<<<< HEAD
<<<<<<< HEAD
=======
          ),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
          ),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
<<<<<<< HEAD
}
=======
}
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
}
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
