import 'dart:io'; // For detecting platform
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../utils/constants.dart'; // Adjust path as needed

final String apiBaseUrl = Constants.envBaseUrl;

class GoogleLoginScreen extends StatefulWidget {
  @override
  _GoogleLoginScreenState createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final String? googleWebClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: googleWebClientId,
  );

  TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint("DEBUG: GOOGLE_WEB_CLIENT_ID = $googleWebClientId");
  }

  // Google Sign-In Function with enhanced debugging
  Future<void> _loginWithGoogle() async {
    try {
      debugPrint("DEBUG: Attempting to sign in with Google...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint("DEBUG: googleUser: $googleUser");

      if (googleUser != null) {
        debugPrint("DEBUG: Google sign-in successful: ${googleUser.displayName}, Email: ${googleUser.email}");

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        debugPrint("DEBUG: Received googleAuth: $googleAuth");

        final String? idToken = googleAuth.idToken;
        final String? accessToken = googleAuth.accessToken;

        if (idToken == null || accessToken == null) {
          debugPrint("ERROR: Missing ID token or access token from Google.");
          throw Exception("Google authentication tokens are null.");
        }

        debugPrint("DEBUG: Google Authentication Tokens - ID Token: $idToken, Access Token: $accessToken");

        // Send the ID token to the backend for authentication
        final response = await http.post(
          Uri.parse('$apiBaseUrl/auth/google/callback'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'idToken': idToken,
            'accessToken': accessToken,
          }),
        );

        debugPrint("DEBUG: Response from backend: ${response.statusCode}, Body: ${response.body}");

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          debugPrint("DEBUG: Parsed backend response: $responseBody");

          final String? token = responseBody['token'];
          final String? userId = responseBody['userId'];

          if (token == null || userId == null) {
            debugPrint("ERROR: Missing token or userId in backend response.");
            throw Exception("Invalid response from backend: Missing token or userId.");
          }

          Navigator.pushNamed(
            context,
            '/main',
            arguments: {'userId': userId, 'token': token},
          );
        } else {
          final responseBody = jsonDecode(response.body);
          debugPrint("ERROR: Backend error: ${responseBody['message']}");
          if (responseBody['message'] == 'Please set a password to continue.') {
            debugPrint("DEBUG: Prompting user to set a password...");
            _promptForPassword(idToken);
          } else {
            debugPrint("ERROR: Unhandled backend error: ${responseBody['message']}");
          }
        }
      } else {
        debugPrint("DEBUG: Google sign-in canceled by the user.");
      }
    } on PlatformException catch (e, stackTrace) {
      debugPrint("ERROR: Google sign-in failed with PlatformException:");
      debugPrint("  Code: ${e.code}");
      debugPrint("  Message: ${e.message}");
      debugPrint("  Details: ${e.details}");
      debugPrint("  Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: ${e.message}")),
      );
    } catch (error, stackTrace) {
      debugPrint("ERROR: Unexpected error during Google sign-in: $error");
      debugPrint("Stack trace: $stackTrace");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed. Please try again.")),
      );
    }
  }

  // Function to show password dialog
  void _promptForPassword(String idToken) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set a Password'),
          content: TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(hintText: 'Enter password'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                final password = _passwordController.text.trim();
                debugPrint("DEBUG: User entered password: $password");

                final setPasswordResponse = await http.post(
                  Uri.parse('$apiBaseUrl/auth/google/callback'),
                  headers: <String, String>{
                    'Content-Type': 'application/json',
                  },
                  body: json.encode({
                    'idToken': idToken,
                    'password': password,
                  }),
                );

                debugPrint("DEBUG: Response after setting password: ${setPasswordResponse.statusCode}, Body: ${setPasswordResponse.body}");

                if (setPasswordResponse.statusCode == 200) {
                  debugPrint("DEBUG: Password set successfully. Navigating to home...");
                  Navigator.pushNamed(context, '/home');
                } else {
                  debugPrint("ERROR: Failed to set password.");
                }
              },
              child: Text('Set Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login with Google'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/google_logo.png', // Ensure this asset exists
                width: 120,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _loginWithGoogle,
                child: Text(
                  'Login with Google',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}