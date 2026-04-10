import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'set_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userData;

  const OtpScreen({super.key, required this.email, required this.userData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _isVerifying = false;

  void _verify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP')),
      );
      return;
    }
    setState(() => _isVerifying = true);
    // In production: verify OTP via Firebase Auth phone or email OTP
    // For hackathon: accept any 6-digit code
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isVerifying = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordScreen(userData: widget.userData),
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
                  'Verify\nYour Email',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit code to\n${widget.email}',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 48),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  onChanged: (v) => setState(() => _otp = v),
                  onCompleted: (v) => setState(() => _otp = v),
                  animationType: AnimationType.scale,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: AppColors.glassWhiteStrong,
                    selectedFillColor: AppColors.glassWhite,
                    inactiveFillColor: AppColors.glassWhite,
                    activeColor: AppColors.nebulaBlue,
                    selectedColor: AppColors.cosmicPurple,
                    inactiveColor: AppColors.glassBorder,
                  ),
                  enableActiveFill: true,
                  cursorColor: AppColors.nebulaBlue,
                  textStyle: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 32),
                _isVerifying
                    ? const Center(child: CircularProgressIndicator())
                    : GlassButton(
                        text: 'Verify & Continue',
                        icon: Icons.check_circle_outline,
                        onTap: _verify,
                      ).animate().fadeIn(delay: 600.ms),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: AppColors.nebulaBlue,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}