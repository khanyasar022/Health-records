import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/router.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS 10 and below local notifications
        print('Received local notification: $title');
      },
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          navigatorKey.currentState?.pushNamed(response.payload!);
        }
      },
    );
  }

  static Future<void> setupFirebaseMessaging() async {
    // Request permission for iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      print('FCM Token refreshed: $token');
      // Here you would typically send the new token to your server
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app from background state!');
      print('Message data: ${message.data}');
      
      if (message.data['navigation_path'] != null) {
        navigatorKey.currentState?.pushNamed(message.data['navigation_path']);
      }
    });

    // Check if app was opened from a notification
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state by notification');
      print('Message data: ${initialMessage.data}');
      
      if (initialMessage.data['navigation_path'] != null) {
        // Delay navigation to ensure app is fully initialized
        Future.delayed(const Duration(seconds: 1), () {
          navigatorKey.currentState?.pushNamed(initialMessage.data['navigation_path']);
        });
      }
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    String? imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['imageUrl'] as String?;

    String? localImagePath;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        localImagePath = await _downloadAndSaveImage(imageUrl, 'notification_image');
      } catch (e) {
        print('Error downloading notification image: $e');
      }
    }

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'phr_channel_rich',
      'PHR Rich Notifications',
      channelDescription: 'PHR app notifications channel with images',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: localImagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(localImagePath),
              largeIcon: FilePathAndroidBitmap(localImagePath),
              contentTitle: message.notification?.title,
              htmlFormatContentTitle: true,
              summaryText: message.notification?.body,
              htmlFormatSummaryText: true,
            )
          : const DefaultStyleInformation(true, true),
    );

    List<DarwinNotificationAttachment>? attachments;
    if (localImagePath != null) {
      try {
        attachments = [
          DarwinNotificationAttachment(localImagePath,
              identifier: 'imageAttachment')
        ];
      } catch (e) {
        print('Error creating iOS notification attachment: $e');
      }
    }

    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: attachments,
      categoryIdentifier: 'phr_notification_category',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data['navigation_path'] as String? ?? 'notifications',
    );
  }

  static Future<String?> _downloadAndSaveImage(String url, String fileName) async {
    try {
      final Directory directory = await getTemporaryDirectory();
      final String filePath = '${directory.path}/$fileName.png';
      final http.Response response = await http.get(Uri.parse(url));
      final File file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('Error in _downloadAndSaveImage: $e');
      return null;
    }
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  print('Message data: ${message.data}');
} 