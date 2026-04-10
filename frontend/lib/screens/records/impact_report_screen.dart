import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

/// Full-page Impact Report showing aggregated sustainability data,
/// narrative report, charts, and blind spots.
/// Works for both individual users and college/org accounts.
class ImpactReportScreen extends StatefulWidget {
  final String entityId; // userId or collegeId
  final bool isCollege;

  const ImpactReportScreen({
    super.key,
    required this.entityId,
    this.isCollege = false,
  });

  @override
  State<ImpactReportScreen> createState() => _ImpactReportScreenState();
}

class _ImpactReportScreenState extends State<ImpactReportScreen> {
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String? _error;

  // 0 = Weekly, 1 = Monthly, 2 = Yearly
  int _timePeriod = 1;

  static const _periodLabels = ['Weekly', 'Monthly', 'Yearly'];
  static const _periodKeys = ['weekly', 'monthly', 'yearly'];

  // Line chart metric selector
  String _selectedMetric = 'co2';
  static const _metricMeta = {
    'co2':     {'label': 'CO₂ (kg)',    'color': AppColors.cosmicGreen},
    'energy':  {'label': 'Energy (kWh)','color': AppColors.stardustGold},
    'water':   {'label': 'Water (L)',   'color': AppColors.nebulaBlue},
    'actions': {'label': 'Actions',     'color': AppColors.cosmicPurple},
  };

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = widget.isCollege
          ? await ApiService.instance.getCollegeImpactReport(widget.entityId)
          : await ApiService.instance.getImpactReport(widget.entityId);
      setState(() {
        _report = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load impact report.\nCheck that the backend is running.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── App bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Impact Report',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!_isLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: AppColors.nebulaBlue),
                        onPressed: _loadReport,
                      ),
                  ],
                ),
              ),
              // ── Body ───────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.nebulaBlue))
                    : _error != null
                        ? _buildError()
                        : _buildReport(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Outfit', color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          GlassButton(text: 'Retry', onTap: _loadReport),
        ],
      ),
    );
  }

  Widget _buildReport() {
    final report = _report!;
    final summary = report['summary'] as Map<String, dynamic>? ?? {};
    final narrative = report['narrativeReport'] as String? ?? '';
    final blindSpots =
        (report['blindSpots'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final actionBreakdown =
        (report['actionBreakdown'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt()));
    final periodData =
        (report[_periodKeys[_timePeriod]] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Time period toggle ────────────────────────────────────────
          _buildTimePeriodToggle()
              .animate()
              .fadeIn(duration: 300.ms),
          const SizedBox(height: 20),

          // ── Summary stat cards ────────────────────────────────────────
          _buildSummaryCards(summary)
              .animate()
              .fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // ── Bar chart: impact over time ──────────────────────────────
          _sectionTitle('IMPACT OVER TIME'),
          const SizedBox(height: 12),
          if (periodData.isNotEmpty)
            _buildBarChart(periodData)
                .animate()
                .fadeIn(delay: 200.ms)
                .slideY(begin: 0.05, end: 0)
          else
            _buildEmptyChart('No data for this period')
                .animate()
                .fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          // ── Donut chart: action breakdown ─────────────────────────────
          if (actionBreakdown.isNotEmpty) ...[
            _sectionTitle('ACTION BREAKDOWN'),
            const SizedBox(height: 12),
            _buildDonutChart(actionBreakdown)
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.05, end: 0),
            const SizedBox(height: 24),
          ],

          // ── Narrative report ─────────────────────────────────────────
          _sectionTitle('DETAILED REPORT'),
          const SizedBox(height: 12),
          _buildNarrativeCard(narrative)
              .animate()
              .fadeIn(delay: 400.ms),
          const SizedBox(height: 24),

          // ── chartSeries Line Chart ────────────────────────────────────
          _sectionTitle('IMPACT TREND'),
          const SizedBox(height: 8),
          _buildMetricToggle()
              .animate()
              .fadeIn(delay: 450.ms),
          const SizedBox(height: 8),
          _buildLineChart(report)
              .animate()
              .fadeIn(delay: 480.ms)
              .slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),

          // ── Blind spots ──────────────────────────────────────────────
          if (blindSpots.isNotEmpty) ...[
            _sectionTitle('⚠️ BLIND SPOTS'),
            const SizedBox(height: 12),
            ...blindSpots.asMap().entries.map((e) =>
                _buildBlindSpotCard(e.value)
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: 500 + e.key * 100))),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ── Time period toggle ──────────────────────────────────────────────────

  Widget _buildTimePeriodToggle() {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(4),
      borderRadius: 16,
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _timePeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timePeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isActive
                      ? AppColors.nebulaBlue.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isActive
                        ? AppColors.nebulaBlue.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Text(
                    _periodLabels[i],
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.nebulaBlue
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Summary cards ───────────────────────────────────────────────────────

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final cards = [
      _StatCard(
          icon: '🌿',
          value: '${_fmt(summary['totalCo2Kg'])} kg',
          label: 'CO₂ Saved',
          color: AppColors.cosmicGreen),
      _StatCard(
          icon: '⚡',
          value: '${_fmt(summary['totalEnergyKwh'])} kWh',
          label: 'Energy Saved',
          color: AppColors.stardustGold),
      _StatCard(
          icon: '💧',
          value: '${_fmt(summary['totalWaterL'])} L',
          label: 'Water Saved',
          color: AppColors.nebulaBlue),
      _StatCard(
          icon: '✨',
          value: '${(summary['totalStardust'] as num?)?.toInt() ?? 0}',
          label: 'Stardust',
          color: AppColors.cosmicPurple),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards,
    );
  }

  String _fmt(dynamic val) {
    if (val == null) return '0';
    final n = (val as num).toDouble();
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n == n.roundToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(1);
  }

  // ── Bar chart ───────────────────────────────────────────────────────────

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    // Take last 8 periods max for readability
    final displayData = data.length > 8 ? data.sublist(data.length - 8) : data;
    final maxCo2 = displayData
        .map((d) => (d['co2Kg'] as num? ?? 0).toDouble())
        .fold<double>(0, max);
    final maxEnergy = displayData
        .map((d) => (d['energyKwh'] as num? ?? 0).toDouble())
        .fold<double>(0, max);
    final maxVal = max(maxCo2, maxEnergy);
    final yMax = maxVal == 0 ? 10.0 : maxVal * 1.2;

    return LiquidGlassCard(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      borderColor: AppColors.nebulaBlue.withValues(alpha: 0.2),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: yMax,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final label = rodIndex == 0 ? 'CO₂' : 'Energy';
                  return BarTooltipItem(
                    '$label: ${rod.toY.toStringAsFixed(1)}',
                    const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11,
                        color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= displayData.length) {
                      return const SizedBox.shrink();
                    }
                    final label =
                        displayData[idx]['label'] as String? ?? '';
                    // Shorten long labels
                    final short = label.length > 6
                        ? label.substring(0, 6)
                        : label;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        short,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                  reservedSize: 28,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _fmt(value),
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.glassBorder,
                strokeWidth: 0.5,
              ),
            ),
            barGroups: displayData.asMap().entries.map((e) {
              final d = e.value;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: (d['co2Kg'] as num? ?? 0).toDouble(),
                    color: AppColors.cosmicGreen,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: (d['energyKwh'] as num? ?? 0).toDouble(),
                    color: AppColors.stardustGold,
                    width: 10,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(String msg) {
    return LiquidGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      borderColor: AppColors.glassBorder,
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // ── Donut chart ─────────────────────────────────────────────────────────

  static const _actionColors = {
    'solar': AppColors.stardustGold,
    'composting': AppColors.cosmicGreen,
    'recycling': Color(0xFF4CAF50),
    'eWaste': Color(0xFFFF7043),
    'water': AppColors.nebulaBlue,
    'energy': Color(0xFFFFEB3B),
    'transport': Color(0xFF42A5F5),
    'cutsWaste': Color(0xFF66BB6A),
    'optimizesResources': Color(0xFF29B6F6),
    'lowersEmissions': Color(0xFFAB47BC),
    'other': AppColors.textMuted,
  };

  static const _actionEmoji = {
    'solar': '☀️', 'composting': '🌿', 'recycling': '♻️',
    'eWaste': '🔌', 'water': '💧', 'energy': '💡',
    'transport': '🚲', 'cutsWaste': '🗑️',
    'optimizesResources': '⚡', 'lowersEmissions': '🌱', 'other': '🌍',
  };

  Widget _buildDonutChart(Map<String, int> breakdown) {
    final total = breakdown.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = breakdown.entries.map((e) {
      final color =
          _actionColors[e.key] ?? AppColors.textMuted;
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${(e.value / total * 100).round()}%',
        radius: 40,
        titleStyle: const TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return LiquidGlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.cosmicPurple.withValues(alpha: 0.2),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 36,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: breakdown.entries.map((e) {
              final color =
                  _actionColors[e.key] ?? AppColors.textMuted;
              final emoji = _actionEmoji[e.key] ?? '🌍';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$emoji ${e.key} (${e.value})',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Metric toggle for line chart ────────────────────────────────────────

  Widget _buildMetricToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _metricMeta.entries.map((entry) {
          final selected = _selectedMetric == entry.key;
          final color = entry.value['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedMetric = entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected
                    ? color.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.6)
                      : AppColors.glassBorder,
                ),
              ),
              child: Text(
                entry.value['label'] as String,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? color : AppColors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Line chart using chartSeries ─────────────────────────────────────────

  Widget _buildLineChart(Map<String, dynamic> report) {
    final chartSeries =
        report['chartSeries'] as Map<String, dynamic>? ?? {};
    final periodData =
        chartSeries[_periodKeys[_timePeriod]] as Map<String, dynamic>? ?? {};

    final labels = (periodData['labels'] as List<dynamic>? ?? [])
        .cast<String>();
    final rawValues = (periodData[_selectedMetric] as List<dynamic>? ?? []);
    final values = rawValues.map((v) => (v as num).toDouble()).toList();

    if (labels.isEmpty || values.isEmpty) {
      return _buildEmptyChart('No trend data for this period');
    }

    final color = _metricMeta[_selectedMetric]!['color'] as Color;
    final spots = values.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final maxVal = values.fold<double>(0, max);
    final yMax = maxVal == 0 ? 1.0 : maxVal * 1.25;

    return LiquidGlassCard(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
      borderColor: color.withValues(alpha: 0.2),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: yMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: AppColors.glassBorder,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    _fmt(value),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: labels.length > 6
                      ? (labels.length / 4).ceilToDouble()
                      : 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= labels.length) {
                      return const SizedBox.shrink();
                    }
                    final raw = labels[idx];
                    final short = raw.length > 6 ? raw.substring(0, 6) : raw;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        short,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: spots.length <= 12,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.backgroundPrimary,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) =>
                    touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final label =
                      idx < labels.length ? labels[idx] : '';
                  return LineTooltipItem(
                    '$label\n${_fmt(spot.y)}',
                    TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Narrative card ──────────────────────────────────────────────────────

  Widget _buildNarrativeCard(String narrative) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.cosmicGreen.withValues(alpha: 0.2),
      child: MarkdownBody(
        data: narrative,
        styleSheet: MarkdownStyleSheet(
          h2: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          h3: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.nebulaBlue,
          ),
          p: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          strong: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          em: const TextStyle(
            fontFamily: 'Outfit',
            fontStyle: FontStyle.italic,
            color: AppColors.textMuted,
          ),
          listBullet: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Blind spot card ─────────────────────────────────────────────────────

  Widget _buildBlindSpotCard(Map<String, dynamic> spot) {
    final color = spot['category'] == 'cutsWaste'
        ? AppColors.cosmicGreen
        : spot['category'] == 'optimizesResources'
            ? AppColors.nebulaBlue
            : AppColors.cosmicPurple;
    final suggestions =
        (spot['suggestions'] as List<dynamic>? ?? []).cast<String>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(18),
        borderColor: AppColors.stardustGold.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(spot['icon'] as String? ?? '⚠️',
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spot['title'] as String? ?? 'Unknown',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: spot['severity'] == 'blind'
                        ? AppColors.reefCoral.withValues(alpha: 0.15)
                        : AppColors.stardustGold.withValues(alpha: 0.15),
                  ),
                  child: Text(
                    spot['severity'] == 'blind'
                        ? '🔴 0 actions logged'
                        : '🟡 ${(spot['coveragePct'] as num?)?.toInt() ?? 0}% coverage',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: spot['severity'] == 'blind'
                          ? AppColors.reefCoral
                          : AppColors.stardustGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              spot['message'] as String? ?? '',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Try these:',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              ...suggestions.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_right, size: 14, color: color),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ── Section title helper ────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Montserrat',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 2,
      ),
    );
  }
}

// ── Summary stat card widget ──────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String icon, value, label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: color.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}