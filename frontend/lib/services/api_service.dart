import 'dart:convert';
import 'dart:typed_data';
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
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
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
    Query query = _db
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
        .map((d) => d.data() as Map<String, dynamic>)
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

  /// Uploads image bytes to Firebase Storage from the client and returns the download URL.
  Future<String> _uploadImageToStorage(Uint8List bytes, String userId) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('submissions')
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await task.ref.getDownloadURL();
  }

  /// Submits an eco-action:
  /// 1) Uploads image directly to Firebase Storage (fast, no server JWT issues)
  /// 2) Sends base64 + storage URL to Render backend for AI classification
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
    // Step 1 — Upload image to Firebase Storage directly from Flutter
    String imageUrl = '';
    try {
      imageUrl = await _uploadImageToStorage(imageBytes, userId);
    } catch (e) {
      debugPrint('Image upload to Storage failed (non-fatal): $e');
      // Continue without image URL — submission still records AI data + stardust
    }

    // Step 2 — Send to backend for AI classification
    final body = <String, dynamic>{
      'userId': userId,
      'collegeId': collegeId,
      'role': role,
      'imageBase64': imageBase64,
      'imageUrl': imageUrl,
      'description': description,
      'isPredefined': isPredefined,
      if (predefinedActionId != null) 'predefinedActionId': predefinedActionId,
    };

    final res = await http.post(
      Uri.parse('$_baseUrl/submissions/submit'),
      headers: _headers,
      body: jsonEncode(body),
    );
    _assertOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
