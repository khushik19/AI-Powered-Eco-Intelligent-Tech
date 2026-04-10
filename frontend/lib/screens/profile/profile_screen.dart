import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar + name
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.cosmicPurple, AppColors.nebulaBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cosmicPurple.withOpacity(0.4),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  (userData['name'] as String? ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(
              userData['name'] as String? ?? 'Cosmic Explorer',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ).animate().fadeIn(delay: 200.ms),
            Text(
              userData['email'] as String? ?? '',
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 28),
            // Stats row
            Row(
              children: [
                _StatCard(
                  label: 'Stardust',
                  value: '${userData['stardust'] ?? 0}',
                  icon: '✨',
                  color: AppColors.stardustGold,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Streak',
                  value: '${userData['weeklyStreak'] ?? 0}w',
                  icon: '🔥',
                  color: AppColors.cosmicGreen,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Actions',
                  value: '${userData['totalActions'] ?? 0}',
                  icon: '🌱',
                  color: AppColors.nebulaBlue,
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 28),
            // Profile details
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ProfileField(
                    icon: Icons.location_city_outlined,
                    label: 'City',
                    value: userData['city'] as String? ?? '—',
                  ),
                  _Divider(),
                  _ProfileField(
                    icon: Icons.map_outlined,
                    label: 'State',
                    value: userData['state'] as String? ?? '—',
                  ),
                  _Divider(),
                  _ProfileField(
                    icon: Icons.public_outlined,
                    label: 'Country',
                    value: userData['country'] as String? ?? '—',
                  ),
                  _Divider(),
                  _ProfileField(
                    icon: Icons.phone_outlined,
                    label: 'Contact',
                    value: userData['phone'] as String? ?? '—',
                  ),
                  if ((userData['institution'] as String? ?? '').isNotEmpty) ...[
                    _Divider(),
                    _ProfileField(
                      icon: Icons.business_outlined,
                      label: 'Institution',
                      value: userData['institution'] as String,
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 20),
            GlassButton(
              text: 'Sign Out',
              isOutline: true,
              color: AppColors.error,
              onTap: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                }
              },
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 160),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        borderColor: color.withOpacity(0.3),
        child: Column(
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

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileField({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: AppColors.glassBorder,
      height: 1,
    );
  }
}