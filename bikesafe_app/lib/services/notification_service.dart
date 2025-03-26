import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart'; // Adjust path as needed
import 'package:http/http.dart' as http;
import 'dart:convert';


final String _baseUrl = Constants.envBaseUrl;
class NotificationService {
  // Singleton pattern (optional but good practice)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Future<void> init(BuildContext context) async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initSettings = InitializationSettings(android: androidInitSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null) {
          debugPrint('Notification payload: $payload');
          // Example: Navigate somewhere
          Navigator.pushNamed(context, '/alerts-settings');
        }
      },
    );

    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        print('❌ Notification permission not granted!');
      }
    }
  }

  Future<void> showLocalNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'bikesafe_channel', // Channel ID
      'BikeSafe Alerts', // Channel Name
      channelDescription: 'Notifications for BikeSafe alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title ?? 'BikeSafe Alert',
      body ?? 'You have a new notification!',
      notificationDetails,
    );
  }
  /// Registers the device token with your backend.
  Future<void> registerDeviceToken({
    required String userId,
    required String jwtToken,
    required String baseUrl,
  }) async {
    try {
      debugPrint('🔄 Starting device token registration...');
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('✅ Retrieved FCM Token: $fcmToken');

      if (fcmToken != null) {
        debugPrint('Sending registration for userId: $userId with token: $fcmToken');
        final response = await http.post(
          Uri.parse('$baseUrl/alerts/save-token'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'userId': userId,
            'token': fcmToken,
          }),
        );

        debugPrint('Response status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        if (response.statusCode == 200) {
          debugPrint('✅ FCM token registered successfully!');
        } else {
          debugPrint('❌ Failed to register FCM token');
        }
      } else {
        debugPrint('❌ FCM token is null, registration aborted');
      }
    } catch (e) {
      debugPrint('❌ Error registering FCM token: $e');
    }
  }

  /// Initializes FCM for the app.
  void initializeFCM({
    required String userId,
    required String jwtToken,
    required BuildContext context,
    required String baseUrl,
    required Function(String newToken) onTokenRefresh,
  }) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Step 1: Get and register the initial FCM token
    String? fcmToken = await messaging.getToken();
    debugPrint('✅ Initial FCM Token: $fcmToken');

    if (fcmToken != null) {
      // Immediately register the token
      await registerDeviceToken(userId: userId, jwtToken: jwtToken, baseUrl: baseUrl);
    } else {
      debugPrint('❌ Failed to retrieve initial FCM Token');
    }

    // Step 2: Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      onTokenRefresh(newToken);
      await registerDeviceToken(userId: userId, jwtToken: jwtToken, baseUrl: baseUrl);
    });

    // Step 3: Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      debugPrint('📩 FCM message received in foreground: ${notification?.title}');
      showLocalNotification(notification?.title, notification?.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notification?.body ?? 'You have a new alert!')),
      );
    });

    // Step 4: Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🟢 App opened from FCM message: ${message.notification?.title}');
      Navigator.pushNamed(context, '/alerts-settings');
    });

    // Step 5: Handle terminated state (app launched via notification)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App launched from notification: ${message.notification?.title}');
        Navigator.pushNamed(context, '/alerts-settings');
      }
    });
  }
}