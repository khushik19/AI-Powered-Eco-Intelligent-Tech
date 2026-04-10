import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/glass_card.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String userType;

  const RegisterScreen({super.key, required this.userType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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
          'Create Account',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
<<<<<<< HEAD
<<<<<<< HEAD
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
=======
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Join as ${widget.userType}',
                  style: TextStyle(
                    color: AppColors.bioTeal,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in your details to get started',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                const SizedBox(height: 32),
                // Name
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
                  child: TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: AppColors.textPrimary),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name is required' : null,
                    decoration: InputDecoration(
                      hintText: 'Full Name',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
<<<<<<< HEAD
<<<<<<< HEAD
                      icon: Icon(Icons.person_outline, color: AppColors.bioTeal),
=======
                      icon:
                          Icon(Icons.person_outline, color: AppColors.bioTeal),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
                      icon:
                          Icon(Icons.person_outline, color: AppColors.bioTeal),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Email
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
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: AppColors.textPrimary),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Email Address',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
<<<<<<< HEAD
<<<<<<< HEAD
                      icon: Icon(Icons.email_outlined, color: AppColors.bioTeal),
=======
                      icon:
                          Icon(Icons.email_outlined, color: AppColors.bioTeal),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
                      icon:
                          Icon(Icons.email_outlined, color: AppColors.bioTeal),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Phone
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
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: AppColors.textPrimary),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Phone is required' : null,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
<<<<<<< HEAD
<<<<<<< HEAD
                      icon: Icon(Icons.phone_outlined, color: AppColors.bioTeal),
=======
                      icon:
                          Icon(Icons.phone_outlined, color: AppColors.bioTeal),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
                      icon:
                          Icon(Icons.phone_outlined, color: AppColors.bioTeal),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _continue,
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
                          'Continue to Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
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
