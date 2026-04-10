import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_fact_widget.dart';

class AddRecordScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? initialCategory;
  final bool isCustom;

  const AddRecordScreen({
    super.key,
    required this.userData,
    this.initialCategory,
    this.isCustom = false,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _descController = TextEditingController();
  final _titleController = TextEditingController();
  XFile? _mediaFile;
  String? _selectedActivity;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  Map<String, dynamic>? get _currentCategory {
    if (_selectedCategory == null) return null;
    return AppConstants.categories.firstWhere(
      (c) => c['id'] == _selectedCategory,
      orElse: () => AppConstants.categories.first,
    );
  }

  Future<void> _pickMedia({bool video = false}) async {
    final picker = ImagePicker();
    final picked = video
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _mediaFile = picked;
        _isVideo = video;
      });
    }
  }

  void _submit() async {
    if (_mediaFile == null) {
      _showSnack('Please upload an image or video of your activity', AppColors.error);
      return;
    }
    if (_descController.text.trim().isEmpty) {
      _showSnack('Please describe your activity', AppColors.error);
      return;
    }
    if (!widget.isCustom && _selectedActivity == null) {
      _showSnack('Please select an activity', AppColors.error);
      return;
    }
    setState(() => _isLoading = true);

    try {
      // Read image bytes once — used for both Storage upload and AI analysis
      final bytes = await _mediaFile!.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final description = widget.isCustom
          ? '${_titleController.text.trim()}: ${_descController.text.trim()}'
          : '${_selectedActivity ?? ''}: ${_descController.text.trim()}';

      final result = await ApiService.instance.submitAction(
        userId: widget.userData['uid'] as String? ?? widget.userData['id'] as String? ?? '',
        collegeId: widget.userData['collegeId'] as String? ?? '',
        role: widget.userData['role'] as String? ?? 'student',
        imageBytes: bytes,        // for Firebase Storage upload (client-side)
        imageBase64: imageBase64, // for AI vision model (backend)
        description: description,
        isPredefined: !widget.isCustom,
      );

      final stardust = result['stardustAwarded'] ?? 50;
      final summary = result['impactSummary'] ?? 'Great eco action!';

      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack('🌟 Activity recorded! +$stardust Stardust earned! $summary', AppColors.cosmicGreen);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack('⚠️ Submission failed: ${e.toString().replaceAll('Exception: ', '')}', AppColors.error);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Outfit')),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = _currentCategory;

    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      widget.isCustom ? 'Custom Activity' : 'Add Record',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      if (widget.isCustom) ...[
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(
                              fontFamily: 'Outfit', color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Activity Title',
                            hintText: 'What did you do?',
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 16),
                      ],
                      if (!widget.isCustom && category != null) ...[
                        Text(
                          'SELECT ACTIVITY',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 2,
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 12),
                        ...(category['activities'] as List<String>)
                            .map((activity) {
                          final isSelected = _selectedActivity == activity;
                          final color = Color(category['color'] as int);
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedActivity = activity),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? color.withOpacity(0.2)
                                    : AppColors.glassWhite,
                                border: Border.all(
                                  color: isSelected
                                      ? color
                                      : AppColors.glassBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? color
                                        : AppColors.textMuted,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      activity,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14,
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],
                      // Media upload
                      Text(
                        'PROOF (REQUIRED)',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 12),
                      _mediaFile != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _isVideo
                                      ? Container(
                                          height: 200,
                                          color: AppColors.glassWhite,
                                          child: const Center(
                                            child: Icon(Icons.play_circle,
                                                color: AppColors.textPrimary,
                                                size: 48),
                                          ),
                                        )
                                      : kIsWeb
                                          ? Image.network(
                                              _mediaFile!.path,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Image.file(
                                              File(_mediaFile!.path),
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _mediaFile = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.error,
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: GlassCard(
                                    onTap: () => _pickMedia(),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.image_outlined,
                                            color: AppColors.nebulaBlue,
                                            size: 28),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Photo',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassCard(
                                    onTap: () => _pickMedia(video: true),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.videocam_outlined,
                                            color: AppColors.cosmicPurple,
                                            size: 28),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Video',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(
                            fontFamily: 'Outfit', color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Describe your activity *',
                          hintText: 'Tell the cosmos what you did...',
                          alignLabelWithHint: true,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 16),
                      if (widget.isCustom)
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: AppColors.stardustGold.withOpacity(0.3),
                          child: Row(
                            children: [
                              const Text('⭐',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 10),
                              Text(
                                'Custom activities earn extra stardust!',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: AppColors.stardustGold,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 16),
                      const LoadingFactWidget(),
                      const SizedBox(height: 24),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GlassButton(
                              text: 'Submit & Earn Stardust ✨',
                              onTap: _submit,
                            ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),
                    ],
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
    _descController.dispose();
    _titleController.dispose();
    super.dispose();
  }
}