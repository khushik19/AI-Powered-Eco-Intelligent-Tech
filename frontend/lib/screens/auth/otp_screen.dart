import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'set_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String userType;

  const OtpScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    required this.userType,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

<<<<<<< HEAD
<<<<<<< HEAD
  String get _otp =>
      _controllers.map((c) => c.text).join();
=======
  String get _otp => _controllers.map((c) => c.text).join();
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
  String get _otp => _controllers.map((c) => c.text).join();
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd

  Future<void> _verify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete OTP')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      // TODO: Replace with actual OTP verification
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SetPasswordScreen(
            email: widget.email,
            name: widget.name,
            phone: widget.phone,
            userType: widget.userType,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
<<<<<<< HEAD
      backgroundColor: AppColors.abyss,
=======
      backgroundColor: Colors.transparent,
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
      backgroundColor: Colors.transparent,
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.bioTeal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Verify OTP',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
<<<<<<< HEAD
<<<<<<< HEAD
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
=======
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.mark_email_read_outlined,
                  color: AppColors.bioTeal, size: 64),
              const SizedBox(height: 24),
              Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit OTP to\n${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          fillColor: AppColors.glassWhiteStrong,
                          filled: false,
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
              ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bioTeal,
                  foregroundColor: AppColors.midnightBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                        'Verify & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Resend OTP',
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
}
