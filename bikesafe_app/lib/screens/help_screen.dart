//bikesafe_app/lib/screens/help_screen.dart
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Help & Guidance"),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          _buildHelpSection(
            title: "How to Register",
            description:
                "1. Click 'Register' on the home screen.\n"
                "2. Enter your email and create a password.\n"
                "3. You can also use 'Login with Google' for a quick sign-up.\n"
                "4. After registering, log in with your credentials.",
            imagePath: "assets/register.png",
          ),
          _buildHelpSection(
            title: "How to Log In",
            description:
                "1. Click 'Login' on the home screen.\n"
                "2. Enter your registered email and password.\n"
                "3. If you used Google sign-in, click 'Login with Google'.",
            imagePath: "assets/login.png",
          ),
          _buildHelpSection(
            title: "Forgot Your Password?",
            description:
                "1. Click 'Forgot Password' on the login screen.\n"
                "2. Enter your email to receive a reset link.\n"
                "3. Follow the link to create a new password.",
            imagePath: "assets/reset_password.png",
          ),
          _buildHelpSection(
            title: "Monitor Your Battery",
            description:
                "Track your bike's battery status and receive alerts.",
            imagePath: "assets/battery_status.png",
          ),
          _buildHelpSection(
            title: "Manage Alerts",
            description:
                "Customize your alert settings to receive notifications.",
            imagePath: "assets/alerts.png",
          ),
          _buildHelpSection(
            title: "Submit Feedback",
            description:
                "Help us improve by providing your feedback directly in the app.",
            imagePath: "assets/feedback.png",
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 150, errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported, size: 80, color: Colors.grey);
            }), // Placeholder if image is missing
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(description, textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}