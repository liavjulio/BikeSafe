//bikesafe_app/lib/screens/admin_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/constants.dart';

final String _baseUrl = Constants.envBaseUrl;

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _token;
  String? _userId;

  @override
  void didChangeDependencies() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && _token == null) {
      _token = args['token'];
      _userId = args['userId'];
      _fetchUsers();
    }

    super.didChangeDependencies();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/users'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
        });
      } else {
        throw Exception('Failed to load users: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching users: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdminStatus(String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/users/$userId/toggle-admin'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User admin status updated.'),
        ));
        _fetchUsers();
      } else {
        throw Exception('Failed: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Toggle admin error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating admin status')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((user) => user['_id'] == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted')),
        );
      } else {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(user['email'] ?? 'No Email'),
                      subtitle: Text(user['name'] ?? 'No Name'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              user['isAdmin'] == true
                                  ? Icons.shield
                                  : Icons.shield_outlined,
                              color: Colors.blue,
                            ),
                            tooltip: user['isAdmin'] == true
                                ? 'Demote from Admin'
                                : 'Promote to Admin',
                            onPressed: () => _toggleAdminStatus(user['_id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            tooltip: 'Delete User',
                            onPressed: () => _deleteUser(user['_id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
