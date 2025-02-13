//bikesafe_app/lib/screens/google_login_screen.dart
import 'dart:io'; // For detecting platform
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class GoogleLoginScreen extends StatefulWidget {
  @override
  _GoogleLoginScreenState createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],);
  
  TextEditingController _passwordController = TextEditingController();

  // Function to determine the correct API base URL for different platforms
  String getApiBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5001'; // Android Emulator
    } else if (Platform.isIOS) {
      return 'http://localhost:5001'; // iOS Simulator
    } else {
      return 'http://192.168.X.X:5001'; // Replace X.X with your local IP for physical devices
    }
  }

  // Google Sign-In Function
  Future<void> _loginWithGoogle() async {
    try {
      print("Attempting to sign in with Google...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        print("Google sign-in successful: ${googleUser.displayName}, Email: ${googleUser.email}");

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final String? idToken = googleAuth.idToken;
        final String? accessToken = googleAuth.accessToken;

        if (idToken == null || accessToken == null) {
          print("Error: Missing ID token or access token from Google.");
          throw Exception("Google authentication tokens are null.");
        }

        print("Google Authentication Tokens - ID Token: $idToken, Access Token: $accessToken");

        // Get the correct API base URL
        String apiBaseUrl = getApiBaseUrl();
        print("Using API base URL: $apiBaseUrl");

        // Now send the ID token to the backend for authentication
        final response = await http.post(
          Uri.parse('$apiBaseUrl/auth/google/callback'), // Dynamically selects API URL
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'idToken': idToken,
            'accessToken': accessToken,
          }),
        );

        print("Response from backend: ${response.statusCode}, Body: ${response.body}");

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);

          // Extract token and userId from the response
          final String? token = responseBody['token'];
          final String? userId = responseBody['userId'];

          if (token == null || userId == null) {
            print("Error: Missing token or userId in backend response.");
            throw Exception("Invalid response from backend: Missing token or userId.");
          }

          // Navigate to main screen with arguments
          Navigator.pushNamed(
            context,
            '/main',
            arguments: {'userId': userId, 'token': token},
          );
        } else {
          final responseBody = jsonDecode(response.body);
          print("Backend error: ${responseBody['message']}");

          if (responseBody['message'] == 'Please set a password to continue.') {
            print("Prompting user to set a password...");
            _promptForPassword(idToken);
          } else {
            print("Unhandled backend error: ${responseBody['message']}");
          }
        }
      } else {
        print("Google sign-in canceled by the user.");
      }
    } catch (error) {
      print("Google sign-in failed: $error");
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
                print("User entered password: $password");

                // Send password to the backend
                String apiBaseUrl = getApiBaseUrl();
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

                print("Response from backend after setting password: ${setPasswordResponse.statusCode}, Body: ${setPasswordResponse.body}");

                if (setPasswordResponse.statusCode == 200) {
                  print("Password set successfully. Navigating to home...");
                  Navigator.pushNamed(context, '/home');
                } else {
                  print("Failed to set password.");
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
              // Google logo or icon
              Image.asset(
                'assets/google_logo.png', // Add your Google logo here
                width: 120,
              ),
              SizedBox(height: 30),

              // Login button
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

              // Back to login
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