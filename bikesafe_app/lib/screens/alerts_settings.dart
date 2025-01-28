import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AlertsSettingsScreen extends StatefulWidget {
  @override
  _AlertsSettingsScreenState createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  Map<String, bool> alertPreferences = {};
  late String userId;
  late String token;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    userId = args['userId'];
    token = args['token'];

    // Fetch preferences when the screen loads
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
  try {
    print('Fetching alert preferences for user: $userId');
    final preferences = await ApiService.fetchAlertPreferences(userId, token);
    print('Fetched preferences: $preferences'); // Debugging print

    // Ensure we update the UI with the fetched preferences
    setState(() {
      alertPreferences = preferences;
      _isLoading = false;
    });
  } catch (e) {
    print('Error fetching preferences: $e');
    setState(() {
      _isLoading = false;
    });
  }
}

  void updatePreferences(String alertType, bool value) {
    setState(() {
      alertPreferences[alertType] = value;
    });
  }

  void savePreferences() async {
  setState(() {
    _isLoading = true;
  });

  try {
    print('Saving preferences for user: $userId with token: $token');
    print('Preferences to save: $alertPreferences');

    final response = await ApiService.updateAlertPreferences(
      userId, // Pass the userId
      token,  // Pass the token
      alertPreferences.keys.where((key) => alertPreferences[key] == true).toList(), // Correct argument type
    );

    if (response) {
      print('Preferences saved successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences saved successfully!')),
      );
    }
  } catch (e) {
    print('Error saving preferences: $e');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts Settings'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: alertPreferences.keys.map((alertType) {
                return CheckboxListTile(
                  title: Text(alertType.replaceAll('-', ' ').toUpperCase()),
                  value: alertPreferences[alertType],
                  onChanged: (value) => updatePreferences(alertType, value!),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: savePreferences,
        child: Icon(Icons.save),
      ),
    );
  }
}