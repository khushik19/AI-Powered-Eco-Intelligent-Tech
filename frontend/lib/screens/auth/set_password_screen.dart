import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';

class SetPasswordScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String userType;
  final String city;
  final String state;
  final String country;
  final String institution;
  final String? collegeId;
  final String idNumber;

  const SetPasswordScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
    this.city = '',
    this.state = '',
    this.country = '',
    this.institution = '',
    this.collegeId,
    this.idNumber = '',
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _launch() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.signUp(
        email: widget.email,
        password: _passwordController.text,
        name: widget.name,
        role: widget.userType,
        phone: widget.phone,
        city: widget.city,
        state: widget.state,
        country: widget.country,
        institution: widget.institution.isNotEmpty ? widget.institution : null,
        collegeId: widget.collegeId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created! Please log in.',
            style: TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: AppColors.cosmicGreen,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      // Redirect to login after registration
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration failed: ${e.toString().split(']').last.trim()}',
            style: const TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.bioTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Set Password',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.lock_outline,
                      color: AppColors.bioTeal, size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Almost there',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a secure password for your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontFamily: 'Outfit'),
                  ),
                  const SizedBox(height: 40),
                  // Password
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'Outfit'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontFamily: 'Outfit'),
                        border: InputBorder.none,
                        icon: const Icon(Icons.lock_outline,
                            color: AppColors.bioTeal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Confirm
                  GlassCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'Outfit'),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Please confirm your password';
                        if (v != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: const TextStyle(
                            color: AppColors.textMuted, fontFamily: 'Outfit'),
                        border: InputBorder.none,
                        icon: const Icon(Icons.lock_outline,
                            color: AppColors.bioTeal),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _launch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bioTeal,
                        foregroundColor: AppColors.midnightBlack,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 8,
                        shadowColor: AppColors.bioTeal.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Launch into the Cosmos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}