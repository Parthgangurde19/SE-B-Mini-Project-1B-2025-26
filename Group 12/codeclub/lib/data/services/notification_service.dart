import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

/// Notification Service for Chat Notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      print('NotificationService: Initialized successfully');
    } catch (e) {
      print('NotificationService: Error initializing - $e');
    }
  }

  /// Handle notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      print('NotificationService: Notification tapped with payload: $payload');
      // Handle navigation based on payload if needed
      // You can parse the payload and navigate to the appropriate screen
    }
  }

  /// Show message notification
  Future<void> showMessageNotification({
    required String chatId,
    required String senderName,
    required String messageContent,
    String? senderImage,
  }) async {
    try {
      // Don't show notification if message is too long
      final displayMessage = messageContent.length > 50
          ? '${messageContent.substring(0, 47)}...'
          : messageContent;

      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
            'chat_channel',
            'Chat Messages',
            channelDescription: 'Notification channel for chat messages',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          );

      const DarwinNotificationDetails iosNotificationDetails =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iosNotificationDetails,
      );

      await _notificationsPlugin.show(
        chatId.hashCode,
        senderName,
        displayMessage,
        notificationDetails,
        payload: chatId,
      );

      print('NotificationService: Notification shown for $senderName');
    } catch (e) {
      print('NotificationService: Error showing notification - $e');
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(String chatId) async {
    try {
      await _notificationsPlugin.cancel(chatId.hashCode);
      print('NotificationService: Notification cancelled for $chatId');
    } catch (e) {
      print('NotificationService: Error cancelling notification - $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      print('NotificationService: All notifications cancelled');
    } catch (e) {
      print('NotificationService: Error cancelling all notifications - $e');
    }
  }

  /// Start listening to notification events
  static Future<void> startListeningNotificationEvents() async {
    // Notification event handling is now done in the initialize method
    // through the onDidReceiveNotificationResponse callback
    print('NotificationService: Notification listeners initialized');
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    try {
      // For Android 13+ permission handling
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          return await androidImplementation.requestNotificationsPermission() ?? false;
        }
      }
      
      // For iOS
      if (Platform.isIOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _notificationsPlugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImplementation != null) {
          return await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ?? false;
        }
      }

      return true; // Default to true for other platforms
    } catch (e) {
      print('NotificationService: Error requesting permission - $e');
      return false;
    }
  }
}
