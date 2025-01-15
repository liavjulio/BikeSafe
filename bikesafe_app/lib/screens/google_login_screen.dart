import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleLoginScreen extends StatefulWidget {
  @override
  _GoogleLoginScreenState createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  TextEditingController _passwordController = TextEditingController();

  // Google Sign-In Function
  Future<void> _loginWithGoogle() async {
    try {
      print("Attempting to sign in with Google...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        print("Google sign-in successful: ${googleUser.displayName}");

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final String idToken = googleAuth.idToken!;
        final String accessToken = googleAuth.accessToken!;

        // Now send the ID token to the backend for authentication
        final response = await http.post(
          Uri.parse('http://localhost:5001/auth/google/callback'),
          headers: <String, String>{
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'idToken': idToken,
            'accessToken': accessToken,
          }),
        );

        if (response.statusCode == 200) {
          print("Backend authentication successful.");
          Navigator.pushNamed(context, '/home');
        } else {
          final responseBody = jsonDecode(response.body);
          if (responseBody['message'] == 'Please set a password to continue.') {
            // Prompt the user to set a password
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
                        final password = _passwordController.text;
                        print(password);
                        // Send password to the backend
                        final setPasswordResponse = await http.post(
                          Uri.parse('http://localhost:5001/auth/google/callback'),
                          headers: <String, String>{
                            'Content-Type': 'application/json',
                          },
                          body: json.encode({
                            'idToken': idToken,
                            'password': password,
                          }),
                        );

                        if (setPasswordResponse.statusCode == 200) {
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
        }
      } else {
        print("Google sign-in failed: User canceled the sign-in.");
      }
    } catch (error) {
      print("Google sign-in failed: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    // Dispose of the password controller
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login with Google'),
        backgroundColor: Colors.blue, // AppBar color
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
                  backgroundColor: Colors.blue, // Set button color
                  minimumSize: Size(double.infinity, 50), // Full width button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Back to login
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to the previous screen
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