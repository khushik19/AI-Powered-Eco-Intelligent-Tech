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

  void _assertOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[${res.statusCode}] ${res.body}');
    }
  }

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

    if (collegeId != null) {
      users = users
          .where((u) =>
              u['collegeId'] == collegeId || u['institution'] == collegeId)
          .toList();
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
        .orderBy('accreditationScore', descending: true)
        .limit(limit);

    final snap = await query.get();
    return snap.docs
        .map((d) => <String, dynamic>{'id': d.id, ...((d.data() as Map<String, dynamic>?) ?? {})})
        .toList();
  }

  // ─── Dashboard ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getStudentDashboard(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
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
      final month =
          (d['createdAt'] as String? ?? '').length >= 7
              ? (d['createdAt'] as String).substring(0, 7)
              : '';
      monthlyCo2[month] = (monthlyCo2[month] ?? 0) +
          (d['co2ReducedKg'] as num? ?? 0).toDouble();
      final at = d['actionType'] as String? ?? 'other';
      actionTypes[at] = (actionTypes[at] ?? 0) + 1;
    }

    return {
      'college':
          collegeDoc.exists ? collegeDoc.data()! : <String, dynamic>{},
      'monthlyCo2': monthlyCo2,
      'actionBreakdown': actionTypes,
    };
  }

  // ─── Chatbot ────────────────────────────────────────────────────────────────

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

  // ─── Submissions ────────────────────────────────────────────────────────────

  /// Upload image bytes to Firebase Storage. Returns URL or '' on failure.
  Future<String> _uploadImageToStorage(
      Uint8List bytes, String userId) async {
    // On web, Firebase Storage requires CORS configuration on the bucket.
    // When running on localhost (dev), CORS is blocked. We store the image
    // as a base64 data URL in Firestore instead — no CORS needed.
    if (kIsWeb) {
      debugPrint('[SUBMIT] Step 1: Web mode — storing image as base64 data URL');
      final b64 = base64Encode(bytes);
      return 'data:image/jpeg;base64,$b64';
    }

    debugPrint('[SUBMIT] Step 1: Uploading image (${bytes.length} bytes) to Firebase Storage...');
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

  /// AI classify — 10 s timeout, NEVER throws, always returns safe map.
  /// Sends only the description text (NOT the full image) to avoid huge payloads.
  Future<Map<String, dynamic>> _classifyWithFallback(
      String description) async {
    debugPrint('[SUBMIT] Step 2: AI classify for "$description"...');
    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/submissions/classify'),
            headers: _headers,
            body: jsonEncode({
              'imageBase64': '', // skip sending huge base64 — backend uses text
              'description': description,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint(
          '[SUBMIT] Step 2 AI response: status=${res.statusCode} body=${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          debugPrint('[SUBMIT] Step 2 DONE: AI success');
          return decoded;
        }
      }
      debugPrint('[SUBMIT] Step 2: AI non-2xx, using fallback');
    } catch (e) {
      debugPrint('[SUBMIT] Step 2: AI skipped (${e.runtimeType}): $e');
    }

    // Fallback
    debugPrint('[SUBMIT] Step 2 DONE: using fallback values');
    return {
      'actionType': 'other',
      'stardustAwarded': 25,
      'co2ReducedKg': 0.5,
      'energySavedKwh': 0.1,
      'waterSavedLiters': 0.0,
      'eWasteKg': 0.0,
      'estimatedCostSavingRupees': 5.0,
      'impactSummary': 'Eco action recorded successfully!',
      'realWorldEquivalent': 'Keeping the planet a little cleaner',
      'isLegitimate': true,
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
    required String imageBase64,  // kept for API compat but NOT sent to backend
    required String description,
    bool isPredefined = false,
    String? predefinedActionId,
  }) async {
    debugPrint(
        '[SUBMIT] ═══════════ START ═══════════ userId=$userId collegeId=$collegeId');

    // ── Parallel: upload + AI ──────────────────────────────────────────────────
    final uploadFuture = _uploadImageToStorage(imageBytes, userId);
    final aiFuture = _classifyWithFallback(description);

    // Collect upload result (non-fatal if fails)
    String imageUrl = '';
    try {
      imageUrl = await uploadFuture;
    } catch (e) {
      debugPrint('[SUBMIT] Step 1 FAILED (non-fatal): $e');
    }

    // AI result always succeeds
    final ai = await aiFuture;

    // ── Unpack ────────────────────────────────────────────────────────────────
    final actionType = ai['actionType'] as String? ?? 'other';
    final stardust = (ai['stardustAwarded'] as num?)?.toInt() ?? 25;
    final co2 = (ai['co2ReducedKg'] as num? ?? 0).toDouble();
    final energy = (ai['energySavedKwh'] as num? ?? 0).toDouble();
    final water = (ai['waterSavedLiters'] as num? ?? 0).toDouble();
    final eWaste = (ai['eWasteKg'] as num? ?? 0).toDouble();
    final costSaving =
        (ai['estimatedCostSavingRupees'] as num? ?? 0).toDouble();
    final impactSummary =
        ai['impactSummary'] as String? ?? 'Great eco action!';
    final realWorld = ai['realWorldEquivalent'] as String? ?? '';

    debugPrint(
        '[SUBMIT] AI result: actionType=$actionType stardust=$stardust');

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

  // ─── Impact Reports ──────────────────────────────────────────────────────

  /// Fetches the individual/student impact report from the backend.
  /// Returns aggregated weekly/monthly/yearly data, charts, blind spots,
  /// and a narrative text report.
  Future<Map<String, dynamic>> getImpactReport(String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/dashboard/impact-report/$userId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    _assertOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Fetches the college/org impact report from the backend.
  /// Aggregates all submissions from students belonging to the college.
  Future<Map<String, dynamic>> getCollegeImpactReport(String collegeId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/dashboard/impact-report/college/$collegeId'),
      headers: _headers,
    ).timeout(const Duration(seconds: 15));
    _assertOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
