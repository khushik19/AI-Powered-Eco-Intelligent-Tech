import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Central service for all backend API calls.
/// Backend: https://ai-powered-eco-intelligent-tech.onrender.com
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _baseUrl =
      'https://ai-powered-eco-intelligent-tech.onrender.com';

  static final _db = FirebaseFirestore.instance;

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ─── Leaderboard ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getIndividualLeaderboard({
    String? collegeId,
    String? city,
    String? state,
    int limit = 50,
  }) async {
    final snap = await _db.collection('users').get();

    var users = snap.docs
        .map((d) => <String, dynamic>{'id': d.id, ...d.data()})
        .where((u) => u['role'] != 'college_org' && u['role'] != 'college')
        .toList();

    if (collegeId != null && collegeId.isNotEmpty) {
      users = users
          .where((u) =>
              u['collegeId'] == collegeId || u['institution'] == collegeId)
          .toList();
    }
    if (city != null && city.isNotEmpty) {
      users = users.where((u) => u['city'] == city).toList();
    }
    if (state != null && state.isNotEmpty) {
      users = users.where((u) => u['state'] == state).toList();
    }

    users.sort((a, b) {
      final sa = (a['stardust'] as num? ?? 0).toInt();
      final sb = (b['stardust'] as num? ?? 0).toInt();
      return sb.compareTo(sa);
    });

    return users.take(limit).toList();
  }

  Future<List<Map<String, dynamic>>> getCollegeLeaderboard({
    String? city,
    String? state,
    int limit = 20,
  }) async {
    final Query query = _db
        .collection('colleges')
        .orderBy('accreditationScore', descending: true);

    final snap = await query.get();
    var colleges = snap.docs
        .map((d) => <String, dynamic>{
              'id': d.id,
              ...((d.data() as Map<String, dynamic>?) ?? {})
            })
        .toList();

    if (city != null && city.isNotEmpty) {
      colleges = colleges.where((c) => c['city'] == city).toList();
    }
    if (state != null && state.isNotEmpty) {
      colleges = colleges.where((c) => c['state'] == state).toList();
    }

    return colleges.take(limit).toList();
  }

  // ─── Dashboard ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStudentDashboard(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final submissionsSnap = await _db
        .collection('submissions')
        .where('userId', isEqualTo: userId)
        .get();

    final submissions = submissionsSnap.docs.map((d) => d.data()).toList()
      ..sort((a, b) {
        final ta = a['createdAt'] as String? ?? '';
        final tb = b['createdAt'] as String? ?? '';
        return tb.compareTo(ta);
      });

    return {
      'user': userDoc.exists
          ? <String, dynamic>{'uid': userId, ...userDoc.data()!}
          : <String, dynamic>{},
      'submissions': submissions,
    };
  }

  Future<Map<String, dynamic>> getCollegeDashboard(String collegeId) async {
    final collegeDoc = await _db.collection('colleges').doc(collegeId).get();
    final submissionsSnap = await _db
        .collection('submissions')
        .where('collegeId', isEqualTo: collegeId)
        .get();

    final monthlyCo2 = <String, double>{};
    final actionTypes = <String, int>{};

    for (final doc in submissionsSnap.docs) {
      final d = doc.data();
      final month = (d['createdAt'] as String? ?? '').length >= 7
          ? (d['createdAt'] as String).substring(0, 7)
          : '';
      monthlyCo2[month] = (monthlyCo2[month] ?? 0) +
          (d['co2ReducedKg'] as num? ?? 0).toDouble();
      final at = d['actionType'] as String? ?? 'other';
      actionTypes[at] = (actionTypes[at] ?? 0) + 1;
    }

    return {
      'college': collegeDoc.exists ? collegeDoc.data()! : <String, dynamic>{},
      'monthlyCo2': monthlyCo2,
      'actionBreakdown': actionTypes,
    };
  }

  // ─── Chatbot ────────────────────────────────────────────────────────────────
  // Routes through the Render backend which calls OpenRouter server-side.
  // 35s timeout handles Render free-tier cold starts gracefully.

  Future<String> sendChatMessage(
    String query,
    List<Map<String, String>> history,
  ) async {
    debugPrint(
        '[Chat] POST $_baseUrl/chatbot/message (history=${history.length})');
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/chatbot/message'),
            headers: _headers,
            body: jsonEncode({'query': query, 'history': history}),
          )
          .timeout(const Duration(seconds: 35));

      debugPrint('[Chat] status=${res.statusCode} body_len=${res.body.length}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final reply = data['response'] as String? ?? '';
        if (reply.isNotEmpty) return reply;
      } else {
        debugPrint(
            '[Chat] error body: ${res.body.substring(0, res.body.length.clamp(0, 300))}');
      }
    } catch (e) {
      debugPrint('[Chat] exception: $e');
    }
    return "I'm having trouble reaching Nebula right now. Please try again in a moment!";
  }

  // ─── Submissions ────────────────────────────────────────────────────────────

  /// Upload image bytes to Firebase Storage. Returns URL or '' on failure.
  Future<String> _uploadImageToStorage(Uint8List bytes, String userId) async {
    // On web, Firebase Storage requires CORS configuration on the bucket.
    // When running on localhost (dev), CORS is blocked. We store the image
    // as a base64 data URL in Firestore instead — no CORS needed.
    if (kIsWeb) {
      debugPrint(
          '[SUBMIT] Step 1: Web mode — storing image as base64 data URL');
      final b64 = base64Encode(bytes);
      return 'data:image/jpeg;base64,$b64';
    }

    debugPrint(
        '[SUBMIT] Step 1: Uploading image (${bytes.length} bytes) to Firebase Storage...');
    final ref = FirebaseStorage.instance
        .ref()
        .child('submissions')
        .child(userId.isNotEmpty ? userId : 'anonymous')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task =
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final url = await task.ref.getDownloadURL();
    debugPrint('[SUBMIT] Step 1 DONE: imageUrl=$url');
    return url;
  }

  /// Sends image + description to AI. Returns the decoded response map.
  /// If AI says rejected=true, returns that map (caller must check).
  /// On network/parse failure returns a safe fallback (always approved).
  Future<Map<String, dynamic>> _classifyWithImage(
      Uint8List imageBytes, String description) async {
    debugPrint(
        '[SUBMIT AI] Sending image (${imageBytes.length} bytes) + description to AI...');
    try {
      // Compress: cap at 800KB of base64 to stay under API limits
      Uint8List sendBytes = imageBytes;
      if (imageBytes.length > 600000) {
        // Take first 600KB — good enough for visual classification
        sendBytes = imageBytes.sublist(0, 600000);
        debugPrint('[SUBMIT AI] Image truncated to 600KB for API');
      }
      final imageBase64 = base64Encode(sendBytes);

      final res = await http
          .post(
            Uri.parse('$_baseUrl/submissions/classify'),
            headers: _headers,
            body: jsonEncode({
              'imageBase64': imageBase64,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
          '[SUBMIT AI] Response: status=${res.statusCode} len=${res.body.length}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          final rejected = decoded['rejected'] == true;
          debugPrint('[SUBMIT AI] Parsed OK — rejected=$rejected');
          return decoded;
        }
      }
      debugPrint('[SUBMIT AI] Non-2xx or bad body — using fallback');
    } catch (e) {
      debugPrint('[SUBMIT AI] Exception: $e — using fallback');
    }

    // Fallback: approve with minimal points when AI is unreachable
    return {
      'success': true,
      'rejected': false,
      'isLegitimate': true,
      'rejectionReason': null,
      'actionType': 'other',
      'stardustAwarded': 10,
      'co2ReducedKg': 0.2,
      'energySavedKwh': 0.0,
      'waterSavedLiters': 0.0,
      'eWasteKg': 0.0,
      'estimatedCostSavingRupees': 0.0,
      'impactSummary': 'Eco-action recorded (AI offline — auto-approved).',
      'realWorldEquivalent': null,
    };
  }

  /// Main submission entry point — guaranteed to succeed.
  ///
  /// Flow:
  ///   [parallel] Upload image to Firebase Storage
  ///   [parallel] AI classify with 10 s timeout + fallback
  ///   → Save submission doc to Firestore
  ///   → Increment user stardust in Firestore
  Future<Map<String, dynamic>> submitAction({
    required String userId,
    required String collegeId,
    required String role,
    required Uint8List imageBytes,
    required String imageBase64, // kept for API compat but NOT sent to backend
    required String description,
    bool isPredefined = false,
    String? predefinedActionId,
  }) async {
    debugPrint(
        '[SUBMIT] ═══════════ START ═══════════ userId=$userId collegeId=$collegeId');

    // ── Step 1: Upload image (parallel with AI for speed) ─────────────────────
    final uploadFuture = _uploadImageToStorage(imageBytes, userId);

    // ── Step 2: AI classify WITH image ────────────────────────────────────────
    // We do this FIRST and check rejection BEFORE touching Firestore.
    debugPrint('[SUBMIT] Step 2: Sending image to AI validator...');
    final ai = await _classifyWithImage(imageBytes, description);

    // ── Check AI rejection immediately ─────────────────────────────────────────
    if (ai['rejected'] == true) {
      final reason = ai['rejectionReason'] as String? ??
          'This action was not recognized as a valid eco-activity.';
      debugPrint('[SUBMIT] REJECTED by AI: $reason');
      throw SubmissionRejectedException(reason);
    }

    // ── Collect upload result now (non-fatal) ─────────────────────────────────
    String imageUrl = '';
    try {
      imageUrl = await uploadFuture;
    } catch (e) {
      debugPrint('[SUBMIT] Step 1 FAILED (non-fatal): $e');
    }

    // ── Unpack ────────────────────────────────────────────────────────────────
    final actionType = ai['actionType'] as String? ?? 'other';
    final stardust = (ai['stardustAwarded'] as num?)?.toInt() ?? 25;
    final co2 = (ai['co2ReducedKg'] as num? ?? 0).toDouble();
    final energy = (ai['energySavedKwh'] as num? ?? 0).toDouble();
    final water = (ai['waterSavedLiters'] as num? ?? 0).toDouble();
    final eWaste = (ai['eWasteKg'] as num? ?? 0).toDouble();
    final costSaving =
        (ai['estimatedCostSavingRupees'] as num? ?? 0).toDouble();
    final impactSummary = ai['impactSummary'] as String? ?? 'Great eco action!';
    final realWorld = ai['realWorldEquivalent'] as String? ?? '';

    debugPrint('[SUBMIT] AI result: actionType=$actionType stardust=$stardust');

    // ── Step 3: Save to Firestore ──────────────────────────────────────────────
    final now = DateTime.now().toUtc().toIso8601String();
    final doc = <String, dynamic>{
      'userId': userId,
      'collegeId': collegeId,
      'role': role,
      'description': description,
      'imageUrl': imageUrl,
      'isPredefined': isPredefined,
      'actionType': actionType,
      'stardustAwarded': stardust,
      'co2ReducedKg': co2,
      'energySavedKwh': energy,
      'waterSavedLiters': water,
      'eWasteKg': eWaste,
      'estimatedCostSavingRupees': costSaving,
      'impactSummary': impactSummary,
      'realWorldEquivalent': realWorld,
      'status': 'approved',
      'createdAt': now,
    };

    debugPrint('[SUBMIT] Step 3: Saving submission to Firestore...');
    String submissionId = '';
    try {
      final ref = await _db.collection('submissions').add(doc);
      submissionId = ref.id;
      debugPrint('[SUBMIT] Step 3 DONE: submissionId=$submissionId');
    } catch (e) {
      debugPrint('[SUBMIT] Step 3 FAILED: $e');
    }

    // ── Step 4: Update user stardust ──────────────────────────────────────────
    if (userId.isNotEmpty) {
      debugPrint('[SUBMIT] Step 4: Updating user stardust +$stardust...');
      try {
        await _db.collection('users').doc(userId).update({
          'stardust': FieldValue.increment(stardust),
          'totalActions': FieldValue.increment(1),
          'lastActionDate': now,
        });
        debugPrint('[SUBMIT] Step 4 DONE');
      } catch (e) {
        debugPrint('[SUBMIT] Step 4 FAILED (non-fatal): $e');
      }
    } else {
      debugPrint('[SUBMIT] Step 4 SKIPPED: userId is empty');
    }

    // ── Step 4b: Sync college aggregate stats ─────────────────────────────────
    // This ensures College Leaderboard shows up-to-date accreditation scores.
    if (collegeId.isNotEmpty) {
      debugPrint('[SUBMIT] Step 4b: Syncing college stats...');
      try {
        await _db.collection('colleges').doc(collegeId).update({
          'totalStardust': FieldValue.increment(stardust),
          'accreditationScore': FieldValue.increment(stardust ~/ 10),
          'totalCo2Kg': FieldValue.increment(co2),
          'totalEnergySavedKwh': FieldValue.increment(energy),
          'totalWaterSavedL': FieldValue.increment(water),
          'totalEWasteKg': FieldValue.increment(eWaste),
        });
        // Update accreditation tier based on new score
        final collegeSnap =
            await _db.collection('colleges').doc(collegeId).get();
        final score =
            (collegeSnap.data()?['accreditationScore'] as num? ?? 0).toInt();
        final tier = score >= 500
            ? 'platinum'
            : score >= 200
                ? 'gold'
                : score >= 100
                    ? 'silver'
                    : 'seedling';
        await _db
            .collection('colleges')
            .doc(collegeId)
            .update({'accreditationTier': tier});
        debugPrint('[SUBMIT] Step 4b DONE: tier=$tier score=$score');
      } catch (e) {
        debugPrint('[SUBMIT] Step 4b FAILED (non-fatal): $e');
      }
    }

    debugPrint('[SUBMIT] ═══════════ COMPLETE ═══════════ stardust=$stardust');

    return {
      'success': true,
      'submissionId': submissionId,
      'actionType': actionType,
      'stardustAwarded': stardust,
      'co2ReducedKg': co2,
      'energySavedKwh': energy,
      'waterSavedLiters': water,
      'eWasteKg': eWaste,
      'estimatedCostSavingRupees': costSaving,
      'impactSummary': impactSummary,
      'realWorldEquivalent': realWorld,
    };
  }

  // ─── College Dashboard (Backend) ────────────────────────────────────────────
  /// Fetches full college dashboard including AI recommendations from backend.
  /// Falls back to Firestore-direct data on failure.
  Future<Map<String, dynamic>> getCollegeDashboardBackend(
      String collegeId) async {
    debugPrint('[Dashboard] GET $_baseUrl/dashboard/college/$collegeId');
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/dashboard/college/$collegeId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        debugPrint('[Dashboard] OK — keys=${data.keys.join(",")}');
        return data;
      }
      debugPrint(
          '[Dashboard] HTTP ${res.statusCode} — using Firestore fallback');
    } catch (e) {
      debugPrint('[Dashboard] exception: $e — using Firestore fallback');
    }
    // Firestore fallback
    return getCollegeDashboard(collegeId);
  }

  // ─── Challenges ─────────────────────────────────────────────────────────────
  /// Returns the active weekly challenge for a college (or a default).
  Future<Map<String, dynamic>> getChallenge(String collegeId) async {
    debugPrint('[Challenge] GET $_baseUrl/challenges/$collegeId');
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/challenges/$collegeId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          // Return first active challenge
          return data.first as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('[Challenge] exception: $e — using default');
    }
    // Default challenge fallback
    return {
      'title': 'This week: Reduce single-use plastic in 3 meals.',
      'description': 'Log each plastic-free meal to earn bonus stardust!',
      'pointReward': 50,
    };
  }

  // ─── Suggestions ────────────────────────────────────────────────────────────
  /// Student submits a sustainability suggestion to their college.
  Future<bool> submitSuggestion({
    required String userId,
    required String collegeId,
    required String title,
    required String description,
  }) async {
    debugPrint('[Suggestion] POST $_baseUrl/suggestions/');
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/suggestions/'),
            headers: _headers,
            body: jsonEncode({
              'userId': userId,
              'collegeId': collegeId,
              'title': title,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint('[Suggestion] exception: $e');
      return false;
    }
  }

  /// College admin fetches all suggestions from students.
  Future<List<Map<String, dynamic>>> getSuggestions(String collegeId) async {
    debugPrint('[Suggestion] GET $_baseUrl/suggestions/$collegeId');
    try {
      final res = await http
          .get(
            Uri.parse('$_baseUrl/suggestions/$collegeId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint('[Suggestion] exception: $e');
    }
    return [];
  }

  /// Fetch personal impact report for a user.
  /// Tries backend first (15 s), then falls back to Firestore-direct computation.
  Future<Map<String, dynamic>> getImpactReport(String userId) async {
    debugPrint('[Report] GET $_baseUrl/dashboard/impact-report/user/$userId');
    try {
      final res = await http
          .get(Uri.parse('$_baseUrl/dashboard/impact-report/user/$userId'),
              headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('[Report] HTTP ${res.statusCode} — falling back to Firestore');
    } catch (e) {
      debugPrint('[Report] exception: $e — falling back to Firestore');
    }
    return _buildLocalImpactReport(userId);
  }

  /// Fetch college-wide impact report.
  /// Tries backend first (15 s), then falls back to Firestore-direct computation.
  Future<Map<String, dynamic>> getCollegeImpactReport(String collegeId) async {
    debugPrint(
        '[Report] GET $_baseUrl/dashboard/impact-report/college/$collegeId');
    try {
      final res = await http
          .get(
              Uri.parse('$_baseUrl/dashboard/impact-report/college/$collegeId'),
              headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      debugPrint('[Report] HTTP ${res.statusCode} — falling back to Firestore');
    } catch (e) {
      debugPrint('[Report] exception: $e — falling back to Firestore');
    }
    return _buildLocalCollegeImpactReport(collegeId);
  }

  // ─── Local (Firestore-direct) Impact Report ──────────────────────────────────
  // Used as a fallback when the backend is unreachable or cold-starting.

  Future<Map<String, dynamic>> _buildLocalImpactReport(String userId) async {
    debugPrint(
        '[Report] Building local impact report from Firestore for user=$userId');
    final snap = await _db
        .collection('submissions')
        .where('userId', isEqualTo: userId)
        .get();
    final subs = snap.docs.map((d) => d.data()).toList();
    return _aggregateSubmissions(subs);
  }

  Future<Map<String, dynamic>> _buildLocalCollegeImpactReport(
      String collegeId) async {
    debugPrint(
        '[Report] Building local college impact report from Firestore for college=$collegeId');
    final snap = await _db
        .collection('submissions')
        .where('collegeId', isEqualTo: collegeId)
        .get();
    final subs = snap.docs.map((d) => d.data()).toList();
    return _aggregateSubmissions(subs);
  }

  /// Aggregates a list of Firestore submission maps into the same shape
  /// that the backend returns, so the ImpactReportScreen works identically.
  Map<String, dynamic> _aggregateSubmissions(List<Map<String, dynamic>> subs) {
    double totalCo2 = 0, totalEnergy = 0, totalWater = 0, totalStardust = 0;
    final actionBreakdown = <String, int>{};

    // Time-series buckets: key → {label, co2Kg, energyKwh, waterL, actions}
    final weeklyBuckets = <String, Map<String, dynamic>>{};
    final monthlyBuckets = <String, Map<String, dynamic>>{};
    final yearlyBuckets = <String, Map<String, dynamic>>{};

    for (final s in subs) {
      final co2 = (s['co2ReducedKg'] as num? ?? 0).toDouble();
      final energy = (s['energySavedKwh'] as num? ?? 0).toDouble();
      final water = (s['waterSavedLiters'] as num? ?? 0).toDouble();
      final dust = (s['stardustAwarded'] as num? ?? 0).toDouble();
      final action = s['actionType'] as String? ?? 'other';

      totalCo2 += co2;
      totalEnergy += energy;
      totalWater += water;
      totalStardust += dust;
      actionBreakdown[action] = (actionBreakdown[action] ?? 0) + 1;

      // Parse date
      DateTime dt;
      try {
        dt = DateTime.parse((s['createdAt'] as String? ?? '')
            .split('+')[0]
            .replaceAll('Z', ''));
      } catch (_) {
        dt = DateTime.now();
      }

      // Week bucket — ISO week number: (dayOfYear - weekday + 10) ~/ 7
      final weekStart = dt.subtract(Duration(days: dt.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final dayOfYear = dt.difference(DateTime(dt.year, 1, 1)).inDays + 1;
      final isoWeek = (dayOfYear - dt.weekday + 10) ~/ 7;
      final weekKey = '${dt.year}-W${_twoDigit(isoWeek.clamp(1, 53))}';
      final weekLabel = '${_mmmDd(weekStart)}–${_mmmDd(weekEnd)}';
      _addToBucket(weeklyBuckets, weekKey, weekLabel, co2, energy, water);

      // Month bucket
      final monthKey = '${dt.year}-${_twoDigit(dt.month)}';
      final monthLabel = '${_monthName(dt.month)} ${dt.year}';
      _addToBucket(monthlyBuckets, monthKey, monthLabel, co2, energy, water);

      // Year bucket
      final yearKey = '${dt.year}';
      _addToBucket(yearlyBuckets, yearKey, yearKey, co2, energy, water);
    }

    // Sort chronologically
    List<Map<String, dynamic>> sorted(Map<String, Map<String, dynamic>> m) => m
        .entries
        .map((e) => <String, dynamic>{'period': e.key, ...e.value})
        .toList()
      ..sort(
          (a, b) => (a['period'] as String).compareTo(b['period'] as String));

    final weekly = sorted(weeklyBuckets);
    final monthly = sorted(monthlyBuckets);
    final yearly = sorted(yearlyBuckets);

    Map<String, dynamic> toChartSeries(List<Map<String, dynamic>> buckets) => {
          'labels': buckets.map((b) => b['label'] ?? b['period']).toList(),
          'co2': buckets.map((b) => _round(b['co2Kg'])).toList(),
          'energy': buckets.map((b) => _round(b['energyKwh'])).toList(),
          'water': buckets.map((b) => _round(b['waterL'])).toList(),
          'actions': buckets.map((b) => b['actions']).toList(),
        };

    final total = subs.length;
    final narrative = total == 0
        ? '## 🌍 Sustainability Impact Report\n\n*No eco-actions logged yet. Start making an impact today!*'
        : '## 🌍 Sustainability Impact Report\n\n'
            '### ✨ Overall Impact\nAcross **$total recorded actions**:\n\n'
            '🌿 **${totalCo2.toStringAsFixed(1)} kg of CO₂** reduced\n\n'
            '⚡ **${totalEnergy.toStringAsFixed(1)} kWh** of energy saved\n\n'
            '💧 **${totalWater.toStringAsFixed(0)} liters** of water saved\n\n'
            '✨ **${totalStardust.toInt()} Stardust** earned';

    return {
      'summary': {
        'totalCo2Kg': _roundDouble(totalCo2),
        'totalEnergyKwh': _roundDouble(totalEnergy),
        'totalWaterL': _roundDouble(totalWater),
        'totalStardust': totalStardust,
        'totalActions': total,
      },
      'narrativeReport': narrative,
      'weekly': weekly,
      'monthly': monthly,
      'yearly': yearly,
      'chartSeries': {
        'weekly': toChartSeries(weekly),
        'monthly': toChartSeries(monthly),
        'yearly': toChartSeries(yearly),
      },
      'actionBreakdown': actionBreakdown,
      'blindSpots': const [],
    };
  }

  void _addToBucket(Map<String, Map<String, dynamic>> buckets, String key,
      String label, double co2, double energy, double water) {
    buckets.putIfAbsent(
        key,
        () => {
              'label': label,
              'co2Kg': 0.0,
              'energyKwh': 0.0,
              'waterL': 0.0,
              'actions': 0,
            });
    buckets[key]!['co2Kg'] = (buckets[key]!['co2Kg'] as double) + co2;
    buckets[key]!['energyKwh'] =
        (buckets[key]!['energyKwh'] as double) + energy;
    buckets[key]!['waterL'] = (buckets[key]!['waterL'] as double) + water;
    buckets[key]!['actions'] = (buckets[key]!['actions'] as int) + 1;
  }

  double _round(dynamic v) =>
      double.parse(((v as num?) ?? 0).toStringAsFixed(2));
  double _roundDouble(double v) => double.parse(v.toStringAsFixed(2));
  String _twoDigit(int n) => n.toString().padLeft(2, '0');
  String _mmmDd(DateTime d) => '${_monthAbbr(d.month)} ${d.day}';
  String _monthAbbr(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m];
  String _monthName(int m) => const [
        '',
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m];
}

/// Thrown by [ApiService.submitAction] when the AI explicitly rejects
/// the submitted image/description as not a valid eco-action.
class SubmissionRejectedException implements Exception {
  final String reason;
  const SubmissionRejectedException(this.reason);

  @override
  String toString() => reason;
}
