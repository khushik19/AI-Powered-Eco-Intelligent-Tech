import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class LeaderboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const LeaderboardScreen({super.key, required this.userData});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _filter = 'Global';
  final List<String> _filters = ['Global', 'Institution', 'City', 'State', 'Country'];

  static final _mockData = [
    {'name': 'Aryan Kapoor', 'institution': 'MIT Manipal', 'stardust': 840, 'emoji': '👑'},
    {'name': 'Priya Sharma', 'institution': 'IIT Bombay', 'stardust': 720, 'emoji': '🌟'},
    {'name': 'Ravi Mehta', 'institution': 'BITS Pilani', 'stardust': 650, 'emoji': '⭐'},
    {'name': 'Neha Singh', 'institution': 'NIT Trichy', 'stardust': 590, 'emoji': '✨'},
    {'name': 'Achal Goyal', 'institution': 'PIMR Indore', 'stardust': 480, 'emoji': '💫'},
    {'name': 'Khushi Katiyar', 'institution': 'PIMR Indore', 'stardust': 460, 'emoji': '🌙'},
    {'name': 'Siddharth Roy', 'institution': 'IIT Delhi', 'stardust': 410, 'emoji': '🔥'},
    {'name': 'Anjali Verma', 'institution': 'Symbiosis', 'stardust': 380, 'emoji': '🌿'},
  ];

  @override
  Widget build(BuildContext context) {
    final top3 = _mockData.take(3).toList();
    final rest = _mockData.skip(3).toList();

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
                    'Cosmos\nRankings 🏆',
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
                        onTap: () => setState(() => _filter = f),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Top 3 podium
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 2nd place
                      Expanded(
                        child: _PodiumCard(
                          rank: 2,
                          name: top3[1]['name'] as String,
                          stardust: top3[1]['stardust'] as int,
                          emoji: top3[1]['emoji'] as String,
                          height: 120,
                          color: const Color(0xFFC0C0C0),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 1st place
                      Expanded(
                        child: _PodiumCard(
                          rank: 1,
                          name: top3[0]['name'] as String,
                          stardust: top3[0]['stardust'] as int,
                          emoji: top3[0]['emoji'] as String,
                          height: 160,
                          color: AppColors.stardustGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3rd place
                      Expanded(
                        child: _PodiumCard(
                          rank: 3,
                          name: top3[2]['name'] as String,
                          stardust: top3[2]['stardust'] as int,
                          emoji: top3[2]['emoji'] as String,
                          height: 100,
                          color: const Color(0xFFCD7F32),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),
                  // Rest of rankings
                  ...rest.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final rank = i + 4;
                    final isUser = r['name'] == widget.userData['name'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        borderColor: isUser
                            ? AppColors.nebulaBlue.withOpacity(0.4)
                            : AppColors.glassBorder,
                        fillColor: isUser
                            ? AppColors.nebulaBlue.withOpacity(0.08)
                            : AppColors.glassWhite,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                '#$rank',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Text(r['emoji'] as String,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r['name'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isUser
                                          ? AppColors.nebulaBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    r['institution'] as String,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '✨ ${r['stardust']}',
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.stardustGold,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 400 + i * 80)),
                    );
                  }),
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

class _PodiumCard extends StatelessWidget {
  final int rank;
  final String name, emoji;
  final int stardust;
  final double height;
  final Color color;

  const _PodiumCard({
    required this.rank,
    required this.name,
    required this.emoji,
    required this.stardust,
    required this.height,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
              Text(
                '✨$stardust',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.stardustGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}