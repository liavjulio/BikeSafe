//bikesafe_app/lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'map_screen.dart';
import 'battery_history_screen.dart';

final String _baseUrl = Platform.isAndroid
    ? 'http://10.0.2.2:5001/api'
    : 'http://localhost:5001/api';

class MainScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Function(ThemeMode) onThemeChanged;

  MainScreen({required this.userId, required this.token, required this.onThemeChanged});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _batteryTemp = '--';
  Timer? _batteryTimer;

  @override
  void initState() {
    super.initState();
    _fetchBatteryTemperature();
    _startBatteryMonitor();
  }

  Future<void> _triggerMockUpdate() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sensor/update-mock'),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"userId": widget.userId}),
    );

    if (response.statusCode == 200) {
      print("✅ Mock sensor data updated!");
      _fetchBatteryTemperature(); 
    } else {
      print("❌ Failed to update mock data: ${response.statusCode}");
    }
  }

  Future<void> _fetchBatteryTemperature() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sensor/data?userId=${widget.userId}&type=temperature'),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data.containsKey('temperature')) {
        setState(() {
          _batteryTemp = '${data['temperature']}°C';
        });
      } else {
        print("❌ Temperature data not available");
      }
    } else {
      print("❌ Failed to fetch battery temperature: ${response.statusCode}");
    }
  }

  Future<void> _addSensor() async {
    TextEditingController sensorIdController = TextEditingController();
    TextEditingController dataController = TextEditingController();
    String selectedType = "temperature";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add New Sensor"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: sensorIdController,
                    decoration: InputDecoration(labelText: "Sensor ID"),
                  ),
                  DropdownButton<String>(
                    value: selectedType,
                    items: ["temperature", "gps", "battery", "humidity"]
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                        dataController.text = _getDefaultValueForType(selectedType);
                      });
                    },
                  ),
                  TextField(
                    controller: dataController,
                    decoration: InputDecoration(
                        labelText: _getLabelForType(selectedType)),
                    keyboardType: _getKeyboardTypeForType(selectedType),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (sensorIdController.text.isEmpty) return;
                    await _createSensor(sensorIdController.text, selectedType, dataController.text);
                    Navigator.pop(context);
                  },
                  child: Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createSensor(String sensorId, String type, String data) async {
    Map<String, dynamic> sensorData = {};

    switch (type) {
      case "temperature":
        sensorData["temperature"] = double.tryParse(data) ?? 25.0;
        break;
      case "gps":
        sensorData["latitude"] = 32.0151;
        sensorData["longitude"] = 34.7528;
        break;
      case "battery":
        sensorData["batteryLevel"] = int.tryParse(data) ?? 80;
        break;
      case "humidity":
        sensorData["humidity"] = double.tryParse(data) ?? 40.0;
        break;
    }

    final response = await http.post(
      Uri.parse("$_baseUrl/sensor/create"),
      headers: {
        "Authorization": "Bearer ${widget.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": widget.userId,
        "sensorId": sensorId,
        "type": type,
        "data": sensorData,
      }),
    );

    if (response.statusCode == 201) {
      print("✅ Sensor added successfully");
      _fetchBatteryTemperature();
      setState(() {});
    } else {
      print("❌ Failed to add sensor: ${response.statusCode}");
    }
  }

  String _getDefaultValueForType(String type) {
    switch (type) {
      case "temperature":
        return "25.0";
      case "gps":
        return "32.0151, 34.7528";
      case "battery":
        return "80";
      case "humidity":
        return "40.0";
      default:
        return "";
    }
  }

  String _getLabelForType(String type) {
    switch (type) {
      case "temperature":
        return "Temperature (°C)";
      case "gps":
        return "Latitude, Longitude";
      case "battery":
        return "Battery Level (%)";
      case "humidity":
        return "Humidity (%)";
      default:
        return "Data";
    }
  }

  TextInputType _getKeyboardTypeForType(String type) {
    switch (type) {
      case "gps":
        return TextInputType.text;
      case "temperature":
      case "battery":
      case "humidity":
        return TextInputType.numberWithOptions(decimal: true);
      default:
        return TextInputType.text;
    }
  }

  void _startBatteryMonitor() {
    _batteryTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchBatteryTemperature();
    });
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BikeSafe Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, 
        centerTitle: true,
        elevation: 4.0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            tooltip: "Help & Guidance",
            onPressed: () => Navigator.pushNamed(context, '/help'),
          ),
          IconButton(
            icon: Icon(Icons.person),
            tooltip: "Profile",
            onPressed: () {
              Navigator.pushNamed(context, '/profile',
                  arguments: {'userId': widget.userId, 'token': widget.token});
            },
          ),
          IconButton(
            icon: Icon(Icons.nightlight_round),
            onPressed: () {
              widget.onThemeChanged(
                Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: MapScreen(userId: widget.userId, token: widget.token),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Battery Temperature: $_batteryTemp',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _triggerMockUpdate,
                      icon: Icon(Icons.refresh, size: 24),
                      label: Text("Update Sensors",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addSensor,
                      icon: Icon(Icons.add, size: 24),
                      label: Text("Add Sensor",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 4,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildButton(
                      context,
                      title: 'Battery History',
                      color: Colors.blueAccent,
                      icon: Icons.battery_full,
                      route: '/battery-history',
                      tooltip: "View battery temperature and charge history",
                    ),
                    const SizedBox(height: 10),

                    _buildButton(
                      context,
                      title: 'Alerts Settings',
                      color: Colors.orange,
                      icon: Icons.settings,
                      route: '/alerts-settings',
                      tooltip: "Manage notification preferences",
                    ),
                    const SizedBox(height: 10),

                    _buildButton(
                      context,
                      title: 'Submit Feedback',
                      color: Colors.green,
                      icon: Icons.feedback,
                      route: '/feedback',
                      tooltip: "Tell us what you think about BikeSafe",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context,
      {required String title,
      required Color color,
      required IconData icon,
      required String route,
      required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: ElevatedButton.icon(
        onPressed: () =>
            Navigator.pushNamed(context, route, arguments: {'userId': widget.userId, 'token': widget.token}),
        icon: Icon(icon, size: 24),
        label: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 4,
        ),
      ),
    );
  }
}