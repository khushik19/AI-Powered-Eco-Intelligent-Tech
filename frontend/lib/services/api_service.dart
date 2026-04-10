import 'dart:convert';
import 'package:http/http.dart' as http;

/// Central service for all backend API calls.
/// Backend runs at http://localhost:8000
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String _baseUrl = 'http://localhost:8000';

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  void _assertOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('[${res.statusCode}] ${res.body}');
    }
  }

  // ─── Chatbot ───────────────────────────────────────────────────────────────

  /// POST /chatbot/message
  /// Sends a user message + conversation history and returns the AI reply.
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

  // ─── Leaderboard ───────────────────────────────────────────────────────────

  /// GET /leaderboard/individuals
  /// Returns a list of top students. Optionally filter by [collegeId].
  Future<List<Map<String, dynamic>>> getIndividualLeaderboard({
    String? collegeId,
    String? city,
    String? state,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (collegeId != null) params['college_id'] = collegeId;
    if (city != null) params['city'] = city;
    if (state != null) params['state'] = state;

    final res = await http.get(
      Uri.parse('$_baseUrl/leaderboard/individuals')
          .replace(queryParameters: params),
      headers: _headers,
    );
    _assertOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// GET /leaderboard/colleges
  /// Returns a list of top colleges sorted by accreditation score.
  Future<List<Map<String, dynamic>>> getCollegeLeaderboard({
    String? city,
    String? state,
    int limit = 20,
  }) async {
    final params = <String, String>{'limit': '$limit'};
    if (city != null) params['city'] = city;
    if (state != null) params['state'] = state;

    final res = await http.get(
      Uri.parse('$_baseUrl/leaderboard/colleges')
          .replace(queryParameters: params),
      headers: _headers,
    );
    _assertOk(res);
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ─── Submissions ───────────────────────────────────────────────────────────

  /// POST /submissions/submit
  /// Submits an eco-action with an image (base64), description and user info.
  /// Returns the AI-classified result: stardust, impact summary, etc.
  Future<Map<String, dynamic>> submitAction({
    required String userId,
    required String collegeId,
    required String role,
    required String imageBase64,
    required String description,
    bool isPredefined = false,
    String? predefinedActionId,
  }) async {
    final body = <String, dynamic>{
      'userId': userId,
      'collegeId': collegeId,
      'role': role,
      'imageBase64': imageBase64,
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

  // ─── Dashboard ─────────────────────────────────────────────────────────────

  /// GET /dashboard/student/{userId}
  /// Returns user profile and all their submitted records.
  Future<Map<String, dynamic>> getStudentDashboard(String userId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/dashboard/student/$userId'),
      headers: _headers,
    );
    _assertOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// GET /dashboard/college/{collegeId}
  /// Returns college profile, monthly CO2 data, action breakdown, blind spots.
  Future<Map<String, dynamic>> getCollegeDashboard(String collegeId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/dashboard/college/$collegeId'),
      headers: _headers,
    );
    _assertOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
