//bikesafe_app/lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

import '../utils/constants.dart'; // Adjust path as needed

final String _baseUrl = Constants.envBaseUrl;

class MapScreen extends StatefulWidget {
  final String userId;
  final String token;

  MapScreen({required this.userId, required this.token});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Location _location = Location();
  LatLng? _bikeLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  // Safe Zone variables
  LatLng? _safeZoneCenter;
  double _safeZoneRadius = 20; 
  void _startLocationMonitor() {
    Timer.periodic(Duration(seconds: 10), (timer) {
      _fetchBikeLocation();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCustomMarker(); // Load your marker here!
    _fetchBikeLocation();
    _fetchSafeZone();
    _trackLocation();
    _startLocationMonitor();
  }

  BitmapDescriptor? customIcon;

  Future<void> _loadCustomMarker() async {
    customIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/bike_marker.png', // Make sure this path is correct
    );
    setState(() {}); // Refresh UI after loading
  }

  /// Fetch bike's real-time location from backend
  void _fetchBikeLocation() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/location/realtime?userId=${widget.userId}'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final lat = (data['currentLocation']['latitude'] as num).toDouble();
      final lng = (data['currentLocation']['longitude'] as num).toDouble();

      LatLng newLocation = LatLng(lat, lng);

      setState(() {
        _bikeLocation = newLocation;
      });

      _controller?.animateCamera(CameraUpdate.newLatLng(newLocation));
    } else {
      print("Failed to fetch bike location: ${response.statusCode}");
    }
  }

  /// Track real-time location updates (device GPS) and update the backend
  void _trackLocation() {
    _locationSubscription =
        _location.onLocationChanged.listen((LocationData locationData) async {
      final lat = locationData.latitude;
      final lng = locationData.longitude;

      if (lat == null || lng == null) return;

      LatLng newLocation = LatLng(lat, lng);
      setState(() => _bikeLocation = newLocation);
      _controller?.animateCamera(CameraUpdate.newLatLng(newLocation));

      await _updateLocationOnServer(locationData);
    });
  }

  /// Send updated location to backend
  Future<void> _updateLocationOnServer(LocationData locationData) async {
    final lat = locationData.latitude;
    final lng = locationData.longitude;

    if (lat == null || lng == null) return;

    final url = '$_baseUrl/location/update';

    try {
      await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'latitude': lat,
          'longitude': lng,
        }),
      );
    } catch (error) {
      print('Failed to update location: $error');
    }
  }

  void _setSafeZone() async {
    if (_bikeLocation == null) {
      print("🚨 _setSafeZone() called, but _bikeLocation is null!");
      return;
    }

    print("✅ _setSafeZone() called, bike location = $_bikeLocation");

    setState(() {
      _safeZoneCenter = _bikeLocation;
      _safeZoneRadius = 500;
    });

    print("📡 Sending safe zone to server...");

    final url = '$_baseUrl/location/safe-zone';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': widget.userId,
          'latitude': _safeZoneCenter?.latitude,
          'longitude': _safeZoneCenter?.longitude,
          'radius': _safeZoneRadius,
        }),
      );

      print("🔄 Response status: ${response.statusCode}");
      print("📩 Response body: ${response.body}");

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Safe Zone Set"),
            content: Text("Your safe zone has been set successfully!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        print("❌ Failed to save safe zone: ${response.statusCode}");
      }
    } catch (error) {
      print("❌ Error saving safe zone: $error");
    }
  }

  /// Fetch Safe Zone from backend if already set
  Future<void> _fetchSafeZone() async {
    final url = '$_baseUrl/location/safe-zone?userId=${widget.userId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final lat = (data['latitude'] as num).toDouble();
      final lng = (data['longitude'] as num).toDouble();
      final rad = (data['radius'] as num).toDouble();

      setState(() {
        _safeZoneCenter = LatLng(lat, lng);
        _safeZoneRadius = rad;
      });

      print("Fetched safe zone lat=$lat, lng=$lng, rad=$rad");
    } else {
      print(
          "No safe zone data found or error fetching. Code: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _bikeLocation ?? LatLng(32.0853, 34.7818), // תל אביב
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            markers: _bikeLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('bikeLocation'),
                      position: _bikeLocation!,
                      icon: customIcon ??
                          BitmapDescriptor.defaultMarker, // fallback
                      infoWindow: const InfoWindow(title: 'Your Bike'),
                    ),
                  }
                : {},
            circles: _safeZoneCenter != null
                ? {
                    Circle(
                      circleId: CircleId('safeZone'),
                      center: _safeZoneCenter!,
                      radius: _safeZoneRadius,
                      fillColor: Colors.blue.withOpacity(0.3),
                      strokeColor: Colors.blue,
                      strokeWidth: 2,
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 80,
            left: 20,
            child: ElevatedButton(
              onPressed: _setSafeZone,
              child: Text("Set Safe Zone"),
            ),
          ),
        ],
      );
    
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
