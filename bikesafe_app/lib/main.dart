import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/google_login_screen.dart';
import 'screens/resetPassword_screen.dart';

void main() {
  runApp(BikeSafeApp());
}

class BikeSafeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeSafe',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      home: HomeScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/google-login': (context) => GoogleLoginScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
      },
      // Use onGenerateRoute for dynamic routes with arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/confirmation') {
          final email = settings.arguments as String;  // Retrieve email from arguments
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: email), // Pass email to ResetPasswordScreen
          );
        }
        return null; // Return null if no matching route
      },
    );
  }
}