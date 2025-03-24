//bikesafe_app/lib/screens/user_profile_screen.dart
import 'dart:io'; // ✅ Import Platform
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart'; // Adjust path as needed

final String _apiBaseUrl = Constants.envBaseUrl;

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String token;

  UserProfileScreen({required this.userId, required this.token});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? userData;
  bool _isLoading = true;
  TextEditingController _batteryCompanyController = TextEditingController();
  TextEditingController _batteryTypeController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final response = await http.get(
      Uri.parse(
          '$_apiBaseUrl/auth/user/${widget.userId}'), // ✅ Dynamic Base URL
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
        _batteryCompanyController.text = userData?['batteryCompany'] ?? '';
        _batteryTypeController.text = userData?['batteryType'] ?? '';
        _nameController.text = userData?['name'] ?? '';
        _phoneController.text = userData?['phone'] ?? '';
        _isLoading = false;
      });
    } else {
      print("❌ Failed to load user profile: ${response.body}");
    }
  }

  Future<void> _updateProfile() async {
    final response = await http.put(
      Uri.parse(
          '$_apiBaseUrl/auth/user/${widget.userId}'), // ✅ Dynamic Base URL
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'batteryCompany': _batteryCompanyController.text,
        'batteryType': _batteryTypeController.text,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Profile updated successfully!");
      _fetchUserProfile(); // Refresh the screen with updated data
    } else {
      print("❌ Failed to update profile: ${response.body}");
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    final response = await http.put(
      Uri.parse(
          '$_apiBaseUrl/auth/user/change-password/${widget.userId}'), // Add your endpoint for password change
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({'password': _passwordController.text}),
    );

    if (response.statusCode == 200) {
      print("✅ Password updated successfully!");
      _passwordController.clear();
      _confirmPasswordController.clear();
    } else {
      print("❌ Failed to change password: ${response.body}");
    }
  }

  Future<void> _deleteAccount() async {
    final response = await http.delete(
      Uri.parse(
          '$_apiBaseUrl/auth/delete-account/${widget.userId}'), // ✅ Dynamic Base URL
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );

    if (response.statusCode == 200) {
      print("✅ Account deleted successfully!");
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      print("❌ Failed to delete account: ${response.body}");
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Account"),
        content: Text(
            "Are you sure you want to delete your account? This action is irreversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
            tooltip: "Delete Account",
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(
                        "assets/profile.png"), // Change to actual profile image
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: "Name"),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(labelText: "Phone"),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _batteryCompanyController,
                    decoration: InputDecoration(labelText: "Battery Company"),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _batteryTypeController,
                    decoration: InputDecoration(labelText: "Battery Type"),
                  ),
                  SizedBox(height: 20),
                  // **NEW: Password Change Section**
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: "New Password"),
                    obscureText: true,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(labelText: "Confirm Password"),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text("Update Profile"),
                  ),
                  SizedBox(height: 20),

                  // **NEW: Alerts Settings Button**
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/alerts-settings',
                          arguments: {
                            'userId': widget.userId,
                            'token': widget.token
                          });
                    },
                    icon: Icon(Icons.notifications_active),
                    label: Text("Manage Alerts"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: Text("Logout"),
                  ),
                  SizedBox(height: 20),

                  // **NEW: Change Password Button**
                  ElevatedButton(
                    onPressed: _changePassword,
                    child: Text("Change Password"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
