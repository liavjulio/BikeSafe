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
}