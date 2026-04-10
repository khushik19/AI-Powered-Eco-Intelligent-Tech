import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'add_record_screen.dart';
import 'all_records_screen.dart';

class RecordsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const RecordsScreen({super.key, required this.userData});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> _recent = [];
  bool _isLoading = true;

  // Maps actionType → emoji
  static const _actionEmoji = {
    'solar': '☀️',
    'composting': '🌿',
    'recycling': '♻️',
    'eWaste': '🔌',
    'water': '💧',
    'energy': '💡',
    'transport': '🚲',
    'cutsWaste': '🗑️',
    'optimizesResources': '⚡',
    'lowersEmissions': '🌱',
    'other': '🌍',
  };

  @override
  void initState() {
    super.initState();
    _loadRecentActivity();
  }

  Future<void> _loadRecentActivity() async {
    final uid = widget.userData['uid'] as String? ?? '';
    if (uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final dash = await ApiService.instance.getStudentDashboard(uid);
      final submissions = (dash['submissions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      // Show only the 3 most recent
      setState(() {
        _recent = submissions.take(3).toList();
        _isLoading = false;
      });
    } catch (_) {
      // Silent fail — just hide the recent section if offline
      setState(() => _isLoading = false);
    }
  }

  Color _colorForAction(String type) {
    switch (type) {
      case 'recycling':
      case 'cutsWaste':
      case 'composting':
        return AppColors.cosmicGreen;
      case 'water':
      case 'optimizesResources':
      case 'energy':
      case 'solar':
        return AppColors.nebulaBlue;
      default:
        return AppColors.cosmicPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your\nRecords',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 4),
                Text(
                  'Every action is a star in your cosmos.',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 150.ms),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── RECENT ACTIVITY ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RECENT ACTIVITY',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 2,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AllRecordsScreen(
                                    userId: widget.userData['uid'] as String? ?? '',
                                  )),
                        ),
                        child: Text(
                          'View All →',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            color: AppColors.nebulaBlue,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),

                  // Loading shimmer
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                          color: AppColors.nebulaBlue,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  // Empty state
                  else if (_recent.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      borderColor: AppColors.cosmicGreen.withValues(alpha: 0.2),
                      child: Column(
                        children: [
                          const Text('🌱',
                              style: TextStyle(fontSize: 36)),
                          const SizedBox(height: 10),
                          const Text(
                            'No activities yet!',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start an action below to earn your first Stardust ✨',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms)
                  // Real recent cards
                  else
                    ..._recent.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;
                      final actionType =
                          r['actionType'] as String? ?? 'other';
                      final emoji =
                          _actionEmoji[actionType] ?? '🌍';
                      final stardust =
                          (r['stardustAwarded'] as num?)?.toInt() ?? 0;
                      final date = (r['createdAt'] as String? ?? '')
                          .split('T')
                          .first;
                      final description =
                          r['description'] as String? ?? actionType;
                      final color = _colorForAction(actionType);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecordCard(
                          emoji: emoji,
                          title: description,
                          category: actionType,
                          stardust: stardust,
                          date: date,
                          color: color,
                        ).animate().fadeIn(
                            delay:
                                Duration(milliseconds: 300 + i * 100)),
                      );
                    }),

                  const SizedBox(height: 28),

                  // ── ADD NEW RECORD ────────────────────────────────────────
                  Text(
                    'ADD NEW RECORD',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),

                  // Categories
                  ...AppConstants.categories.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    final color = Color(cat['color'] as int);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddRecordScreen(
                              userData: widget.userData,
                              initialCategory: cat['id'] as String,
                            ),
                          ),
                        ).then((_) => _loadRecentActivity()), // refresh after submitting
                        padding: const EdgeInsets.all(20),
                        borderColor: color.withValues(alpha: 0.3),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: color.withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  cat['icon'] as String,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat['title'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${(cat['activities'] as List).length} suggested activities',
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: color, size: 16),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay:
                                  Duration(milliseconds: 500 + i * 100))
                          .slideX(begin: 0.05, end: 0),
                    );
                  }),

                  // Custom activity button
                  GlassButton(
                    text: '+ Add Your Own Activity',
                    isOutline: true,
                    color: AppColors.stardustGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddRecordScreen(
                          userData: widget.userData,
                          isCustom: true,
                        ),
                      ),
                    ).then((_) => _loadRecentActivity()), // refresh after submitting
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Record Card Widget ─────────────────────────────────────────────────────────

class _RecordCard extends StatelessWidget {
  final String emoji, title, category, date;
  final int stardust;
  final Color color;

  const _RecordCard({
    required this.emoji,
    required this.title,
    required this.category,
    required this.stardust,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withValues(alpha: 0.2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$category · $date',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.stardustGold.withValues(alpha: 0.15),
            ),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '+$stardust',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.stardustGold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}