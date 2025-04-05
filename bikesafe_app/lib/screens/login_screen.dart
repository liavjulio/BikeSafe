//bikesafe_app/lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    print('Login initiated'); // Debugging print
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      print('Form validated. Sending login request...');
      try {
        final response = await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );
        print('Login response: $response'); // Debugging print for response

        // Safely extract userId and token from the response
        final String? userId = response['userId'] as String?;
        final String? token = response['token'] as String?;

        // Check if userId or token is null
        if (userId == null || token == null) {
          print('Invalid response: Missing userId or token'); // Debugging print
          throw Exception(
              'Invalid response from server: Missing userId or token');
        }

        print(
            'Login successful. Navigating to Main Screen with userId: $userId');
        Navigator.pushNamed(
          context,
          '/main',
          arguments: {'userId': userId, 'token': token ,'isAdmin': response['isAdmin'] ?? false,},
        );
      } catch (e) {
        // Check if the error is about not being verified
        if (e.toString().contains('Account not verified')) {
          _showVerificationDialog();
        } else {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
        print('Login request completed'); // Debugging print
      }
    }
  }

  void _forgotPassword() async {
    final email = _emailController.text.trim();

    print('Forgot Password initiated for email: $email'); // Debugging print

    // Validate email input
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      print('Invalid email address entered'); // Debugging print
      setState(() {
        _errorMessage =
            'Please enter a valid email address to reset your password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Sending forgot password request...'); // Debugging print
      await ApiService.forgotPassword(email); // Await the API call
      print('Forgot Password email sent successfully'); // Debugging print
      setState(() {
        _errorMessage = 'Password reset email sent successfully.';
      });

      // Optionally, navigate to confirmation screen
      Navigator.pushNamed(context, '/confirmation', arguments: email);
    } catch (e) {
      print('Failed to send forgot password email: $e'); // Debugging print
      setState(() {
        _errorMessage = 'Failed to send password reset email: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('Forgot Password request completed'); // Debugging print
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to interact with the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Email Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Your account is not verified. Please enter the verification code sent to your email:'),
              TextField(
                controller: _verificationCodeController,
                decoration: InputDecoration(labelText: 'Verification Code'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Optionally allow cancel
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                print("Verifying code: ${_verificationCodeController.text}");
                try {
                  final verifyResponse = await ApiService.verifyCode(
                    _verificationCodeController.text,
                  );
                  print("Verification response: $verifyResponse");
                  if (verifyResponse['status'] == 'success') {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Verification successful! Please login again.')),
                    );
                  } else {
                    setState(() {
                      _errorMessage = 'Verification failed. Please try again.';
                    });
                  }
                } catch (error) {
                  setState(() {
                    _errorMessage = error.toString();
                  });
                  print("Error during verification: $error");
                }
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    print('Email field is empty'); // Debugging print
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    print('Invalid email entered'); // Debugging print
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                ),
                TextButton(
                  onPressed: _forgotPassword,
                  child: Text('Forgot Password?'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
