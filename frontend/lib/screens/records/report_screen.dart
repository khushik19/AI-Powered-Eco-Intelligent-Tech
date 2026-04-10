import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

enum ReportFilter { week, month, year }

class ReportScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ReportScreen({super.key, required this.userData});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportFilter _filter = ReportFilter.week;
  List<Map<String, dynamic>> _submissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final dash = await ApiService.instance
          .getStudentDashboard(widget.userData['uid'] as String? ?? '');
      final all = (dash['submissions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _submissions = all;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final now = DateTime.now();
    return _submissions.where((s) {
      final dateStr = s['createdAt'] as String? ?? '';
      if (dateStr.isEmpty) return false;
      try {
        final date = DateTime.parse(dateStr);
        switch (_filter) {
          case ReportFilter.week:
            return now.difference(date).inDays <= 7;
          case ReportFilter.month:
            return date.year == now.year && date.month == now.month;
          case ReportFilter.year:
            return date.year == now.year;
        }
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // Build category breakdown from filtered data
  Map<String, int> get _categoryBreakdown {
    final map = <String, int>{};
    for (final s in _filtered) {
      final type = s['actionType'] as String? ?? 'other';
      map[type] = (map[type] ?? 0) + 1;
    }
    return map;
  }

  // Totals
  int get _totalStardust => _filtered.fold(
      0, (sum, s) => sum + ((s['stardustAwarded'] as num?)?.toInt() ?? 0));
  double get _totalCo2 => _filtered.fold(
      0.0, (sum, s) => sum + ((s['co2ReducedKg'] as num?)?.toDouble() ?? 0.0));

  // Blindspots — categories with zero activity
  List<String> get _blindspots {
    final active = _categoryBreakdown.keys.toSet();
    final all = ['recycling', 'water', 'transport', 'energy', 'composting', 'solar'];
    return all.where((c) => !active.contains(c)).toList();
  }

  String _filterLabel(ReportFilter f) {
    switch (f) {
      case ReportFilter.week:
        return 'This Week';
      case ReportFilter.month:
        return 'This Month';
      case ReportFilter.year:
        return 'This Year';
    }
  }

  String _descriptionText() {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return 'No activities recorded for this period. Start making an impact!';
    }
    final topCat = _categoryBreakdown.entries.isEmpty
        ? 'various'
        : (_categoryBreakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
    return 'During ${_filterLabel(_filter).toLowerCase()}, you logged ${filtered.length} '
        'eco action${filtered.length == 1 ? '' : 's'}, earning $_totalStardust stardust '
        'and reducing approximately ${_totalCo2.toStringAsFixed(1)} kg of CO₂. '
        'Your most active category was $topCat. Keep up the cosmic work!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Your Report',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Filter pills
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: ReportFilter.values.map((f) {
                    final isActive = _filter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: isActive
                              ? AppColors.oliveGreen
                              : AppColors.glassWhite,
                          border: Border.all(
                            color: isActive
                                ? AppColors.oliveGreen
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          _filterLabel(f),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.oliveGreen))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats row
                            Row(
                              children: [
                                _StatTile(
                                  label: 'Actions',
                                  value: '${_filtered.length}',
                                  icon: Icons.eco,
                                  color: AppColors.oliveGreen,
                                ),
                                const SizedBox(width: 12),
                                _StatTile(
                                  label: 'Stardust',
                                  value: '$_totalStardust',
                                  icon: Icons.star,
                                  color: AppColors.cream,
                                ),
                                const SizedBox(width: 12),
                                _StatTile(
                                  label: 'CO₂ Saved',
                                  value: '${_totalCo2.toStringAsFixed(1)}kg',
                                  icon: Icons.air,
                                  color: AppColors.tealBlue,
                                ),
                              ],
                            ).animate().fadeIn(delay: 300.ms),
                            const SizedBox(height: 20),

                            // Text summary
                            GlassCard(
                              padding: const EdgeInsets.all(20),
                              borderColor:
                                  AppColors.oliveGreen.withOpacity(0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.description_outlined,
                                          color: AppColors.oliveGreen,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SUMMARY',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.oliveGreen,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _descriptionText(),
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 20),

                            // Bar chart — category breakdown
                            if (_categoryBreakdown.isNotEmpty) ...[
                              Text(
                                'ACTIVITY BREAKDOWN',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GlassCard(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: _categoryBreakdown.entries
                                      .map((entry) {
                                    final max = _categoryBreakdown.values
                                        .reduce((a, b) => a > b ? a : b);
                                    final pct = entry.value / max;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                entry.key,
                                                style: const TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                '${entry.value}x',
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.oliveGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: pct,
                                              backgroundColor:
                                                  AppColors.glassWhite,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                AppColors.oliveGreen,
                                              ),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ).animate().fadeIn(delay: 500.ms),
                              const SizedBox(height: 24),
                            ],

                            // Blindspots
                            if (_blindspots.isNotEmpty) ...[
                              Text(
                                'YOUR BLIND SPOTS',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'These are areas you haven\'t explored yet. Small steps here can make a big difference!',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ..._blindspots.map((b) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: GlassCard(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      borderColor: AppColors.dustyRose
                                          .withOpacity(0.3),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber_outlined,
                                              color: AppColors.dustyRose,
                                              size: 18),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'No activity in: $b',
                                              style: const TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 13,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            'Try it!',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.dustyRose,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
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
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        borderColor: color.withOpacity(0.3),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}