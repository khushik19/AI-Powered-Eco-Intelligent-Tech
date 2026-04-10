import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../records/records_screen.dart';
import '../records/add_record_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';
import 'meet_the_stars_screen.dart';

// ... existing imports

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  bool get isCollegeOrg => widget.userData['role'] == 'college_org';

  List<Widget> get _pages => [
        _HomeContent(
          userData: widget.userData,
          onRecordTap: () => setState(() => _currentIndex = 1),
        ),
        RecordsScreen(userData: widget.userData),
        LeaderboardScreen(userData: widget.userData),
        isCollegeOrg
            ? OrgDashboardScreen(userData: widget.userData)
            : ProfileScreen(userData: widget.userData),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nebula chat bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassCard(
                      // UPDATED Navigator.push below:
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatbotScreen(userData: widget.userData),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      borderColor: AppColors.oliveGreen.withOpacity(0.4),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.tealBlue,
                                  AppColors.forestGreen,
                                ],
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ask Nebula anything...',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward,
                              color: AppColors.oliveGreen, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _BottomNavBar(
                    currentIndex: _currentIndex,
                    isOrg: isCollegeOrg,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onRecordTap;

  const _HomeContent({required this.userData, required this.onRecordTap});

  String get _weeklyChallenge =>
      'This week: Reduce single-use plastic in 3 meals. '
      'Log each plastic-free meal to earn bonus stardust!';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MeetTheStarsScreen()),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.forestGreen,
                                    AppColors.tealBlue
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.eco,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      _TopBadge(
                        icon: Icons.local_fire_department,
                        label: '${userData['weeklyStreak'] ?? 0}',
                        sublabel: 'streak',
                        color: AppColors.dustyRose,
                      ),
                      const SizedBox(width: 10),
                      _TopBadge(
                        icon: Icons.star,
                        label: '${userData['stardust'] ?? 0}',
                        sublabel: 'stardust',
                        color: AppColors.oliveGreen,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 36),

                  // Greeting
                  Text(
                    'Hello, ${(userData['name'] as String? ?? 'Star').split(' ').first}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.cream, AppColors.oliveGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(b),
                    child: Text(
                      '${(userData['name'] as String? ?? 'Star').split(' ').first}',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 24),

                  // Tell us prompt — arrow right instead of +
                  GlassCard(
                    onTap: onRecordTap,
                    padding: const EdgeInsets.all(24),
                    borderColor: AppColors.oliveGreen.withOpacity(0.3),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.oliveGreen.withOpacity(0.08),
                        AppColors.tealBlue.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tell us about how you\nhelped clean the Cosmos today?',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Earn stardust for every action',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.oliveGreen.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.arrow_forward, // arrow instead of +
                            color: AppColors.oliveGreen,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 16),

                  // Weekly challenge box
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    borderColor: AppColors.dustyRose.withOpacity(0.35),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.dustyRose.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.emoji_events,
                                      color: AppColors.dustyRose, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'WEEKLY CHALLENGE',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.dustyRose,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _weeklyChallenge,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 28),

                  // Quick Launchpad
                  Text(
                    'QUICK LAUNCHPAD',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickActionChip(
                        icon: Icons.recycling,
                        label: 'Cut Waste',
                        color: AppColors.oliveGreen,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddRecordScreen(
                              userData: userData,
                              initialCategory: 'cut_waste',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickActionChip(
                        icon: Icons.water_drop_outlined,
                        label: 'Resources',
                        color: AppColors.tealBlue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddRecordScreen(
                              userData: userData,
                              initialCategory: 'optimize_resources',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _QuickActionChip(
                        icon: Icons.eco,
                        label: 'Emissions',
                        color: AppColors.forestGreen,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddRecordScreen(
                              userData: userData,
                              initialCategory: 'lower_emissions',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 180),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;
  const _TopBadge({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 12,
      borderColor: color.withOpacity(0.3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: color.withOpacity(0.12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isOrg;
  final void Function(int) onTap;

  const _BottomNavBar({
    required this.currentIndex,
    required this.isOrg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'active': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.list_alt_outlined,
        'active': Icons.list_alt,
        'label': 'Records'
      },
      {
        'icon': Icons.leaderboard_outlined,
        'active': Icons.leaderboard,
        'label': 'Ranks'
      },
      if (isOrg)
        {
          'icon': Icons.dashboard_outlined,
          'active': Icons.dashboard,
          'label': 'Dashboard'
        }
      else
        {
          'icon': Icons.person_outline,
          'active': Icons.person,
          'label': 'Profile'
        },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withOpacity(0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isActive = currentIndex == i;
              final color =
                  isActive ? AppColors.oliveGreen : AppColors.textMuted;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive
                              ? item['active'] as IconData
                              : item['icon'] as IconData,
                          color: color,
                          size: 22,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10,
                            color: color,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class OrgDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const OrgDashboardScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Text(
          'Organisation Dashboard\n(Coming soon)',
          style: TextStyle(
              fontFamily: 'Outfit', color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}