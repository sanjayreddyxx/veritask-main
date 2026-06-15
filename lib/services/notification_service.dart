import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level background message handler
// This MUST be annotated with @pragma('vm:entry-point') to prevent tree-shaking
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background/terminated notification message
  if (kDebugMode) {
    debugPrint('Handling a background message: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  
  // Conditionally initialize local notification plugin only on non-web platforms
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  
  // High-importance Android channel for WhatsApp-like floating notification popups
  final AndroidNotificationChannel _channel = const AndroidNotificationChannel(
    'veritask_high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for task updates and priority alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Request OS permission for notifications (important for iOS & Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) debugPrint('User granted notification permission');
      } else {
        if (kDebugMode) debugPrint('User declined or has not accepted notification permission');
      }

      // 2. Configure background message handler (Native only)
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }

      // 3. Configure local notification plugin settings for Foreground popups (Native only)
      if (!kIsWeb) {
        const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
        
        const InitializationSettings initSettings = InitializationSettings(
          android: androidInit,
          iOS: iosInit,
        );

        await _localNotif.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            // Handle local notification click action here
            if (kDebugMode) debugPrint('Notification clicked: ${response.payload}');
          },
        );

        // 4. Create high-importance Android channel
        await _localNotif
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // 5. Listen for FOREGROUND messages (triggers when user is using the app)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        
        if (notification != null) {
          if (kIsWeb) {
            // Web-specific console or fallback alert
            print('Foreground web notification received: ${notification.title} - ${notification.body}');
          } else {
            AndroidNotification? android = message.notification?.android;
            _localNotif.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                  playSound: true,
                  enableVibration: true,
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: message.data.toString(),
            );
          }
        }
      });

      // 6. Handle app opened from notification click when backgrounded
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) debugPrint('App opened from background via notification: ${message.notification?.title}');
      });

      // 7. Check if app was opened from terminated state via notification click
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) debugPrint('App opened from terminated via notification: ${initialMessage.notification?.title}');
      }

      _initialized = true;
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  // Fetch FCM token and save to the Firestore user document for targeting
  Future<void> saveTokenToUser(String uid) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) debugPrint('Successfully saved FCM token to user document: $token');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error saving FCM Token: $e');
    }
  }

  // Remove token upon user signing out to prevent sending notifications to wrong devices
  Future<void> removeTokenFromUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
      if (kDebugMode) debugPrint('Successfully cleared FCM token from user document.');
    } catch (e) {
      if (kDebugMode) debugPrint('Error removing FCM Token: $e');
    }
  }
}
