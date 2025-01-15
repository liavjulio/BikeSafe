import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      try {
        final response = await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );
        print('Login successful: $response');
        Navigator.pushNamed(context, '/'); // Navigate to Home
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  

void _forgotPassword() async {
  final email = _emailController.text.trim();

  // Validate email input
  if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
    setState(() {
      _errorMessage = 'Please enter a valid email address to reset your password.';
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    await ApiService.forgotPassword(email); // Await the API call
    setState(() {
      _errorMessage = 'Password reset email sent successfully.';
    });

    // Optionally, you can navigate to another screen after the password reset email is sent
    Navigator.pushNamed(context, '/confirmation',arguments: email);  // or any other screen you want to redirect the user to
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to send password reset email: $e';
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
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
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
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