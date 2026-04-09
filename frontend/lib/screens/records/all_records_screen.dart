import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class AllRecordsScreen extends StatelessWidget {
  final String userId;
  const AllRecordsScreen({super.key, required this.userId});

  // Mock data — replace with Firestore stream
  static final _records = [
    {'emoji': '♻️', 'title': 'Used reusable bags', 'cat': 'Cut Waste', 'stars': 25, 'date': 'Apr 17', 'color': 0xFF06D6A0},
    {'emoji': '💧', 'title': 'Fixed a leaking tap', 'cat': 'Optimize Resources', 'stars': 40, 'date': 'Apr 16', 'color': 0xFF4FC3F7},
    {'emoji': '🚲', 'title': 'Cycled to college', 'cat': 'Lower Emissions', 'stars': 35, 'date': 'Apr 15', 'color': 0xFF7B5EA7},
    {'emoji': '🌱', 'title': 'Planted a sapling', 'cat': 'Lower Emissions', 'stars': 60, 'date': 'Apr 14', 'color': 0xFF7B5EA7},
    {'emoji': '💡', 'title': 'Switched to LED bulbs', 'cat': 'Optimize Resources', 'stars': 30, 'date': 'Apr 13', 'color': 0xFF4FC3F7},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      'All Activities',
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _records.length,
                  itemBuilder: (context, i) {
                    final r = _records[i];
                    final color = Color(r['color'] as int);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        borderColor: color.withOpacity(0.2),
                        child: Row(
                          children: [
                            Text(r['emoji'] as String,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['title'] as String,
                                      style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary)),
                                  Text(
                                      '${r['cat']} · ${r['date']}',
                                      style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: AppColors.stardustGold.withOpacity(0.15),
                              ),
                              child: Text(
                                '✨ +${r['stars']}',
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.stardustGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}