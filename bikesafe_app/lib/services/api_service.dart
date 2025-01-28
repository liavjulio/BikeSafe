import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://localhost:5001/api';

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
    Uri.parse('http://localhost:5001/api/auth/update-alerts'),
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
    Uri.parse('$_baseUrl/auth/alert-preferences/$userId'),
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
    Uri.parse('http://localhost:5001/api/auth/feedback'),
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
        Uri.parse('http://localhost:5001/api/auth/verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Failed to verify code');
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
}