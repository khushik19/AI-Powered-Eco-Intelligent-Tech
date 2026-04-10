import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class LeaderboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const LeaderboardScreen({super.key, required this.userData});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late String _filter;
  late List<String> _filters;

  bool get _isCollege => widget.userData['role'] == 'college_org';

  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_isCollege) {
      _filter = 'All Colleges';
      _filters = ['All Colleges'];
    } else {
      _filter = 'Global';
      _filters = ['Global', 'Institution', 'City', 'State'];
    }
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard({String? filter}) async {
    final activeFilter = filter ?? _filter;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? collegeId;
      String? city;
      String? state;

      switch (activeFilter) {
        case 'Institution':
          collegeId = widget.userData['collegeId'] as String?;
          break;
        case 'City':
          city = widget.userData['city'] as String?;
          break;
        case 'State':
          state = widget.userData['state'] as String?;
          break;
        default:
          break;
      }

      List<Map<String, dynamic>> results;
      if (_isCollege) {
        results = await ApiService.instance.getCollegeLeaderboard();
      } else {
        results = await ApiService.instance.getIndividualLeaderboard(
          collegeId: collegeId,
          city: city,
          state: state,
        );
      }
      
      setState(() {
        _data = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error =
            'Failed to load rankings.${_filter != 'Global' ? '\nTry a different filter.' : ''}';
        _isLoading = false;
      });
    }
  }

  String _filterHint() {
    switch (_filter) {
      case 'Institution':
        final col = widget.userData['collegeId'] as String? ??
            widget.userData['institution'] as String?;
        return col != null ? 'Showing: $col' : 'No institution in your profile';
      case 'City':
        final city = widget.userData['city'] as String?;
        return city != null ? 'Showing: $city' : 'No city in your profile';
      case 'State':
        final state = widget.userData['state'] as String?;
        return state != null ? 'Showing: $state' : 'No state in your profile';
      case 'All Colleges':
        return 'Ranking colleges by Accreditation Score';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(
            child: CircularProgressIndicator(color: AppColors.bioTeal)),
      );
    }
    if (_error != null) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontFamily: 'Outfit', color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              AppButton(text: 'Retry', onTap: _fetchLeaderboard),
            ],
          ),
        ),
      );
    }

    final top3 = _data.take(3).toList();
    final rest = _data.skip(3).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.stardustGold, AppColors.cosmicPurple],
                  ).createShader(b),
                  child: const Text(
                    'Cosmos\nRankings',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 16),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, i) {
                      final f = _filters[i];
                      final isActive = _filter == f;
                      return GestureDetector(
                        onTap: () {
                          if (_filter == f) return;
                          setState(() => _filter = f);
                          _fetchLeaderboard(filter: f);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isActive
                                ? AppColors.cosmicPurple
                                : AppColors.glassWhite,
                            border: Border.all(
                              color: isActive
                                  ? AppColors.cosmicPurple
                                  : AppColors.glassBorder,
                            ),
                          ),
                          child: Text(
                            f,
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
                    },
                  ),
                ).animate().fadeIn(delay: 200.ms),
                if (_filter != 'Global') ...[
                  const SizedBox(height: 8),
                  Text(
                    _filterHint(),
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: AppColors.cosmicPurple,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (top3.length >= 3)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _PodiumCard(
                            rank: 2,
                            name: top3[1]['name'] as String? ?? 'Unknown',
                            stardust: _isCollege 
                                ? (top3[1]['accreditationScore'] as num?)?.toInt() ?? 0
                                : (top3[1]['stardust'] as num?)?.toInt() ?? 0,
                            height: 120,
                            color: const Color(0xFFC0C0C0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PodiumCard(
                            rank: 1,
                            name: top3[0]['name'] as String? ?? 'Unknown',
                            stardust: _isCollege 
                                ? (top3[0]['accreditationScore'] as num?)?.toInt() ?? 0
                                : (top3[0]['stardust'] as num?)?.toInt() ?? 0,
                            height: 160,
                            color: AppColors.stardustGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PodiumCard(
                            rank: 3,
                            name: top3[2]['name'] as String? ?? 'Unknown',
                            stardust: _isCollege 
                                ? (top3[2]['accreditationScore'] as num?)?.toInt() ?? 0
                                : (top3[2]['stardust'] as num?)?.toInt() ?? 0,
                            height: 100,
                            color: const Color(0xFFCD7F32),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 20),
                  ...rest.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final rank = i + 4;
                    final isUser =
                        r['name'] == widget.userData['name'];
                    final stardust = _isCollege
                        ? (r['accreditationScore'] as num?)?.toInt() ?? 0
                        : (r['stardust'] as num?)?.toInt() ?? 0;
                    final institution = _isCollege
                        ? '${r['city'] ?? ''}, ${r['state'] ?? ''}'.trim()
                        : r['collegeId'] as String? ?? r['institution'] as String? ?? '—';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LiquidGlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        borderColor: isUser
                            ? AppColors.bioTeal.withOpacity(0.4)
                            : AppColors.glassBorder,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                '#$rank',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['name'] as String? ?? 'Unknown',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isUser
                                          ? AppColors.bioTeal
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    institution,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    color: AppColors.stardustGold, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '$stardust',
                                  style: const TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.stardustGold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          delay: Duration(milliseconds: 400 + i * 60)),
                    );
                  }),
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

class _PodiumCard extends StatelessWidget {
  final int rank;
  final String name;
  final int stardust;
  final double height;
  final Color color;

  const _PodiumCard({
    required this.rank,
    required this.name,
    required this.stardust,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rank crown icon instead of emoji
        Icon(
          rank == 1 ? Icons.emoji_events : Icons.star,
          color: color,
          size: rank == 1 ? 32 : 24,
        ),
        const SizedBox(height: 4),
        Text(
          name.split(' ').first,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12)),
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: AppColors.stardustGold, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    '$stardust',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11,
                      color: AppColors.stardustGold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}