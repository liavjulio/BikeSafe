import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/notification_service.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart'; // Make sure this is imported
import 'package:firebase_messaging/firebase_messaging.dart';
import 'map_screen.dart';
import 'package:http/http.dart' as http;
import '../services/bluetooth_service.dart';

import '../utils/constants.dart'; // Adjust path as needed

final String _baseUrl = Constants.envBaseUrl;

class MainScreen extends StatefulWidget {
  final String userId;
  final String token;
  final Function(ThemeMode) onThemeChanged;

  const MainScreen({
    Key? key,
    required this.userId,
    required this.token,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<BluetoothDevice> _availableDevices = [];
  BluetoothDevice? _selectedDevice;
  String _batteryTemp = '--';
  late BikeSafeBluetoothService bluetoothService;
  final NotificationService _notificationService = NotificationService();

  @override
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  Future<void> _logout() async {
    try {
      // Navigate to the login screen (or initial route) and remove previous routes.
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout. Please try again.')),
      );
    }
  }
  Future<void> _initializeApp() async {
    try {
      // ✅ Initialize the Bluetooth Service first
      bluetoothService = BikeSafeBluetoothService(
        userId: widget.userId,
        token: widget.token,
      );
      bluetoothService.addListener(_onBluetoothDataUpdate);

      // ✅ Step 1: Handle Bluetooth permissions and scan
      await _initializeBluetooth();
      debugPrint('✅ Bluetooth initialized');
      await Firebase.initializeApp();
      debugPrint('✅ Firebase initialized');
      // ✅ Step 2: Handle Notification permissions and initialize FCM
      await _notificationService.init(context);
      debugPrint('✅ Notifications initialized');

      _notificationService.initializeFCM(
        userId: widget.userId,
        jwtToken: widget.token,
        baseUrl: _baseUrl,
        context: context,
        onTokenRefresh: (newToken) {
          debugPrint(
              '🔄 Token refresh callback triggered with new token: $newToken');
        },
      );
    } catch (e) {
      debugPrint('❌ Error initializing app: $e');
    }
  }

  void _onBluetoothDataUpdate() {
    setState(() {
      _batteryTemp =
          '${bluetoothService.latestTemperature.toStringAsFixed(1)}°C';
    });
  }

  Future<void> _initializeBluetooth() async {
    await _requestBluetoothPermissions();
    await _startBluetoothScan();
  }

  Future<void> _requestBluetoothPermissions() async {
    if (Platform.isAndroid) {
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final location = await Permission.locationWhenInUse.request();

      if (!bluetoothScan.isGranted ||
          !bluetoothConnect.isGranted ||
          !location.isGranted) {
        debugPrint('❌ Bluetooth/Location permissions not granted');
        return;
      }
    }

    bool isEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;

    if (!isEnabled) {
      isEnabled =
          await FlutterBluetoothSerial.instance.requestEnable() ?? false;

      if (!isEnabled) {
        debugPrint('❌ Bluetooth not enabled!');
        return;
      }
    }

    debugPrint('✅ Bluetooth is enabled!');
  }

  Future<void> _startBluetoothScan() async {
    debugPrint('🔍 Starting Bluetooth scan...');
    await bluetoothService.scanForDevices();

    if (!mounted) return;

    setState(() {
      _availableDevices = bluetoothService.scannedDevices;
    });

    debugPrint("✅ Devices found: ${_availableDevices.length}");
  }

  Future<void> _connectToSelectedDevice() async {
    if (_selectedDevice == null) {
      debugPrint('❌ No device selected!');
      return;
    }

    await bluetoothService.connectToDevice(_selectedDevice!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Connected to ${_selectedDevice!.name}')),
    );
  }

  @override
  void dispose() {
    bluetoothService.removeListener(_onBluetoothDataUpdate);
    bluetoothService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BikeSafe Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.pushNamed(context, '/help'),
          ),
          IconButton(
            icon: const Icon(Icons.feedback), // Feedback icon
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/feedback',
                arguments: {
                  'userId': widget.userId,
                  'token': widget.token,
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () =>
                Navigator.pushNamed(context, '/profile', arguments: {
              'userId': widget.userId,
              'token': widget.token,
            }),
          ),
          IconButton(
            icon: const Icon(Icons.nightlight_round),
            onPressed: () => widget.onThemeChanged(
              Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpansionTile(
                      initiallyExpanded: false,
                      title: Text('Bluetooth Controls',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      leading: Icon(Icons.bluetooth),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<BluetoothDevice>(
                            hint: const Text("Select Paired Bluetooth Device"),
                            isExpanded: true,
                            value: _selectedDevice != null &&
                                    _availableDevices.contains(_selectedDevice!)
                                ? _selectedDevice
                                : null,
                            items: _availableDevices.map((device) {
                              return DropdownMenuItem<BluetoothDevice>(
                                value: device,
                                child: Text(device.name ?? "Unknown Device"),
                              );
                            }).toList(),
                            onChanged: (BluetoothDevice? device) {
                              if (device == null) return;
                              setState(() => _selectedDevice = device);
                              debugPrint(
                                  "✅ Device selected: ${device.name} (${device.address})");
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _connectToSelectedDevice,
                              icon: const Icon(Icons.bluetooth_connected),
                              label: const Text("Connect"),
                            ),
                            ElevatedButton.icon(
                              onPressed: _startBluetoothScan,
                              icon: const Icon(Icons.refresh),
                              label: const Text("Refresh"),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sensor Data Dashboard Card
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('📡 Live Sensor Data',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Divider(),
                            SizedBox(height: 8),
                            _sensorDataRow('Battery Temp:',
                                '${bluetoothService.latestTemperature.toStringAsFixed(1)}°C'),
                            _sensorDataRow('Humidity:',
                                '${bluetoothService.latestHumidity.toStringAsFixed(1)}%'),
                            _sensorDataRow('Speed:',
                                '${bluetoothService.speed.toStringAsFixed(2)} km/h'),
                            _sensorDataRow('Altitude:',
                                '${bluetoothService.altitude.toStringAsFixed(1)} m'),
                            _sensorDataRow('Satellites:',
                                '${bluetoothService.satellites.toString()}'),
                            _sensorDataRow('HDOP:',
                                '${bluetoothService.hdop.toStringAsFixed(2)}'),
                            _sensorDataRow(
                                'GPS Time:', '${bluetoothService.gpsTime}'),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: Icon(Icons.history),
                      label: Text('Sensor History'),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/battery-history',
                          arguments: {
                            'userId': widget.userId,
                            'token': widget.token,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Relay Controls in a Grid
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.8,
                      physics: NeverScrollableScrollPhysics(),
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => bluetoothService.sendCommand('1A'),
                          icon: Icon(Icons.flash_on),
                          label: Text('Relay 1 ON'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => bluetoothService.sendCommand('1F'),
                          icon: Icon(Icons.flash_off),
                          label: Text('Relay 1 OFF'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => bluetoothService.sendCommand('2A'),
                          icon: Icon(Icons.flash_on),
                          label: Text('Relay 2 ON'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => bluetoothService.sendCommand('2F'),
                          icon: Icon(Icons.flash_off),
                          label: Text('Relay 2 OFF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => bluetoothService.sendCommand('R'),
                      icon: Icon(Icons.restart_alt),
                      label: const Text("Reset System"),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Widget _sensorDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16)),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
