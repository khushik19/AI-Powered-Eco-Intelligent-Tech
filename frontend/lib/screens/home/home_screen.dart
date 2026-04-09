import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../records/records_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';
import 'meet_the_stars_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _chatExpanded = false;
  bool _showStardustRain = false;
  late AnimationController _chatController;
  late Animation<double> _chatAnimation;

  @override
  void initState() {
    super.initState();
    _chatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _chatAnimation = CurvedAnimation(
      parent: _chatController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() => _chatExpanded = !_chatExpanded);
    if (_chatExpanded) {
      _chatController.forward();
      // Navigate to chatbot after short delay
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()));
          setState(() => _chatExpanded = false);
          _chatController.reverse();
        }
      });
    } else {
      _chatController.reverse();
    }
  }

  bool get isCollegeOrg =>
      widget.userData['role'] == 'college_org';

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
        showStardustRain: _showStardustRain,
        child: Stack(
          children: [
            // Page content
            IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
            // Bottom navigation + floating chat
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Floating chatbox button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassCard(
                      onTap: _toggleChat,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      borderColor: AppColors.nebulaBlue.withOpacity(0.4),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.nebulaBlue,
                                  AppColors.cosmicPurple
                                ],
                              ),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Ask EcoGPT anything...',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.open_in_new,
                              color: AppColors.nebulaBlue, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bottom nav bar
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
                      // Logo → Meet the Stars
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MeetTheStarsScreen()),
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.cosmicPurple,
                                AppColors.nebulaBlue
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Text('🌌', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Weekly streak
                      _TopBadge(
                        icon: '🔥',
                        label: '${userData['weeklyStreak'] ?? 0}',
                        sublabel: 'streak',
                        color: AppColors.stardustGold,
                      ),
                      const SizedBox(width: 10),
                      // Stardust count
                      _TopBadge(
                        icon: '✨',
                        label: '${userData['stardust'] ?? 0}',
                        sublabel: 'stardust',
                        color: AppColors.cosmicPurple,
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 36),
                  // Greeting
                  Text(
                    'Hello, ${(userData['name'] as String? ?? 'Star').split(' ').first} 🌠',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Colors.white, AppColors.nebulaBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(b),
                    child: const Text(
                      'What\'s your\nimpact today?',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 28),
                  // Main prompt card
                  GlassCard(
                    onTap: onRecordTap,
                    padding: const EdgeInsets.all(24),
                    borderColor: AppColors.cosmicGreen.withOpacity(0.3),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cosmicGreen.withOpacity(0.08),
                        AppColors.nebulaBlue.withOpacity(0.05),
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
                              Text(
                                'Tell us about how you\nhelped clean the Cosmos today?',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Earn stardust for every action ✨',
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
                            color: AppColors.cosmicGreen.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.cosmicGreen,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  // Category quick actions
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickActionChip(
                        emoji: '♻️',
                        label: 'Cut Waste',
                        color: AppColors.cosmicGreen,
                        onTap: onRecordTap,
                      ),
                      const SizedBox(width: 10),
                      _QuickActionChip(
                        emoji: '💧',
                        label: 'Resources',
                        color: AppColors.nebulaBlue,
                        onTap: onRecordTap,
                      ),
                      const SizedBox(width: 10),
                      _QuickActionChip(
                        emoji: '🌱',
                        label: 'Emissions',
                        color: AppColors.cosmicPurple,
                        onTap: onRecordTap,
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 180), // space for bottom nav
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
  final String icon, label, sublabel;
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
          Text(icon, style: const TextStyle(fontSize: 16)),
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
  final String emoji, label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionChip({
    required this.emoji,
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
              Text(emoji, style: const TextStyle(fontSize: 22)),
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
      {'icon': Icons.list_alt_outlined, 'active': Icons.list_alt, 'label': 'Records'},
      {'icon': Icons.leaderboard_outlined, 'active': Icons.leaderboard, 'label': 'Ranks'},
      if (isOrg)
        {'icon': Icons.dashboard_outlined, 'active': Icons.dashboard, 'label': 'Dashboard'}
      else
        {'icon': Icons.person_outline, 'active': Icons.person, 'label': 'Profile'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D2B).withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final isActive = currentIndex == i;
                final color = isActive ? AppColors.nebulaBlue : AppColors.textMuted;
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
      ),
    );
  }
}

// Placeholder for org dashboard (Person B will fill this)
class OrgDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const OrgDashboardScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          'Organisation Dashboard\n(Coming soon)',
          style: const TextStyle(
              fontFamily: 'Outfit', color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}