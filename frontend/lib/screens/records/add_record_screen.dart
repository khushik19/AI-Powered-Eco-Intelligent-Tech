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

  // Multiple media files
  final List<XFile> _mediaFiles = [];
  final List<bool> _isVideoFlags = [];

  String? _selectedActivity;
  String? _selectedCategory;
  bool _isLoading = false;

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
    if (video) {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _mediaFiles.add(picked);
          _isVideoFlags.add(true);
        });
      }
    } else {
      // Allow multiple images
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        setState(() {
          _mediaFiles.addAll(picked);
          _isVideoFlags.addAll(List.filled(picked.length, false));
        });
      }
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
      _isVideoFlags.removeAt(index);
    });
  }

  void _submit() async {
    if (_mediaFiles.isEmpty) {
      _showSnack('Please upload at least one photo or video', AppColors.error);
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
      // Use first media file for AI analysis
      final bytes = await _mediaFiles.first.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      final description = widget.isCustom
          ? '${_titleController.text.trim()}: ${_descController.text.trim()}'
          : '${_selectedActivity ?? ''}: ${_descController.text.trim()}';

      // Submit with verifying status
      final result = await ApiService.instance.submitAction(
        userId: widget.userData['uid'] as String? ??
            widget.userData['id'] as String? ??
            '',
        collegeId: widget.userData['collegeId'] as String? ?? '',
        role: widget.userData['role'] as String? ?? 'student',
        imageBytes: bytes,
        imageBase64: imageBase64,
        description: description,
        isPredefined: !widget.isCustom,
      );

      final stardust = result['stardustAwarded'] ?? 50;

      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack(
          'Record submitted! Verifying your action... +$stardust stardust pending',
          AppColors.oliveGreen,
        );
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack(
          'Submission failed: ${e.toString().replaceAll('Exception: ', '')}',
          AppColors.error,
        );
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
                              fontFamily: 'Outfit',
                              color: AppColors.textPrimary),
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
                          final isSelected =
                              _selectedActivity == activity;
                          final color =
                              Color(category['color'] as int);
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selectedActivity = activity),
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

                      // PROOF — Multiple photos/videos
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

                      // Media grid
                      if (_mediaFiles.isNotEmpty) ...[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ..._mediaFiles.asMap().entries.map((entry) {
                              final i = entry.key;
                              final file = entry.value;
                              final isVideo = _isVideoFlags[i];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: isVideo
                                        ? Container(
                                            width: 90,
                                            height: 90,
                                            color: AppColors.glassWhite,
                                            child: const Center(
                                              child: Icon(
                                                  Icons.play_circle,
                                                  color: AppColors
                                                      .textPrimary,
                                                  size: 36),
                                            ),
                                          )
                                        : kIsWeb
                                            ? Image.network(
                                                file.path,
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(file.path),
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                              ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeMedia(i),
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.error,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add more media buttons
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              onTap: () => _pickMedia(),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 18),
                              child: Column(
                                children: [
                                  const Icon(Icons.add_photo_alternate_outlined,
                                      color: AppColors.oliveGreen, size: 26),
                                  const SizedBox(height: 4),
                                  Text(
                                    _mediaFiles.isEmpty
                                        ? 'Add Photo'
                                        : 'Add More',
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
                                  vertical: 18),
                              child: Column(
                                children: [
                                  const Icon(Icons.videocam_outlined,
                                      color: AppColors.tealBlue, size: 26),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add Video',
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
                            fontFamily: 'Outfit',
                            color: AppColors.textPrimary),
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
                          borderColor:
                              AppColors.cream.withOpacity(0.3),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.cream, size: 18),
                              const SizedBox(width: 10),
                              Text(
                                'Custom activities earn extra stardust!',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: AppColors.cream,
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
                              text: 'Submit for Verification',
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