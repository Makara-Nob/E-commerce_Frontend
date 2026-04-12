import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

typedef OnNotificationReceived = void Function();

// Background handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Called when any notification is received or tapped — refreshes badge + list
  OnNotificationReceived? onNotificationReceived;

  /// Set this from main.dart so the service can navigate to NotificationScreen
  GlobalKey<NavigatorState>? navigatorKey;

  Future<void> init() async {
    // 1. Request permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('[FCM] Notification permission denied');
      return;
    }

    // 2. Initialize local notifications with tap handler
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // User tapped a foreground local notification banner → go to notifications
        _openNotificationScreen();
      },
    );

    // 3. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Foreground FCM message → show banner + refresh list
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
        onNotificationReceived?.call();
      }
    });

    // 5. App in background → user taps system notification → app resumes
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationReceived?.call();
      _openNotificationScreen();
    });

    // 6. App terminated → notification tap launched the app
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Delay to let the widget tree build before navigating
      Future.delayed(const Duration(milliseconds: 800), () {
        onNotificationReceived?.call();
        _openNotificationScreen();
      });
    }

    // 7. FCM token refresh
    _fcm.onTokenRefresh.listen(sendTokenToBackend);

    // 8. Register token for already logged-in users
    await registerDeviceToken();
  }

  void _openNotificationScreen() {
    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    // Lazily import to avoid circular deps — use the route name approach
    nav.pushNamed('/notifications');
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'ecommerce_channel',
      'E-commerce Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
        id: id, title: title, body: body, notificationDetails: details);
  }

  // Call this after successful login
  Future<void> registerDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await sendTokenToBackend(token);
      }
    } catch (e) {
      print("Failed to get FCM token: $e");
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString(ApiConstants.tokenKey); // Use your existing token key
      
      if (jwtToken == null) return; // User not logged in

      final url = Uri.parse('${ApiConstants.baseUrl}/api/v1/tokens/register'); 
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'token': token,
          'deviceType': 'android', // This can be determined dynamically using device_info_plus if needed
        }),
      );

      if (response.statusCode == 201) {
        print("FCM Token successfully registered to backend.");
      } else {
        print("Failed to register FCM token: ${response.body}");
      }
    } catch (e) {
      print('Error sending token to backend: $e');
    }
  }
}
