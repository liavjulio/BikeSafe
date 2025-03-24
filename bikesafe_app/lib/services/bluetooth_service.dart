import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../utils/constants.dart'; // Adjust path as needed

final String baseUrl = Constants.envBaseUrl;

class BikeSafeBluetoothService extends ChangeNotifier {
  List<BluetoothDevice> scannedDevices = [];
  BluetoothConnection? connection;
  bool isConnected = false;

  // 🔥 Real-time sensor data variables
  double latestTemperature = 0.0;
  double latitude = 0.0;
  double longitude = 0.0;
  double latestHumidity = 0.0;
  double speed = 0.0;
  double altitude = 0.0;
  int satellites = 0;
  double hdop = 0.0;
  String gpsTime = '';
  final String userId;
  final String token;

  BikeSafeBluetoothService({
    required this.userId,
    required this.token,
  });

  /// ✅ Get paired Bluetooth devices
  Future<void> scanForDevices() async {
    debugPrint("🔍 Scanning for bonded devices...");
    scannedDevices.clear();
    notifyListeners();

    try {
      scannedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();

      if (scannedDevices.isEmpty) {
        debugPrint("❌ No paired Bluetooth devices found.");
      } else {
        for (var device in scannedDevices) {
          debugPrint(
              "📡 Paired Device: ${device.name} | MAC: ${device.address}");
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Failed to get bonded devices: $e");
    }
  }

  /// ✅ Connect to the selected device
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      debugPrint("🔗 Connecting to ${device.name} (${device.address})...");
      connection = await BluetoothConnection.toAddress(device.address);
      isConnected = true;
      debugPrint("✅ Connected to ${device.name}");

      connection!.input!.listen((Uint8List data) {
        try {
          String receivedData = ascii.decode(data);
          debugPrint("📡 Received: $receivedData");
          processSensorData(receivedData);
        } catch (e) {
          debugPrint("❌ Error decoding data: $e");
        }
      }).onDone(() {
        debugPrint("🔌 Connection closed by remote device");
        isConnected = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("❌ Connection error: $e");
      isConnected = false;
      notifyListeners();
    }
  }

  /// ✅ Send data to ESP32
  void sendCommand(String command) {
    if (connection != null && isConnected) {
      connection!.output.add(utf8.encode(command + "\n"));
      debugPrint("📤 Sent: $command");
    } else {
      debugPrint("❌ No active connection to send data.");
    }
  }

  /// ✅ Process incoming data and send it to your backend
  void processSensorData(String data) {
    Map<String, String> parsedData = {};
    List<String> pairs = data.split(';');

    for (String pair in pairs) {
      List<String> keyValue = pair.split(':');
      if (keyValue.length == 2) {
        parsedData[keyValue[0].toLowerCase()] = keyValue[1];
      }
    }

    // Update local variables with parsed values
    latestTemperature = double.tryParse(parsedData['temp'] ?? '0') ?? 0.0;
    latestHumidity = double.tryParse(parsedData['humidity'] ?? '0') ?? 0.0;
    latitude = double.tryParse(parsedData['lat'] ?? '0') ?? 0.0;
    longitude = double.tryParse(parsedData['lon'] ?? '0') ?? 0.0;
    speed = double.tryParse(parsedData['speed'] ?? '0') ?? 0.0;
    altitude = double.tryParse(parsedData['altitude'] ?? '0') ?? 0.0;
    satellites = int.tryParse(parsedData['satellites'] ?? '0') ?? 0;
    hdop = double.tryParse(parsedData['hdop'] ?? '0') ?? 0.0 / 100.0;
    gpsTime = parsedData['time'] ?? '';

    notifyListeners();
    sendSensorDataToBackend();
  }

  /// ✅ Send processed data to backend
  Future<void> sendSensorDataToBackend() async {
    final response = await http.post(
      Uri.parse('$baseUrl/sensor/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'sensorId': 'ESP32_SENSOR',
        'data': {
          'temperature': latestTemperature,
          'humidity': latestHumidity, // ✅ Added humidity!
          'latitude': latitude,
          'longitude': longitude,
        },
      }),
    );

    if (response.statusCode == 200) {
      debugPrint("✅ Sensor data sent successfully");
    } else {
      debugPrint("❌ Failed to send sensor data: ${response.statusCode}");
    }
  }

  /// ✅ Disconnect cleanly
  Future<void> disconnect() async {
    try {
      await connection?.close();
      connection = null;
      isConnected = false;
      debugPrint("🔌 Disconnected from device");
    } catch (e) {
      debugPrint("❌ Error disconnecting: $e");
    }
    notifyListeners();
  }
}
