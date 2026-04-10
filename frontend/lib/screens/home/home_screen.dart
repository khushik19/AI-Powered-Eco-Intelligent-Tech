import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
<<<<<<< HEAD
import '../../widgets/liquid_glass_card.dart';
=======
import '../../widgets/cosmic_background.dart';
import '../../widgets/liquid_glass_card.dart';
import '../../widgets/glass_card.dart';
import '../../services/api_service.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../records/records_screen.dart';
import '../records/add_record_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../profile/profile_screen.dart';
import 'org_dashboard_screen.dart';
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd

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
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
<<<<<<< HEAD
      backgroundColor: AppColors.abyss,
      appBar: AppBar(
        backgroundColor: AppColors.abyss,
        elevation: 0,
        title: Text(
          'CleanCosmos',
          style: TextStyle(color: AppColors.bioTeal, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: AppColors.bioTeal),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back 🌿',
              style: TextStyle(color: AppColors.seaFoam, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Eco Dashboard',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            LiquidGlassCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.bioTeal, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eco Score',
                          style: TextStyle(color: AppColors.seaFoam, fontSize: 14),
                        ),
                        Text(
                          '87 / 100',
                          style: TextStyle(
                            color: AppColors.bioTeal,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
=======
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        showStardustRain: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      // Nebula chat FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatbotScreen(userData: widget.userData)),
        ),
        backgroundColor: AppColors.bioTeal,
        foregroundColor: AppColors.midnightBlack,
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Ask Nebula',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.bioTeal.withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.bioTeal),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt, color: AppColors.bioTeal),
              label: 'Records'),
          const NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard, color: AppColors.bioTeal),
              label: 'Ranks'),
          NavigationDestination(
              icon: Icon(_isOrg
                  ? Icons.dashboard_outlined
                  : Icons.person_outline),
              selectedIcon: Icon(
                  _isOrg ? Icons.dashboard : Icons.person,
                  color: AppColors.bioTeal),
              label: _isOrg ? 'Dashboard' : 'Profile'),
        ],
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
        widget.userData['collegeId'] as String? ?? '';
    try {
      final c = await ApiService.instance.getChallenge(collegeId);
      if (mounted) setState(() => _challenge = c);
    } catch (_) {}
  }

  String get _challengeText {
    if (_challenge == null) {
      return 'This week: Reduce single-use plastic in 3 meals. '
          'Log each meal to earn bonus stardust!';
    }
    final title = _challenge!['title'] as String? ?? '';
    final desc = _challenge!['description'] as String? ?? '';
    final pts = _challenge!['pointReward'] as int? ?? 0;
    return '$title${desc.isNotEmpty ? '\n$desc' : ''}${pts > 0 ? ' (+$pts stardust)' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.userData['name'] as String? ?? 'Star')
        .split(' ')
        .first;
    final stardust = widget.userData['stardust'] ?? 0;
    final streak = widget.userData['weeklyStreak'] ?? 0;

    return CosmicBackground(
      showStardustRain: false,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back 🌿',
                          style: TextStyle(
                              color: AppColors.seaFoam, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Hello, $name',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
                // Streak badge
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderColor: AppColors.reefCoral.withOpacity(0.4),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: AppColors.reefCoral, size: 18),
                      const SizedBox(width: 4),
                      Text('$streak',
                          style: const TextStyle(
                              color: AppColors.reefCoral,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stardust badge
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderColor: AppColors.bioTeal.withOpacity(0.4),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.bioTeal, size: 18),
                      const SizedBox(width: 4),
                      Text('$stardust',
                          style: const TextStyle(
                              color: AppColors.bioTeal,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
=======
      backgroundColor: Colors.transparent,
      body: CosmicBackground(
        showStardustRain: false,
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      // Nebula chat FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChatbotScreen(userData: widget.userData)),
        ),
        backgroundColor: AppColors.bioTeal,
        foregroundColor: AppColors.midnightBlack,
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Ask Nebula',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.backgroundSecondary,
        indicatorColor: AppColors.bioTeal.withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.bioTeal),
              label: 'Home'),
          const NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt, color: AppColors.bioTeal),
              label: 'Records'),
          const NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard, color: AppColors.bioTeal),
              label: 'Ranks'),
          NavigationDestination(
              icon: Icon(_isOrg
                  ? Icons.dashboard_outlined
                  : Icons.person_outline),
              selectedIcon: Icon(
                  _isOrg ? Icons.dashboard : Icons.person,
                  color: AppColors.bioTeal),
              label: _isOrg ? 'Dashboard' : 'Profile'),
        ],
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
        widget.userData['collegeId'] as String? ?? '';
    try {
      final c = await ApiService.instance.getChallenge(collegeId);
      if (mounted) setState(() => _challenge = c);
    } catch (_) {}
  }

  String get _challengeText {
    if (_challenge == null) {
      return 'This week: Reduce single-use plastic in 3 meals. '
          'Log each meal to earn bonus stardust!';
    }
    final title = _challenge!['title'] as String? ?? '';
    final desc = _challenge!['description'] as String? ?? '';
    final pts = _challenge!['pointReward'] as int? ?? 0;
    return '$title${desc.isNotEmpty ? '\n$desc' : ''}${pts > 0 ? ' (+$pts stardust)' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.userData['name'] as String? ?? 'Star')
        .split(' ')
        .first;
    final stardust = widget.userData['stardust'] ?? 0;
    final streak = widget.userData['weeklyStreak'] ?? 0;

    return CosmicBackground(
      showStardustRain: false,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back 🌿',
                          style: TextStyle(
                              color: AppColors.seaFoam, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Hello, $name',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
                // Streak badge
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderColor: AppColors.reefCoral.withOpacity(0.4),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          color: AppColors.reefCoral, size: 18),
                      const SizedBox(width: 4),
                      Text('$streak',
                          style: const TextStyle(
                              color: AppColors.reefCoral,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Stardust badge
                GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  borderColor: AppColors.bioTeal.withOpacity(0.4),
                  child: Row(
                    children: [
                      const Icon(Icons.star,
                          color: AppColors.bioTeal, size: 18),
                      const SizedBox(width: 4),
                      Text('$stardust',
                          style: const TextStyle(
                              color: AppColors.bioTeal,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
            const SizedBox(height: 24),

            // ── Log action card ──
            LiquidGlassCard(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: widget.onRecordTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: AppColors.bioTeal, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Log an eco-action',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Earn stardust for every action',
                              style: TextStyle(
                                  color: AppColors.seaFoam, fontSize: 13)),
                        ],
                      ),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
                    ),
                    Icon(Icons.arrow_forward_ios,
                        color: AppColors.bioTeal, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Weekly Challenge ──
            GlassCard(
              borderColor: AppColors.reefCoral.withOpacity(0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events,
                          color: AppColors.reefCoral, size: 16),
                      const SizedBox(width: 6),
                      Text('WEEKLY CHALLENGE',
                          style: TextStyle(
                            color: AppColors.reefCoral,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          )),
                    ],
                  ),
<<<<<<< HEAD
<<<<<<< HEAD
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Actions',
              style: TextStyle(
                color: AppColors.seaFoam.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
=======
                  const SizedBox(height: 8),
                  _challenge == null
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.reefCoral),
                            ),
                            const SizedBox(width: 8),
                            Text('Loading challenge…',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        )
                      : Text(_challengeText,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.5)),
                ],
              ),
            ),
=======
                  const SizedBox(height: 8),
                  _challenge == null
                      ? Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.reefCoral),
                            ),
                            const SizedBox(width: 8),
                            Text('Loading challenge…',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 12)),
                          ],
                        )
                      : Text(_challengeText,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.5)),
                ],
              ),
            ),
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
            const SizedBox(height: 24),

            // ── Quick Actions ──
            Text('QUICK ACTIONS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )),
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
<<<<<<< HEAD
<<<<<<< HEAD
              children: [
                _buildActionItem("Waste Scan", Icons.qr_code_scanner, AppColors.bioTeal),
                _buildActionItem("Eco Report", Icons.bar_chart, AppColors.reefCoral),
                _buildActionItem("Community", Icons.public, AppColors.kelp),
                _buildActionItem("AI Assistant", Icons.psychology, AppColors.bioTeal),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundSecondary,
        selectedItemColor: AppColors.bioTeal,
        unselectedItemColor: AppColors.softGrey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.eco), label: 'Eco'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
=======
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
              childAspectRatio: 2.2,
              children: [
                _QuickAction(
                    icon: Icons.recycling,
                    label: 'Cut Waste',
                    color: AppColors.kelp,
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddRecordScreen(
                                    userData: widget.userData,
                                    initialCategory: 'cut_waste',
                                  )),
                        )),
                _QuickAction(
                    icon: Icons.water_drop_outlined,
                    label: 'Resources',
                    color: AppColors.bioTeal,
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddRecordScreen(
                                    userData: widget.userData,
                                    initialCategory: 'optimize_resources',
                                  )),
                        )),
                _QuickAction(
                    icon: Icons.eco,
                    label: 'Emissions',
                    color: AppColors.neonMoss,
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddRecordScreen(
                                    userData: widget.userData,
                                    initialCategory: 'lower_emissions',
                                  )),
                        )),
                _QuickAction(
                    icon: Icons.bar_chart,
                    label: 'My Impact',
                    color: AppColors.reefCoral,
                    onTap: widget.onRecordTap),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
        ),
      ),
    );
  }

}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
<<<<<<< HEAD
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
=======
>>>>>>> 882ea7c6e10071e1ef12a7de13e7ecfc94d430dd
