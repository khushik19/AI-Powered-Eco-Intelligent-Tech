import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String userType;
  const RegisterScreen({super.key, required this.userType});

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
  final _idController = TextEditingController();

  XFile? _profilePhoto;
  bool _isLoading = false;

  bool get _needsInstitution =>
      widget.userType == 'student_employee' || widget.userType == 'college_org';

  String get _typeLabel {
    switch (widget.userType) {
      case 'individual':
        return 'Individual';
      case 'student_employee':
        return 'Student / Employee';
      case 'college_org':
        return 'College / Organisation';
      default:
        return widget.userType;
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profilePhoto = picked);
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            userType: widget.userType,
            city: _cityController.text.trim(),
            state: _stateController.text.trim(),
            country: _countryController.text.trim(),
            institution: _institutionController.text.trim(),
            idNumber: _idController.text.trim(),
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
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _institutionController.dispose();
    _idController.dispose();
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
        title: Text(
          'Join as $_typeLabel',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
                  // Profile Photo
                  Center(
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.bioTeal, width: 2),
                              color: AppColors.glassWhite,
                            ),
                            child: ClipOval(
                              child: _profilePhoto == null
                                  ? const Icon(Icons.person_outline,
                                      color: AppColors.textMuted, size: 40)
                                  : kIsWeb
                                      ? Image.network(_profilePhoto!.path,
                                          fit: BoxFit.cover)
                                      : Image.file(File(_profilePhoto!.path),
                                          fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.bioTeal,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: AppColors.midnightBlack, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Profile Photo',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'Outfit'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionLabel('PERSONAL DETAILS'),
                  const SizedBox(height: 12),

                  // Name
                  _buildField(
                    controller: _nameController,
                    hint: widget.userType == 'college_org'
                        ? 'College / Organisation Name'
                        : 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  _buildField(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  _buildField(
                    controller: _phoneController,
                    hint: 'Contact Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Contact number is required' : null,
                  ),
                  const SizedBox(height: 24),

                  _sectionLabel('LOCATION'),
                  const SizedBox(height: 12),

                  // City
                  _buildField(
                    controller: _cityController,
                    hint: 'City',
                    icon: Icons.location_city_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'City is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // State
                  _buildField(
                    controller: _stateController,
                    hint: 'State / Province',
                    icon: Icons.map_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'State is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Country
                  _buildField(
                    controller: _countryController,
                    hint: 'Country',
                    icon: Icons.public_outlined,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Country is required' : null,
                  ),

                  // Institution fields — student/employee + college/org
                  if (_needsInstitution) ...[
                    const SizedBox(height: 24),
                    _sectionLabel(widget.userType == 'college_org'
                        ? 'ORGANISATION DETAILS'
                        : 'INSTITUTION DETAILS'),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _institutionController,
                      hint: widget.userType == 'college_org'
                          ? 'Official Organisation Name'
                          : 'Institution / Organisation Name',
                      icon: Icons.business_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Institution name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _idController,
                      hint: widget.userType == 'college_org'
                          ? 'Registration / Accreditation ID'
                          : 'Student / Employee ID',
                      icon: Icons.badge_outlined,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'ID number is required' : null,
                    ),
                  ],

                  const SizedBox(height: 36),

                  // Continue button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _continue,
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
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue to Verify',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
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

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 2,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(
            color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 14),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textMuted, fontFamily: 'Outfit'),
          border: InputBorder.none,
          icon: Icon(icon, color: AppColors.bioTeal, size: 20),
        ),
      ),
    );
  }
}