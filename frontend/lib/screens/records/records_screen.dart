import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_card.dart';
import 'add_record_screen.dart';
import 'all_records_screen.dart';
import 'report_screen.dart';

class RecordsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const RecordsScreen({super.key, required this.userData});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> _recent = [];
  bool _isLoading = true;

  static const _actionIcons = <String, IconData>{
    'solar': Icons.wb_sunny_outlined,
    'composting': Icons.compost,
    'recycling': Icons.recycling,
    'eWaste': Icons.devices_outlined,
    'water': Icons.water_drop_outlined,
    'energy': Icons.bolt_outlined,
    'transport': Icons.directions_bike_outlined,
    'cutsWaste': Icons.delete_outline,
    'optimizesResources': Icons.water_outlined,
    'lowersEmissions': Icons.eco,
    'other': Icons.star_outline,
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
      final submissions =
          (dash['submissions'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>();
      setState(() {
        _recent = submissions.take(3).toList();
        _isLoading = false;
      });
    } catch (_) {
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
        return AppColors.bioTeal;
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
                const Text(
                  'Every action is a star in your cosmos.',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 150.ms),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Recent header + View All ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
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
                            ),
                          ),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: AppColors.bioTeal,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),

                  // ── Recent cards ──────────────────────────────────────────
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                            color: AppColors.bioTeal, strokeWidth: 2),
                      ),
                    )
                  else if (_recent.isEmpty)
                    LiquidGlassCard(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      borderColor: AppColors.bioTeal.withOpacity(0.2),
                      child: const Column(
                        children: [
                          Icon(Icons.eco,
                              color: AppColors.bioTeal, size: 36),
                          SizedBox(height: 10),
                          Text(
                            'No activities yet!',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Start an action below to earn your first Stardust',
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
                  else
                    ..._recent.asMap().entries.map((entry) {
                      final i = entry.key;
                      final r = entry.value;
                      final actionType =
                          r['actionType'] as String? ?? 'other';
                      final icon =
                          _actionIcons[actionType] ?? Icons.star_outline;
                      final stardust =
                          (r['stardustAwarded'] as num?)?.toInt() ?? 0;
                      final date = (r['createdAt'] as String? ?? '')
                          .split('T')
                          .first;
                      final description =
                          r['description'] as String? ?? actionType;
                      final color = _colorForAction(actionType);
                      final status = r['status'] as String? ?? 'verifying';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecordCard(
                          actionIcon: icon,
                          title: description,
                          category: actionType,
                          stardust: stardust,
                          date: date,
                          color: color,
                          status: status,
                        ).animate().fadeIn(
                            delay: Duration(
                                milliseconds: 300 + i * 100)),
                      );
                    }),

                  const SizedBox(height: 20),

                  // ── View Impact Report ────────────────────────────────────
                  const Text(
                    'YOUR IMPACT',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  const SizedBox(height: 12),

                  LiquidGlassCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReportScreen(userData: widget.userData),
                      ),
                    ),
                    padding: const EdgeInsets.all(22),
                    borderColor: AppColors.bioTeal.withOpacity(0.35),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.bioTeal, AppColors.cosmicGreen],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bioTeal.withOpacity(0.35),
                                blurRadius: 18,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.bar_chart_rounded,
                              color: AppColors.midnightBlack, size: 28),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'View Impact Report',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'CO2 saved, stardust earned\nand full sustainability breakdown.',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            color: AppColors.bioTeal, size: 16),
                      ],
                    ),
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 28),

                  // ── Add New Record ────────────────────────────────────────
                  const Text(
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

                  ...AppConstants.categories.asMap().entries.map((entry) {
                    final i = entry.key;
                    final cat = entry.value;
                    final color = Color(cat['color'] as int);
                    // Pick an icon for each category
                    final IconData catIcon;
                    switch (cat['id'] as String) {
                      case 'cut_waste':
                        catIcon = Icons.recycling;
                        break;
                      case 'optimize_resources':
                        catIcon = Icons.water_drop_outlined;
                        break;
                      default:
                        catIcon = Icons.eco;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: LiquidGlassCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddRecordScreen(
                              userData: widget.userData,
                              initialCategory: cat['id'] as String,
                            ),
                          ),
                        ).then((_) => _loadRecentActivity()),
                        padding: const EdgeInsets.all(20),
                        borderColor: color.withOpacity(0.3),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: color.withOpacity(0.15),
                              ),
                              child: Icon(catIcon, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              delay: Duration(
                                  milliseconds: 500 + i * 100))
                          .slideX(begin: 0.05, end: 0),
                    );
                  }),

                  // Add your own activity
                  AppButton(
                    text: '+ Add Your Own Activity',
                    isOutline: true,
                    color: AppColors.softGrey,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddRecordScreen(
                          userData: widget.userData,
                          isCustom: true,
                        ),
                      ),
                    ).then((_) => _loadRecentActivity()),
                  ).animate().fadeIn(delay: 800.ms),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final IconData actionIcon;
  final String title, category, date, status;
  final int stardust;
  final Color color;

  const _RecordCard({
    required this.actionIcon,
    required this.title,
    required this.category,
    required this.stardust,
    required this.date,
    required this.color,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isVerifying = status == 'verifying' || status == 'pending';
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: color.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
            ),
            child: Icon(actionIcon, color: color, size: 20),
          ),
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
                  '$category  $date',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (isVerifying)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.bioTeal,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Verifying...',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11,
                            color: AppColors.bioTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isVerifying
                  ? AppColors.bioTeal.withOpacity(0.12)
                  : AppColors.cosmicGreen.withOpacity(0.15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isVerifying ? Icons.hourglass_top : Icons.star,
                  color: isVerifying ? AppColors.bioTeal : AppColors.cosmicGreen,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  isVerifying ? 'Pending' : '+$stardust',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isVerifying
                        ? AppColors.bioTeal
                        : AppColors.cosmicGreen,
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