import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Feature screens
import 'features/qr_code/qr_scanner_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/location/location_screen.dart';
import 'features/pdf/pdf_screen.dart';
import 'features/camera/camera_screen.dart';

// Global key for navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global notification settings
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  // Initialize local notifications
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      if (response.payload != null) {
        navigatorKey.currentState?.pushNamed(response.payload!);
      }
    },
  );
  
  // Setup Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');
  
  // Get FCM token for this device
  String? token = await messaging.getToken();
  print('FCM Token: $token');
  
  // Listen for FCM messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      _showLocalNotification(message);
    }
  });
  
  runApp(const MyApp());
}

Future<void> _showLocalNotification(RemoteMessage message) async {
  String? imageUrl = message.notification?.android?.imageUrl ??
                     message.notification?.apple?.imageUrl ??
                     message.data['imageUrl'] as String?;

  String? localImagePath;

  if (imageUrl != null && imageUrl.isNotEmpty) {
    try {
      localImagePath = await _downloadAndSaveImage(imageUrl, 'notification_image');
    } catch (e) {
      print('Error downloading notification image: $e');
      // Proceed without image if download fails
    }
  }

  // Android Notification Details
  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'phr_channel_rich', // New channel ID for rich notifications
    'PHR Rich Notifications',
    channelDescription: 'PHR app notifications channel with images',
    importance: Importance.max,
    priority: Priority.high,
    styleInformation: localImagePath != null
        ? BigPictureStyleInformation(
            FilePathAndroidBitmap(localImagePath), // Use FilePathAndroidBitmap for local files
            largeIcon: FilePathAndroidBitmap(localImagePath),
            contentTitle: message.notification?.title,
            htmlFormatContentTitle: true,
            summaryText: message.notification?.body,
            htmlFormatSummaryText: true,
          )
        : const DefaultStyleInformation(true, true),
  );

  // iOS Notification Details
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
  );

  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    message.hashCode, // Use a unique ID for each notification
    message.notification?.title ?? 'New Notification',
    message.notification?.body ?? '',
    platformChannelSpecifics,
    payload: message.data['navigation_path'] as String? ?? 'notifications',
  );
}

// Helper function to download and save image
Future<String?> _downloadAndSaveImage(String url, String fileName) async {
  try {
    final Directory directory = await getTemporaryDirectory();
    final String filePath = '${directory.path}/$fileName.png'; // Assuming png, adjust if needed
    final http.Response response = await http.get(Uri.parse(url));
    final File file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  } catch (e) {
    print('Error in _downloadAndSaveImage: $e');
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PHR POC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// App Router Configuration
final GoRouter _router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/qr_scanner',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/location',
      builder: (context, state) => const LocationScreen(),
    ),
    GoRoute(
      path: '/pdf',
      builder: (context, state) => const PdfScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),
  ],
);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PHR Features POC'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(
            context,
            'QR Scanner',
            Icons.qr_code_scanner,
            '/qr_scanner',
            Colors.purple,
          ),
          _buildFeatureCard(
            context,
            'Notifications',
            Icons.notifications,
            '/notifications',
            Colors.red,
          ),
          _buildFeatureCard(
            context,
            'Location',
            Icons.location_on,
            '/location',
            Colors.green,
          ),
          _buildFeatureCard(
            context,
            'PDF Handling',
            Icons.picture_as_pdf,
            '/pdf',
            Colors.orange,
          ),
          _buildFeatureCard(
            context,
            'Camera',
            Icons.camera_alt,
            '/camera',
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color color,
  ) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => context.push(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
