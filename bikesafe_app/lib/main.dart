import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/google_login_screen.dart';
import 'screens/resetPassword_screen.dart';
import 'screens/main_screen.dart';
import 'screens/alerts_settings.dart';
import 'screens/feedback_screen.dart';
import 'screens/help_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/battery_history_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures binding is initialized
  await dotenv.load(fileName: "assets/.env");
  runApp(BikeSafeApp());
}

class BikeSafeApp extends StatefulWidget {
  @override
  _BikeSafeAppState createState() => _BikeSafeAppState();
}

class _BikeSafeAppState extends State<BikeSafeApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeSafe',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.blueAccent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blueGrey,
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      themeMode: _themeMode, // Dynamically handle theme mode
      initialRoute: '/', // Set the initial route for the app
      routes: {
        '/home': (context) => HomeScreen(),
        '/google-login': (context) => GoogleLoginScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/alerts-settings': (context) => AlertsSettingsScreen(),
        '/feedback': (context) => FeedbackScreen(),
        '/help': (context) => HelpScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle the navigation to MainScreen with userId and token passed as arguments
        if (settings.name == '/main') {
          final args = settings.arguments as Map<String, dynamic>;

          return MaterialPageRoute(
            builder: (context) => MainScreen(
              userId: args['userId'], // Pass userId from args
              token: args['token'],   // Pass token from args
              onThemeChanged: (themeMode) {
                setState(() {
                  _themeMode = themeMode; // Update theme when toggled
                });
              },
            ),
          );
        }

        // Handle other routes
        if (settings.name == '/battery-history') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => BatteryHistoryScreen(
              userId: args['userId'],
              token: args['token'],
            ),
          );
        }

        if (settings.name == '/profile') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => UserProfileScreen(
              userId: args['userId'],
              token: args['token'],
            ),
          );
        }

        if (settings.name == '/confirmation') {
          final email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: email),
          );
        }

        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => HomeScreen());
      },
    );
  }
}