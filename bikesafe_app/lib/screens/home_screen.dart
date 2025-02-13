//bikesafe_app/lib/screens/home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BikeSafe Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),automaticallyImplyLeading: false,
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
        elevation: 4.0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            tooltip: "Help & Instructions",
            onPressed: () => Navigator.pushNamed(context, '/help'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Section
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 150,
                        width: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Welcome Text
                  const Text(
                    'Welcome to BikeSafe',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Subtitle
                  const Text(
                    'Secure your bike, monitor battery, and more!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Button
                  _buildButton(context, "Login", Colors.blue, Icons.login, '/login'),

                  const SizedBox(height: 15),

                  // Register Button
                  _buildButton(context, "Register", Colors.blue, Icons.person_add, '/register'),

                  const SizedBox(height: 15),

                  // Google Login Button
                  _buildButton(context, "Login with Google", Colors.red, Icons.g_mobiledata, '/google-login'),

                  const SizedBox(height: 20),

                  // Help & Instructions Button
                  _buildButton(context, "How to Use", Colors.grey, Icons.help_outline, '/help'),

                  const SizedBox(height: 40),

                  // Footer Text
                  const Text(
                    "Your bike's safety, reimagined!",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Button Widget
  Widget _buildButton(BuildContext context, String title, Color color, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route),
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
    );
  }
}