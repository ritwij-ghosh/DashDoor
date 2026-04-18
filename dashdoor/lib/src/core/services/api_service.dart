import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class ApiService {
  static const _base = AppConfig.apiBaseUrl;

  static String? get _token =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── Chat ────────────────────────────────────────────────────────────

  static Future<String> sendChatMessage(String message) async {
    final res = await http.post(
      Uri.parse('$_base/api/v1/chat/message'),
      headers: _headers,
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode != 200) {
      throw Exception('Chat request failed: ${res.statusCode}');
    }
    return (jsonDecode(res.body) as Map<String, dynamic>)['response'] as String;
  }

  static Future<List<Map<String, dynamic>>> getChatHistory({int limit = 50}) async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/chat/history?limit=$limit'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  // ── Profile ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/profile'),
      headers: _headers,
    );
    if (res.statusCode != 200) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await http.put(
      Uri.parse('$_base/api/v1/profile'),
      headers: _headers,
      body: jsonEncode(data),
    );
  }

  // ── Recommendations ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getRecommendations({int limit = 5}) async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/recommendations?limit=$limit'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> generateRecommendation({
    String? location,
    String? travelContext,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/v1/recommendations/generate'),
      headers: _headers,
      body: jsonEncode({
        'location': location,
        'travel_context': travelContext,
      }),
    );
    if (res.statusCode != 201) {
      throw Exception('Failed to generate recommendations');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Meal scores ──────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMealScores({int limit = 20}) async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/meals/scores?limit=$limit'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> scoreMeal({
    required String mealName,
    required int score,
    String? notes,
    String? recommendationId,
  }) async {
    await http.post(
      Uri.parse('$_base/api/v1/meals/scores'),
      headers: _headers,
      body: jsonEncode({
        'meal_name': mealName,
        'score': score,
        if (notes != null) 'notes': notes,
        if (recommendationId != null) 'recommendation_id': recommendationId,
      }),
    );
  }

  // ── Calendar ─────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> connectCalendar() async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/calendar/connect'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to get OAuth URL');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<bool> getCalendarStatus() async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/calendar/status'),
      headers: _headers,
    );
    if (res.statusCode != 200) return false;
    return (jsonDecode(res.body) as Map<String, dynamic>)['connected'] as bool? ?? false;
  }

  // ── Location ─────────────────────────────────────────────────────────

  static Future<void> setLocation({
    required String city,
    String? address,
    String? travelNote,
  }) async {
    await http.post(
      Uri.parse('$_base/api/v1/location'),
      headers: _headers,
      body: jsonEncode({
        'city': city,
        if (address != null) 'address': address,
        if (travelNote != null) 'travel_note': travelNote,
      }),
    );
  }

  static Future<Map<String, dynamic>?> getLocation() async {
    final res = await http.get(
      Uri.parse('$_base/api/v1/location'),
      headers: _headers,
    );
    if (res.statusCode != 200) return null;
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
