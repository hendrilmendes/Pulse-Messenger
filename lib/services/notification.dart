import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Configuração do GlobalKey para o Navigator
final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'notification_id';
  static const String channelName = 'Notificações';

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      importance: Importance.max,
    );

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Configura o callback para quando a notificação é tocada
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          _handleNotificationPayload(payload);
        }
      },
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final iosPlatform =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    iosPlatform?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isInitialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required int notificationId,
    String? payload,
  }) async {
    notificationId = notificationId % 2147483647;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      icon: '@mipmap/ic_launcher',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  void _handleNotificationPayload(String payload) {
    switch (payload) {
      case 'navigate_to_chat':
        navigationKey.currentState?.pushNamed('/chat');
        break;
      case 'navigate_to_comments':
        navigationKey.currentState?.pushNamed('/comments');
        break;
      default:
        navigationKey.currentState?.pushNamed('/home');
        break;
    }
  }
}
