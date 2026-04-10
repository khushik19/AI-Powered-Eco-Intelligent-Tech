import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';

class AllRecordsScreen extends StatefulWidget {
  final String userId;
  const AllRecordsScreen({super.key, required this.userId});

  @override
  State<AllRecordsScreen> createState() => _AllRecordsScreenState();
}

class _AllRecordsScreenState extends State<AllRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String? _error;

  // Maps actionType → emoji
  static const _actionEmoji = {
    'solar': '☀️',
    'composting': '🌿',
    'recycling': '♻️',
    'eWaste': '🔌',
    'water': '💧',
    'energy': '💡',
    'transport': '🚲',
    'cutsWaste': '🗑️',
    'optimizesResources': '⚡',
    'lowersEmissions': '🌱',
    'other': '🌍',
  };

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dash = await ApiService.instance.getStudentDashboard(widget.userId);
      final submissions = (dash['submissions'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() { _records = submissions; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = 'Could not load your records.\nCheck that the backend is running.';
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
                    const Spacer(),
                    if (!_isLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.nebulaBlue),
                        onPressed: _loadRecords,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.nebulaBlue),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('⚠️', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        color: AppColors.textSecondary)),
                                const SizedBox(height: 16),
                                GlassButton(text: 'Retry', onTap: _loadRecords),
                              ],
                            ),
                          )
                        : _records.isEmpty
                            ? const Center(
                                child: Text(
                                  'No activities yet!\nStart making an impact 🌱',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: AppColors.textSecondary,
                                      fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(24),
                                itemCount: _records.length,
                                itemBuilder: (context, i) {
                                  final r = _records[i];
                                  final actionType =
                                      r['actionType'] as String? ?? 'other';
                                  final emoji =
                                      _actionEmoji[actionType] ?? '🌍';
                                  final stardust =
                                      (r['stardustAwarded'] as num?)
                                          ?.toInt() ??
                                          0;
                                  final date =
                                      (r['createdAt'] as String? ?? '')
                                          .split('T')
                                          .first;
                                  final color = _colorForAction(actionType);

                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      borderColor: color.withOpacity(0.2),
                                      child: Row(
                                        children: [
                                          Text(emoji,
                                              style: const TextStyle(
                                                  fontSize: 24)),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  r['description'] as String? ??
                                                      actionType,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: AppColors
                                                          .textPrimary),
                                                ),
                                                Text(
                                                  '$actionType · $date',
                                                  style: const TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .textSecondary),
                                                ),
                                                if ((r['impactSummary']
                                                        as String?) !=
                                                    null)
                                                  Text(
                                                    r['impactSummary']
                                                        as String,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 11,
                                                      color: color,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              color: AppColors.stardustGold
                                                  .withOpacity(0.15),
                                            ),
                                            child: Text(
                                              '✨ +$stardust',
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

  Color _colorForAction(String type) {
    switch (type) {
      case 'recycling':
      case 'cutsWaste':
      case 'composting':
        return AppColors.cosmicGreen;
      case 'water':
      case 'optimizesResources':
      case 'energy':
      case 'solar':
        return AppColors.nebulaBlue;
      default:
        return AppColors.cosmicPurple;
    }
  }
}