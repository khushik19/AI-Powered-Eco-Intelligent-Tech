import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/liquid_glass_card.dart';
import '../../services/api_service.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../records/records_screen.dart';
import '../records/add_record_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';
import 'meet_the_stars_screen.dart';
import 'org_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  bool get _isOrg => widget.userData['role'] == 'college_org';

  List<Widget> get _pages => [
        _DashboardTab(
          userData: widget.userData,
          onRecordTap: () => setState(() => _selectedIndex = 1),
        ),
        RecordsScreen(userData: widget.userData),
        LeaderboardScreen(userData: widget.userData),
        _isOrg
            ? OrgDashboardScreen(userData: widget.userData)
            : ProfileScreen(userData: widget.userData),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: CosmicBackground(
        showStardustRain: false,
        child: Stack(
          children: [
            IndexedStack(index: _selectedIndex, children: _pages),
            // Nebula FAB — liquid glass pill floating above nav
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: _NebulaFAB(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChatbotScreen(userData: widget.userData)),
                  ),
                ),
              ),
            ),
            // Liquid Glass Nav Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LiquidGlassNavBar(
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                items: [
                  const LiquidGlassNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  const LiquidGlassNavItem(
                    icon: Icons.list_alt_outlined,
                    activeIcon: Icons.list_alt_rounded,
                    label: 'Records',
                  ),
                  const LiquidGlassNavItem(
                    icon: Icons.leaderboard_outlined,
                    activeIcon: Icons.leaderboard_rounded,
                    label: 'Ranks',
                  ),
                  LiquidGlassNavItem(
                    icon: _isOrg ? Icons.dashboard_outlined : Icons.person_outline,
                    activeIcon: _isOrg ? Icons.dashboard_rounded : Icons.person_rounded,
                    label: _isOrg ? 'Dashboard' : 'Profile',
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

// ─────────────────────────────────────────────────────────────────────────────
// Nebula FAB — liquid glass pill
// ─────────────────────────────────────────────────────────────────────────────

class _NebulaFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _NebulaFAB({required this.onTap});

  @override
  State<_NebulaFAB> createState() => _NebulaFABState();
}

class _NebulaFABState extends State<_NebulaFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: child,
      ),
      child: LiquidGlassCard(
        onTap: widget.onTap,
        borderRadius: 30,
        tintColor: AppColors.bioTeal,
        blurStrength: 24,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: AppColors.bioTeal, size: 18),
            SizedBox(width: 8),
            Text(
              'Nebula',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ── Home Dashboard Tab ────────────────────────────────────────────────────────

class _DashboardTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onRecordTap;
  const _DashboardTab({required this.userData, required this.onRecordTap});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _challenge;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final collegeId = widget.userData['institution'] as String? ??
        widget.userData['collegeId'] as String? ??
        '';
    try {
      final c = await ApiService.instance.getChallenge(collegeId);
      if (mounted) setState(() => _challenge = c);
    } catch (_) {}
  }

  String get _challengeText {
    if (_challenge == null) {
      return 'This week: Reduce single-use plastic in 3 meals. Log each meal to earn bonus stardust!';
    }
    final title = _challenge!['title'] as String? ?? '';
    final desc = _challenge!['description'] as String? ?? '';
    final pts = _challenge!['pointReward'] as int? ?? 0;
    return '$title${desc.isNotEmpty ? '\n$desc' : ''}${pts > 0 ? ' (+$pts stardust)' : ''}';
  }

  @override
  Widget build(BuildContext context) {

    final stardust = widget.userData['stardust'] ?? 0;
    final streak = widget.userData['weeklyStreak'] ?? 0;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── Top bar: Logo left | Streak + Stardust right ──────────
                  Row(
                    children: [
                      // Logo — taps to Meet the Stars
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MeetTheStarsScreen()),
                        ),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.eco,
                              color: AppColors.spruceLight,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Streak badge with fire graphic
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        borderColor: AppColors.reefCoral.withOpacity(0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CustomPaint(painter: _FirePainter()),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$streak',
                              style: const TextStyle(
                                color: AppColors.reefCoral,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Stardust badge with star graphic
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        borderColor: AppColors.stardustGold.withOpacity(0.5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CustomPaint(
                                painter:
                                    _StarPainter(color: AppColors.stardustGold),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$stardust',
                              style: const TextStyle(
                                color: AppColors.stardustGold,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '10,000 Stardust = 1 Carbon Credit',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontFamily: 'Outfit',
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Hero prompt ───────────────────────────────────────────
                  GestureDetector(
                    onTap: widget.onRecordTap,
                    child: LiquidGlassCard(
                      padding: const EdgeInsets.all(22),
                      borderColor: AppColors.bioTeal.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppColors.bioTeal, AppColors.kelp],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.bioTeal.withOpacity(0.35),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.eco,
                                color: AppColors.midnightBlack, size: 26),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tell us about how you\nhelped clean the Cosmos today?',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to add a record and earn stardust',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: AppColors.bioTeal, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Weekly Challenge ──────────────────────────────────────
                  GlassCard(
                    borderColor: AppColors.reefCoral.withOpacity(0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CustomPaint(
                                painter:
                                    _StarPainter(color: AppColors.reefCoral),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'WEEKLY CHALLENGE',
                              style: TextStyle(
                                color: AppColors.reefCoral,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _challenge == null
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.reefCoral,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Loading challenge...',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _challengeText,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontFamily: 'Outfit',
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Launchpad ───────────────────────────────────────
                  const Text(
                    'QUICK LAUNCHPAD',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Montserrat',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _LaunchpadItem(
                          icon: Icons.recycling,
                          label: 'Cut Waste',
                          color: AppColors.kelp,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddRecordScreen(
                                userData: widget.userData,
                                initialCategory: 'cut_waste',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LaunchpadItem(
                          icon: Icons.water_drop_outlined,
                          label: 'Resources',
                          color: AppColors.bioTeal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddRecordScreen(
                                userData: widget.userData,
                                initialCategory: 'optimize_resources',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LaunchpadItem(
                          icon: Icons.eco,
                          label: 'Emissions',
                          color: AppColors.cosmicGreen,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddRecordScreen(
                                userData: widget.userData,
                                initialCategory: 'lower_emissions',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

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

class _LaunchpadItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LaunchpadItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        borderColor: color.withOpacity(0.4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Painters — no emojis ───────────────────────────────────────────────

/// Flame/fire graphic for streak display.
class _FirePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: const [
          AppColors.reefCoral,
          Color(0xFFFFAA44),
          Colors.yellow,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.8, h * 0.2, w * 0.9, h * 0.4, w * 0.75, h * 0.55);
    path.cubicTo(w * 0.9, h * 0.3, w * 0.7, h * 0.5, w * 0.65, h * 0.7);
    path.cubicTo(w * 0.85, h * 0.5, w * 0.9, h * 0.75, w * 0.7, h);
    path.lineTo(w * 0.3, h);
    path.cubicTo(w * 0.1, h * 0.75, w * 0.15, h * 0.5, w * 0.35, h * 0.7);
    path.cubicTo(w * 0.3, h * 0.5, w * 0.1, h * 0.3, w * 0.25, h * 0.55);
    path.cubicTo(w * 0.1, h * 0.4, w * 0.2, h * 0.2, w * 0.5, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_FirePainter old) => false;
}

/// 5-point star graphic for stardust display.
class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.42;
    const numPoints = 5;

    final path = Path();
    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (i * math.pi / numPoints) - math.pi / 2;
      final r = i.isEven ? outerR : innerR;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => color != old.color;
}
