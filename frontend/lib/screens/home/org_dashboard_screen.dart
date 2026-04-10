import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class OrgDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const OrgDashboardScreen({super.key, required this.userData});

  @override
  State<OrgDashboardScreen> createState() => _OrgDashboardScreenState();
}

class _OrgDashboardScreenState extends State<OrgDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = widget.userData['uid'] as String? ?? '';
    if (uid.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No college ID found.';
      });
      return;
    }
    try {
      final data =
          await ApiService.instance.getCollegeDashboardBackend(uid);
      if (mounted) setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : _DashboardContent(
                    data: _data!,
                    collegeName: widget.userData['name'] as String? ?? 'Your College',
                    uid: widget.userData['uid'] as String? ?? '',
                  ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final String collegeName;
  final String uid;
  const _DashboardContent({required this.data, required this.collegeName, required this.uid});

  Map<String, dynamic> get college =>
      (data['college'] as Map<String, dynamic>? ?? {});

  Map<String, dynamic> get monthlyCo2 =>
      (data['monthlyCo2'] as Map<String, dynamic>? ?? {});

  Map<String, dynamic> get actionBreakdown =>
      (data['actionBreakdown'] as Map<String, dynamic>? ?? {});

  List<String> get blindSpots =>
      (data['blindSpots'] as List? ?? []).cast<String>();

  List<String> get recommendations =>
      (data['recommendations'] as List? ?? []).cast<String>();

  String get tier =>
      college['accreditationTier'] as String? ?? 'seedling';

  int get score =>
      (college['accreditationScore'] as num? ?? 0).toInt();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _TierHeader(
                  name: collegeName,
                  tier: tier,
                  score: score,
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 20),

                // Impact stats row
                _ImpactStats(college: college)
                    .animate()
                    .fadeIn(delay: 200.ms),
                const SizedBox(height: 20),

                // Monthly CO2 chart
                if (monthlyCo2.isNotEmpty) ...[
                  _SectionLabel('Monthly CO₂ Reduced (kg)'),
                  const SizedBox(height: 10),
                  _Co2Chart(monthlyCo2: monthlyCo2)
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                ],

                // Action breakdown
                if (actionBreakdown.isNotEmpty) ...[
                  _SectionLabel('Eco-Action Breakdown'),
                  const SizedBox(height: 10),
                  _ActionBreakdown(breakdown: actionBreakdown)
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 20),
                ],

                // Blind spots
                if (blindSpots.isNotEmpty) ...[
                  _SectionLabel('Blind Spots ⚠️'),
                  const SizedBox(height: 8),
                  _BlindSpots(spots: blindSpots)
                      .animate()
                      .fadeIn(delay: 500.ms),
                  const SizedBox(height: 20),
                ],

                // AI Recommendations
                if (recommendations.isNotEmpty) ...[
                  _SectionLabel('AI Recommendations ✨'),
                  const SizedBox(height: 8),
                  _Recommendations(recs: recommendations)
                      .animate()
                      .fadeIn(delay: 600.ms),
                  const SizedBox(height: 20),
                ],

                // Students Leaderboard
                _SectionLabel('Your Top Students'),
                const SizedBox(height: 10),
                _CollegeStudentLeaderboard(collegeId: uid)
                    .animate()
                    .fadeIn(delay: 700.ms),

                const SizedBox(height: 160),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tier Header ──────────────────────────────────────────────────────────────

class _TierHeader extends StatelessWidget {
  final String name, tier;
  final int score;
  const _TierHeader(
      {required this.name, required this.tier, required this.score});

  Color get tierColor {
    switch (tier) {
      case 'platinum':
        return const Color(0xFFB0E0E6);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      default:
        return AppColors.forestGreen;
    }
  }

  IconData get tierIcon {
    switch (tier) {
      case 'platinum':
        return Icons.diamond;
      case 'gold':
        return Icons.emoji_events;
      case 'silver':
        return Icons.star_half;
      default:
        return Icons.eco;
    }
  }

  int get nextMilestone {
    if (score < 100) return 100;
    if (score < 200) return 200;
    if (score < 500) return 500;
    return score + 100;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (score / nextMilestone).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: tierColor.withOpacity(0.5),
      gradient: LinearGradient(
        colors: [tierColor.withOpacity(0.1), Colors.transparent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tierIcon, color: tierColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${tier[0].toUpperCase()}${tier.substring(1)} Tier',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: tierColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tierColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score pts',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score / $nextMilestone to next tier',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Impact Stats ─────────────────────────────────────────────────────────────

class _ImpactStats extends StatelessWidget {
  final Map<String, dynamic> college;
  const _ImpactStats({required this.college});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'CO₂ Reduced',
        'value':
            '${((college['totalCo2Kg'] as num? ?? 0)).toStringAsFixed(1)} kg',
        'icon': Icons.cloud_done_outlined,
        'color': AppColors.tealBlue,
      },
      {
        'label': 'Energy Saved',
        'value':
            '${((college['totalEnergySavedKwh'] as num? ?? 0)).toStringAsFixed(1)} kWh',
        'icon': Icons.bolt_outlined,
        'color': AppColors.oliveGreen,
      },
      {
        'label': 'Water Saved',
        'value':
            '${((college['totalWaterSavedL'] as num? ?? 0)).toStringAsFixed(0)} L',
        'icon': Icons.water_drop_outlined,
        'color': AppColors.nebulaBlue,
      },
      {
        'label': 'E-Waste',
        'value':
            '${((college['totalEWasteKg'] as num? ?? 0)).toStringAsFixed(1)} kg',
        'icon': Icons.devices_outlined,
        'color': AppColors.dustyRose,
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: items.map((item) {
        final color = item['color'] as Color;
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderColor: color.withOpacity(0.3),
          child: Row(
            children: [
              Icon(item['icon'] as IconData, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['value'] as String,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── CO2 Line Chart ───────────────────────────────────────────────────────────

class _Co2Chart extends StatelessWidget {
  final Map<String, dynamic> monthlyCo2;
  const _Co2Chart({required this.monthlyCo2});

  @override
  Widget build(BuildContext context) {
    final sorted = monthlyCo2.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), (e.value.value as num).toDouble());
    }).toList();

    final maxY =
        spots.map((s) => s.y).fold(0.0, max).clamp(1.0, double.infinity) *
            1.2;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: SizedBox(
        height: 150,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppColors.glassBorder,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    final month = sorted[idx].key;
                    final label = month.length >= 7
                        ? month.substring(5, 7)
                        : month;
                    return Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                  reservedSize: 20,
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppColors.tealBlue,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 3,
                    color: AppColors.tealBlue,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.tealBlue.withOpacity(0.25),
                      AppColors.tealBlue.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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

// ─── Action Breakdown ─────────────────────────────────────────────────────────

class _ActionBreakdown extends StatelessWidget {
  final Map<String, dynamic> breakdown;
  const _ActionBreakdown({required this.breakdown});

  static const _iconMap = {
    'solar': Icons.wb_sunny_outlined,
    'composting': Icons.compost,
    'recycling': Icons.recycling,
    'eWaste': Icons.devices,
    'water': Icons.water_drop_outlined,
    'energy': Icons.bolt_outlined,
    'transport': Icons.directions_bus_outlined,
    'cutsWaste': Icons.delete_outline,
    'optimizesResources': Icons.water_outlined,
    'lowersEmissions': Icons.eco,
    'other': Icons.star_outline,
  };

  static const _colorMap = [
    AppColors.tealBlue,
    AppColors.forestGreen,
    AppColors.oliveGreen,
    AppColors.dustyRose,
    AppColors.nebulaBlue,
    AppColors.cosmicPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    final total = sorted.fold<int>(
        0, (sum, e) => sum + (e.value as num).toInt());

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final count = (e.value as num).toInt();
          final pct = total > 0 ? count / total : 0.0;
          final color = _colorMap[i % _colorMap.length];
          final label = e.key[0].toUpperCase() + e.key.substring(1);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Icon(
                  _iconMap[e.key] ?? Icons.star_outline,
                  color: color,
                  size: 16,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.glassWhite,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Blind Spots ─────────────────────────────────────────────────────────────

class _BlindSpots extends StatelessWidget {
  final List<String> spots;
  const _BlindSpots({required this.spots});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.dustyRose.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your college has not recorded any activity in:',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: spots
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.dustyRose.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.dustyRose.withOpacity(0.4)),
                      ),
                      child: Text(
                        s[0].toUpperCase() + s.substring(1),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11,
                          color: AppColors.dustyRose,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ─── AI Recommendations ───────────────────────────────────────────────────────

class _Recommendations extends StatelessWidget {
  final List<String> recs;
  const _Recommendations({required this.recs});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: recs.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderColor: AppColors.oliveGreen.withOpacity(0.35),
            gradient: LinearGradient(
              colors: [
                AppColors.oliveGreen.withOpacity(0.08),
                Colors.transparent
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.oliveGreen.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.oliveGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load dashboard',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.oliveGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.oliveGreen.withOpacity(0.4)),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: AppColors.oliveGreen,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Students Leaderboard ─────────────────────────────────────────────────────

class _CollegeStudentLeaderboard extends StatelessWidget {
  final String collegeId;
  const _CollegeStudentLeaderboard({required this.collegeId});

  @override
  Widget build(BuildContext context) {
    if (collegeId.isEmpty) return const SizedBox.shrink();
    
    // Query users by collegeId. 
    // We sort locally by 'stardust' to prevent requiring a Firestore Composite Index!
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('collegeId', isEqualTo: collegeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.bioTeal));
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error));
        }
        
        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No students have registered under your college yet.',
              style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Outfit', fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }
        
        // Local sort
        final list = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        list.sort((a, b) => (b['stardust'] as num? ?? 0).compareTo(a['stardust'] as num? ?? 0));

        // Let's cap at top 50 
        final displayList = list.take(50).toList();

        return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: displayList.asMap().entries.map((entry) {
              final idx = entry.key;
              final data = entry.value;
              final name = data['name'] ?? 'Unknown';
              final stardust = data['stardust'] ?? 0;
              
              Color rankColor = AppColors.bioTeal.withOpacity(0.3);
              Color textColor = AppColors.textMuted;
              if (idx == 0) {
                rankColor = const Color(0xFFFFD700); // Gold
                textColor = const Color(0xFFFFD700);
              } else if (idx == 1) {
                rankColor = const Color(0xFFC0C0C0); // Silver
                textColor = const Color(0xFFC0C0C0);
              } else if (idx == 2) {
                rankColor = const Color(0xFFCD7F32); // Bronze
                textColor = const Color(0xFFCD7F32);
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: rankColor.withOpacity(0.15),
                  child: Text('${idx + 1}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'Outfit', fontSize: 14)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.neonMoss, size: 14),
                    const SizedBox(width: 6),
                    Text('$stardust', style: const TextStyle(color: AppColors.neonMoss, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
