import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
    setState(() => _isLoading = true);
    try {
      final history = await ApiService.fetchSensorHistory(
        widget.userId,
        'battery',
        widget.token,
      );
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sensor history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHistoryEntry(String historyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Entry'),
        content: Text('Are you sure you want to delete this history entry?'),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: Text('Delete'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteSensorHistoryById(historyId, widget.token);
        _fetchBatteryHistory();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting entry: $e')));
      }
    }
  }

  Future<void> _deleteAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete All History'),
        content: Text('Are you sure you want to delete ALL sensor history?'),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(child: Text('Delete All'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteAllSensorHistoryForUser(widget.userId, widget.token);
        _fetchBatteryHistory();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting history: $e')));
      }
    }
  }

  String formatDateTime(String timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(timestamp));
  }

  double getAverage(List<double> values) => values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;
  double getMin(List<double> values) => values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
  double getMax(List<double> values) => values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final batteryLevels = _history.map((e) => (e['data']['batteryLevel'] as num?)?.toDouble() ?? 0).toList();
    final temperatures = _history.map((e) => (e['data']['temperature'] as num?)?.toDouble() ?? 0).toList();
    final humidities = _history.map((e) => (e['data']['humidity'] as num?)?.toDouble() ?? 0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Battery History'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_forever),
            tooltip: 'Delete All History',
            onPressed: _history.isNotEmpty ? _deleteAllHistory : null,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Text('No sensor history available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryCard('Battery Level (%)', batteryLevels),
                      _buildSummaryCard('Temperature (°C)', temperatures),
                      _buildSummaryCard('Humidity (%)', humidities),
                      const SizedBox(height: 20),
                      _buildLineChart('Battery Level Over Time', batteryLevels, '%'),
                      const SizedBox(height: 20),
                      _buildLineChart('Temperature Over Time', temperatures, '°C'),
                      const SizedBox(height: 20),
                      _buildLineChart('Humidity Over Time', humidities, '%'),
                      const SizedBox(height: 20),
                      Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final entry = _history[index];
                          final data = entry['data'] ?? {};
                          final historyId = entry['_id'];
                          final batteryLevel = data['batteryLevel'] != null ? '${data['batteryLevel']}%' : 'N/A';
                          final temperature = data['temperature'] != null ? '${data['temperature']}°C' : 'N/A';
                          final humidity = data['humidity'] != null ? '${data['humidity']}%' : 'N/A';

                          return ListTile(
                            title: Text('Battery: $batteryLevel'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Temperature: $temperature'),
                                Text('Humidity: $humidity'),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(formatDateTime(entry['timestamp'])),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteHistoryEntry(historyId),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String label, List<double> values) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Avg: ${getAverage(values).toStringAsFixed(1)}'),
                Text('Min: ${getMin(values).toStringAsFixed(1)}'),
                Text('Max: ${getMax(values).toStringAsFixed(1)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(String title, List<double> values, String unit) {
    if (values.isEmpty) return Center(child: Text('No data for $title'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(show: true),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}