import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class BatteryHistoryScreen extends StatefulWidget {
  final String userId;
  final String token;

  BatteryHistoryScreen({required this.userId, required this.token});

  @override
  _BatteryHistoryScreenState createState() => _BatteryHistoryScreenState();
}

class _BatteryHistoryScreenState extends State<BatteryHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBatteryHistory();
  }

  Future<void> _fetchBatteryHistory() async {
    try {
      final history = await ApiService.fetchSensorHistory(widget.userId, 'battery', widget.token);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load battery history: $e';
        _isLoading = false;
      });
    }
  }

  String formatDateTime(String timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Battery History')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Text('No battery history available'))
              : ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final entry = _history[index];
                    return ListTile(
                      title: Text('Battery: ${entry['data']['batteryLevel']}%'),
                      subtitle: Text('Temperature: ${entry['data']['temperature']}°C'),
                      trailing: Text(formatDateTime(entry['timestamp'])),
                    );
                  },
                ),
    );
  }
}