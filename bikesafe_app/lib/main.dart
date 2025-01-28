import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/google_login_screen.dart';
import 'screens/resetPassword_screen.dart';
import 'screens/main_screen.dart'; // Add this for the Main Screen
import 'screens/alerts_settings.dart'; // Add this for Alerts Settings
import 'screens/feedback_screen.dart'; // Add this for Feedback Form

void main() {
  runApp(BikeSafeApp());
}

class BikeSafeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeSafe',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/', // Initial route is the HomeScreen
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/google-login': (context) => GoogleLoginScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/alerts-settings': (context) => AlertsSettingsScreen(), // Alerts Settings screen route
        '/feedback': (context) => FeedbackScreen(), // Feedback Form screen route
      },
      onGenerateRoute: (settings) {
        // Dynamic route for Main Screen
        if (settings.name == '/main') {
          final args = settings.arguments as Map<String, dynamic>;
          final userId = args['userId'] as String;
          final token = args['token'] as String;

          return MaterialPageRoute(
            builder: (context) => MainScreen(userId: userId,token:token),
          );
        }

        // Dynamic route for Reset Password
        if (settings.name == '/confirmation') {
          final email = settings.arguments as String; // Retrieve email from arguments
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: email), // Pass email to ResetPasswordScreen
          );
        }

        return null; // Return null if no matching route
      },
    );
  }
}