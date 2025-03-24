//bikesafe_app/lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart'; // Adjust path as needed

final String _baseUrl = Constants.envBaseUrl;

class ApiService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body); // Properly return the response
  } else {
    throw Exception('Failed to login: ${response.body}');
  }
}
static Future<bool> updateAlertPreferences(String userId, String token, List<String> preferences) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/alerts/preferences'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'userId': userId,
      'alerts': preferences,
    }),
  );

  if (response.statusCode == 200) {
    print('Preferences updated successfully: ${response.body}');
    return true;
  } else {
    print('Failed to update preferences: ${response.body}');
    return false;
  }
}
static Future<Map<String, bool>> fetchAlertPreferences(String userId, String token) async {
  print('Sending request to fetch preferences for $userId');

  final response = await http.get(
    Uri.parse('$_baseUrl/alerts/preferences?userId=$userId'), // ✅ שינוי מ- `/alerts/preferences/$userId`
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('Response Status Code: ${response.statusCode}');
  print('Response Body: ${response.body}');

  if (response.statusCode == 200) {
    final Map<String, dynamic> preferences = jsonDecode(response.body);
    print('Decoded preferences: $preferences');

    return preferences.map((key, value) => MapEntry(key, value as bool));
  } else {
    print('Failed to fetch alert preferences: ${response.body}');
    throw Exception('Failed to fetch alert preferences');
  }
}
static Future<bool> submitFeedback(String userId, String feedback, String token) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/feedback'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Pass the token here
    },
    body: jsonEncode({'userId': userId, 'feedback': feedback}),
  );

  if (response.statusCode == 201) {
    return true;
  } else {
    print('Feedback submission failed: ${response.body}');
    throw Exception('Failed to submit feedback');
  }
}
static Future<Map<String, dynamic>> verifyCode(String code) async {
  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code.trim()}),
    );
    print("Verify code response status: ${response.statusCode}");
    print("Verify code response body: ${response.body}");
    if (response.statusCode != 200) {
      throw Exception("Failed to verify code: ${response.body}");
    }
    return jsonDecode(response.body);
  } catch (e) {
    throw Exception('Failed to verify code: ${e.toString()}');
  }
}
  static Future<Map<String, dynamic>> register(String email, String phone, String password) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'phone': phone, 'password': password}),
  );

  if (response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to register: ${response.body}');
  }
}
  static Future<void> forgotPassword(String email) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/forgot-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to send password reset email: ${response.body}');
  }
}
static Future<void> verifyCodeAndResetPassword(String email,String code, String newPassword) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/auth/verify-code-and-reset-password'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email' : email ,'code': code, 'newPassword': newPassword}),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to reset password: ${response.body}');
  }
}
static Future<List<Map<String, dynamic>>> fetchSensorHistory(String userId, String sensorType, String token) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/sensor/history?userId=$userId&type=$sensorType'), // 🔄 שים לב לשינוי מ-sensorId ל-type
    headers: {'Authorization': 'Bearer $token'},
  );

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load sensor history');
  }
}
static Future<void> deleteSensorHistoryById(String historyId, String token) async {
  final response = await http.delete(
    Uri.parse('$_baseUrl/sensor/history/$historyId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  print('Delete response status: ${response.statusCode}');
  print('Delete response body: ${response.body}');
  if (response.statusCode != 200) {
    throw Exception('Failed to delete sensor history entry');
  }
}

static Future<void> deleteAllSensorHistoryForUser(String userId, String token) async {
  final response = await http.delete(
    Uri.parse('$_baseUrl/sensor/history/user/$userId'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
  print('Delete response status: ${response.statusCode}');
  print('Delete response body: ${response.body}');
  if (response.statusCode != 200) {
    throw Exception('Failed to delete all sensor history');
  }
}
}
