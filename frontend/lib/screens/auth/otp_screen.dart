import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'set_password_screen.dart';

class OtpScreen extends StatefulWidget {
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

  const OtpScreen({
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
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _otpSent = false;

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);

    // DEMO MODE FAST FORWARD: 1.5 second fake delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _otpSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo OTP Sent! (Type ANY 6 digits to log in)'),
        backgroundColor: AppColors.bioTeal,
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _verify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ANY 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // DEMO MODE FAST FORWARD: 1 second fake delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    
    // Verification immediately successful!
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordScreen(
          email: widget.email,
          name: widget.name,
          phone: widget.phone,
          userType: widget.userType,
          city: widget.city,
          state: widget.state,
          country: widget.country,
          institution: widget.institution,
          collegeId: widget.collegeId,
          idNumber: widget.idNumber,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
          'Verify OTP',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.phonelink_ring_outlined,
                    color: AppColors.bioTeal, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Check your phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a 6-digit OTP to\n${widget.phone}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 40),
                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (i) {
                    return SizedBox(
                      width: 46,
                      height: 56,
                      child: GlassCard(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (val.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bioTeal,
                      foregroundColor: AppColors.midnightBlack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Verify and Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                        color: AppColors.bioTeal, fontFamily: 'Outfit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}