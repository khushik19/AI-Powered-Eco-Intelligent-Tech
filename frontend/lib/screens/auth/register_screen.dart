import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_fact_widget.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String registrationType;
  const RegisterScreen({super.key, required this.registrationType});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _institutionController = TextEditingController();
  File? _profileImage;
  bool _isLoading = false;

  bool get isStudentEmployee => widget.registrationType == 'student_employee';
  bool get isCollegeOrg => widget.registrationType == 'college_org';

  String get typeTitle {
    switch (widget.registrationType) {
      case 'individual': return 'Individual';
      case 'student_employee': return 'Student / Employee';
      case 'college_org': return 'College / Organisation';
      default: return '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: _emailController.text.trim(),
            userData: {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _phoneController.text.trim(),
              'city': _cityController.text.trim(),
              'state': _stateController.text.trim(),
              'country': _countryController.text.trim(),
              'institution': _institutionController.text.trim(),
              'type': widget.registrationType,
            },
          ),
        ),
      );
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Outfit',
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.textMuted, size: 18)
              : null,
        ),
        validator: validator ??
            (v) => (v == null || v.isEmpty) ? '$label is required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Join as $typeTitle',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Photo
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.cosmicPurple.withOpacity(0.5),
                                      AppColors.nebulaBlue.withOpacity(0.5),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                    width: 2,
                                  ),
                                  image: _profileImage != null
                                      ? DecorationImage(
                                          image: FileImage(_profileImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _profileImage == null
                                    ? const Center(
                                        child: Icon(
                                          Icons.add_a_photo_outlined,
                                          color: AppColors.textSecondary,
                                          size: 28,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.cosmicPurple,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Profile Photo *',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildField(
                          controller: _nameController,
                          label: isCollegeOrg ? 'Organisation Name' : 'Full Name',
                          hint: isCollegeOrg ? 'ABC University' : 'Your name',
                          icon: Icons.person_outline,
                        ),
                        _buildField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.email_outlined,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        _buildField(
                          controller: _phoneController,
                          label: 'Contact Number',
                          hint: '+91 XXXXXXXXXX',
                          keyboardType: TextInputType.phone,
                          icon: Icons.phone_outlined,
                        ),
                        if (isStudentEmployee)
                          _buildField(
                            controller: _institutionController,
                            label: 'Institution / Organisation',
                            hint: 'Where you study or work',
                            icon: Icons.business_outlined,
                          ),
                        _buildField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'Your city',
                          icon: Icons.location_city_outlined,
                        ),
                        _buildField(
                          controller: _stateController,
                          label: 'State',
                          hint: 'Your state',
                          icon: Icons.map_outlined,
                        ),
                        _buildField(
                          controller: _countryController,
                          label: 'Country',
                          hint: 'Your country',
                          icon: Icons.public_outlined,
                        ),
                        const SizedBox(height: 8),
                        const LoadingFactWidget(),
                        const SizedBox(height: 24),
                        GlassButton(
                          text: 'Continue to Verify',
                          icon: Icons.verified_outlined,
                          onTap: _continue,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _institutionController.dispose();
    super.dispose();
  }
}