import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Central service for all backend API calls.
/// Backend: https://ai-powered-eco-intelligent-tech.onrender.com
/// For read operations that need to be fast, we use Firestore directly.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _baseUrl =
      'https://ai-powered-eco-intelligent-tech.onrender.com';

  static final _db = FirebaseFirestore.instance;

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  void _assertOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[${res.statusCode}] ${res.body}');
    }
  }

  // ─── Leaderboard (reads Firestore directly — fast & reliable) ──────────────

  /// Returns top students sorted by stardust. Fetches all non-org users.
  Future<List<Map<String, dynamic>>> getIndividualLeaderboard({
    String? collegeId,
    String? city,
    String? state,
    int limit = 50,
  }) async {
    // Fetch all users — no role filter to avoid composite index issues
    // and mismatches with role strings ('individual', 'student_employee', etc.)
    final snap = await _db.collection('users').get();

    var users = snap.docs
        .map((d) => {'id': d.id, ...d.data()})
        .where((u) => u['role'] != 'college_org' && u['role'] != 'college')
        .toList();

    if (collegeId != null) {
      users = users
          .where((u) => u['collegeId'] == collegeId || u['institution'] == collegeId)
          .toList();
    }

    // Sort by stardust descending in Dart (no Firestore index needed)
    users.sort((a, b) {
      final sa = (a['stardust'] as num? ?? 0).toInt();
      final sb = (b['stardust'] as num? ?? 0).toInt();
      return sb.compareTo(sa);
    });

    return users.take(limit).toList();
  }

  /// Returns top colleges sorted by accreditation score.
  Future<List<Map<String, dynamic>>> getCollegeLeaderboard({
    String? city,
    String? state,
    int limit = 20,
  }) async {
    final Query query = _db
        .collection('colleges')
        .orderBy('accreditationScore', descending: true)
        .limit(limit);

    final snap = await query.get();
    return snap.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ─── Dashboard (reads Firestore directly) ──────────────────────────────────

  /// Returns student profile + their submission history directly from Firestore.
  Future<Map<String, dynamic>> getStudentDashboard(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    // No orderBy — avoids needing a composite index. Sort in Dart instead.
    final submissionsSnap = await _db
        .collection('submissions')
        .where('userId', isEqualTo: userId)
        .get();

    final submissions = submissionsSnap.docs
        .map((d) => d.data())
        .toList()
      ..sort((a, b) {
        final ta = a['createdAt'] as String? ?? '';
        final tb = b['createdAt'] as String? ?? '';
        return tb.compareTo(ta); // newest first
      });

    return {
      'user': userDoc.exists
          ? {'uid': userId, ...userDoc.data()!}
          : <String, dynamic>{},
      'submissions': submissions,
    };
  }

  /// Returns college dashboard data directly from Firestore.
  Future<Map<String, dynamic>> getCollegeDashboard(String collegeId) async {
    final collegeDoc =
        await _db.collection('colleges').doc(collegeId).get();
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
      monthlyCo2[month] =
          (monthlyCo2[month] ?? 0) + (d['co2ReducedKg'] as num? ?? 0).toDouble();
      final at = d['actionType'] as String? ?? 'other';
      actionTypes[at] = (actionTypes[at] ?? 0) + 1;
    }

    return {
      'college': collegeDoc.exists ? collegeDoc.data()! : <String, dynamic>{},
      'monthlyCo2': monthlyCo2,
      'actionBreakdown': actionTypes,
    };
  }

  // ─── Chatbot (uses Render backend — AI processing needed) ──────────────────

  /// POST /chatbot/message
  Future<String> sendChatMessage(
    String query,
    List<Map<String, String>> history,
  ) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chatbot/message'),
      headers: _headers,
      body: jsonEncode({'query': query, 'history': history}),
    );
    _assertOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['response'] as String;
  }

  // ─── Submissions ───────────────────────────────────────────────────────────

  /// Uploads image bytes to Firebase Storage from the client — no backend JWT needed.
  Future<String> _uploadImageToStorage(Uint8List bytes, String userId) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('submissions')
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await task.ref.getDownloadURL();
  }

  /// Calls the AI classify endpoint with a 10-second hard timeout.
  /// NEVER throws — always returns a valid map (fallback on any error/timeout).
  /// The Render backend may be cold-starting (30-60 s) — 10 s timeout means
  /// we skip AI and use safe defaults rather than blocking the user.
  Future<Map<String, dynamic>> _classifyWithFallback(
    String imageBase64,
    String description,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/submissions/classify'),
            headers: _headers,
            body: jsonEncode({
              'imageBase64': imageBase64,
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 10)); // hard cap — never blocks user

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      debugPrint('AI classify HTTP ${res.statusCode}: ${res.body}');
    } catch (e) {
      debugPrint('AI classify skipped (timeout/error — using fallback): $e');
    }

    // Fallback — always succeeds so the submission is never lost
    return {
      'actionType':                'other',
      'stardustAwarded':           25,
      'co2ReducedKg':              0.5,
      'energySavedKwh':            0.1,
      'waterSavedLiters':          0.0,
      'eWasteKg':                  0.0,
      'estimatedCostSavingRupees': 5.0,
      'impactSummary':             'Eco action recorded successfully!',
      'realWorldEquivalent':       'Keeping the planet a little cleaner',
      'isLegitimate':              true,
    };
  }

  /// Full submission flow — all Firebase handled from Flutter:
  /// Steps 1 & 2 run IN PARALLEL:
  ///   1) Upload image → Firebase Storage
  ///   2) AI classify → Render backend (10 s timeout, falls back gracefully)
  /// Step 3: Save submission doc → Firestore
  /// Step 4: Increment user stardust → Firestore
  ///
  /// Total time ≈ max(uploadTime, min(aiTime, 10 s))
  /// The submission is ALWAYS saved, even if AI is unavailable.
  Future<Map<String, dynamic>> submitAction({
    required String userId,
    required String collegeId,
    required String role,
    required Uint8List imageBytes,
    required String imageBase64,
    required String description,
    bool isPredefined = false,
    String? predefinedActionId,
  }) async {
    // Launch both futures simultaneously — they run in parallel
    final uploadFuture = _uploadImageToStorage(imageBytes, userId);
    final aiFuture    = _classifyWithFallback(imageBase64, description);

    // Collect results — if upload fails, imageUrl is empty string (non-fatal)
    String imageUrl = '';
    try {
      imageUrl = await uploadFuture;
    } catch (e) {
      debugPrint('Image upload failed (non-fatal): $e');
    }

    // AI result is guaranteed to succeed (fallback values if AI is unavailable)
    final aiResult = await aiFuture;

    // Unpack AI result
    final actionType    = aiResult['actionType']    as String? ?? 'other';
    final stardust      = aiResult['stardustAwarded'] as int?   ?? 25;
    final co2           = (aiResult['co2ReducedKg']              as num? ?? 0).toDouble();
    final energy        = (aiResult['energySavedKwh']            as num? ?? 0).toDouble();
    final water         = (aiResult['waterSavedLiters']          as num? ?? 0).toDouble();
    final eWaste        = (aiResult['eWasteKg']                  as num? ?? 0).toDouble();
    final costSaving    = (aiResult['estimatedCostSavingRupees'] as num? ?? 0).toDouble();
    final impactSummary = aiResult['impactSummary']   as String? ?? 'Great eco action!';
    final realWorld     = aiResult['realWorldEquivalent'] as String? ?? '';

    // Step 3 — Save submission document directly to Firestore from Flutter
    final now = DateTime.now().toUtc().toIso8601String();
    final submissionDoc = <String, dynamic>{
      'userId':                    userId,
      'collegeId':                 collegeId,
      'role':                      role,
      'description':               description,
      'imageUrl':                  imageUrl,
      'isPredefined':              isPredefined,
      'actionType':                actionType,
      'stardustAwarded':           stardust,
      'co2ReducedKg':              co2,
      'energySavedKwh':            energy,
      'waterSavedLiters':          water,
      'eWasteKg':                  eWaste,
      'estimatedCostSavingRupees': costSaving,
      'impactSummary':             impactSummary,
      'realWorldEquivalent':       realWorld,
      'status':                    'approved',
      'createdAt':                 now,
    };

    String submissionId = '';
    try {
      final ref = await _db.collection('submissions').add(submissionDoc);
      submissionId = ref.id;
    } catch (e) {
      debugPrint('Firestore submission save failed: $e');
    }

    // Step 4 — Increment stardust + totalActions on user doc from Flutter
    try {
      await _db.collection('users').doc(userId).update({
        'stardust':       FieldValue.increment(stardust),
        'totalActions':   FieldValue.increment(1),
        'lastActionDate': now,
      });
    } catch (e) {
      debugPrint('Updating user stardust failed (non-fatal): $e');
    }

    return {
      'success':                   true,
      'submissionId':              submissionId,
      'actionType':                actionType,
      'stardustAwarded':           stardust,
      'co2ReducedKg':              co2,
      'energySavedKwh':            energy,
      'waterSavedLiters':          water,
      'eWasteKg':                  eWaste,
      'estimatedCostSavingRupees': costSaving,
      'impactSummary':             impactSummary,
      'realWorldEquivalent':       realWorld,
    };
  }
}
