import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'login_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const SetPasswordScreen({super.key, required this.userData});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true, _obscure2 = true, _isLoading = false;

  void _createAccount() async {
    if (_passController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (_passController.text != _confirmController.text) {
      _showError('Passwords do not match');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        email: widget.userData['email'],
        password: _passController.text,
        name: widget.userData['name'],
        role: widget.userData['type'],
        phone: widget.userData['phone'],
        city: widget.userData['city'],
        state: widget.userData['state'],
        country: widget.userData['country'],
        institution: widget.userData['institution'],
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen(showSuccess: true)),
          (_) => false,
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Outfit')),
        backgroundColor: AppColors.error,
      ),
    );
  }

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
                const SizedBox(height: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Set Your\nPassword',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _passController,
                  obscureText: _obscure1,
                  style: const TextStyle(
                      fontFamily: 'Outfit', color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textMuted, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure1 ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscure2,
                  style: const TextStyle(
                      fontFamily: 'Outfit', color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textMuted, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure2 ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GlassButton(
                        text: 'Launch into the Cosmos 🚀',
                        onTap: _createAccount,
                      ).animate().fadeIn(delay: 500.ms),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }
}