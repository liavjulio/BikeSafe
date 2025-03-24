import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

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

  void initializeFCM({
    required String userId,
    required String jwtToken,
    required BuildContext context,
    required Function(String newToken) onTokenRefresh,
  }) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // ✅ Step 1: Log the FCM Token
    String? fcmToken = await messaging.getToken();
    debugPrint('✅ FCM Token: $fcmToken');

    if (fcmToken == null) {
      debugPrint('❌ Failed to retrieve FCM Token');
    }

    // ✅ Step 2: Listen for token refresh
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      onTokenRefresh(newToken);
    });

    // ✅ Step 3: Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      debugPrint('📩 FCM message received in foreground: ${notification?.title}');

      // Show notification as a local notification
      showLocalNotification(notification?.title, notification?.body);

      // Show Snackbar as confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(notification?.body ?? 'You have a new alert!')),
      );
    });

    // ✅ Step 4: Handle when the app is **opened from a notification**
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🟢 App opened from FCM message: ${message.notification?.title}');
      Navigator.pushNamed(context, '/alerts-settings');
    });

    // ✅ Step 5: Handle **terminated state** (when app is launched by tapping a notification)
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🚀 App launched from notification: ${message.notification?.title}');
        Navigator.pushNamed(context, '/alerts-settings');
      }
    });
  }
}
