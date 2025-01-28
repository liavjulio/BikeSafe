import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  final String userId;
  final String token;
  MainScreen({required this.userId, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BikeSafe Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4.0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Text
                const Text(
                  'Welcome to BikeSafe',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black26, blurRadius: 5),
                    ],
                  ),
                ),
                const SizedBox(height: 15),

                // Battery Status
                BatteryStatusWidget(userId: userId),
                const SizedBox(height: 30),

                // Buttons
                _buildButton(context, 'Alerts Settings', Colors.orange, Icons.settings, '/alerts-settings'),
                const SizedBox(height: 15),
                _buildButton(context, 'Submit Feedback', Colors.green, Icons.feedback, '/feedback'),

                const SizedBox(height: 40),

                // Footer Text
                const Text(
                  "Your bike's safety, reimagined!",
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable Button Widget
  Widget _buildButton(BuildContext context, String title, Color color, IconData icon, String route) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, route, arguments: {'userId': userId, 'token': token}),
      icon: Icon(icon, size: 24),
      label: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
    );
  }
}

class BatteryStatusWidget extends StatelessWidget {
  final String userId;
  BatteryStatusWidget({required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: fetchBatteryStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Text('Error loading battery status');
        } else {
          final batteryLevel = snapshot.data ?? 0;
          return Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'Battery Status:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$batteryLevel%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: batteryLevel > 50 ? Colors.green : Colors.red,
                    ),
                  ),
                  if (batteryLevel < 20)
                    const Text(
                      'Warning: Low Battery!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  // Simulated API Call (Replace with actual API call)
  Future<int> fetchBatteryStatus() async {
    await Future.delayed(Duration(seconds: 1)); // Simulating network delay
    return 75; // Example: 75% battery level
  }
}