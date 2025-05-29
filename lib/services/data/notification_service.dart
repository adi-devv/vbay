import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:vbay/components/sliding_notification.dart';
import 'package:vbay/components/utils.dart';
import 'package:vbay/imp/get_server_key.dart';
import 'package:vbay/main.dart';
import 'package:vbay/models/bottom_navbar_key.dart';
import 'package:vbay/pages/nav/chat/chat_page.dart';
import 'package:vbay/providers/chat_provider.dart';
import 'package:vbay/providers/user_data_provider.dart';
import 'package:vbay/services/data/user_data_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print("Error fetching FCM token: $e");
      return null;
    }
  }

  Future<void> initNotification() async {
    await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );
    _initializePushNotification();
  }

  void _initializePushNotification() async {
    // Terminated State
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data['receiverID'] == UserDataService.getCurrentUser()?.uid) {
        debugPrint("App launched from terminated state with notification.");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleMessage(message, changePage: true);
        });
      }
    });

    // Background State
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['receiverID'] == UserDataService.getCurrentUser()?.uid) {
        debugPrint("Notification opened from background.");

        _handleMessage(message, changePage: true);
      }
    });

    // Foreground State
    FirebaseMessaging.onMessage.listen((message) {
      if (message.data['receiverID'] == UserDataService.getCurrentUser()?.uid) {
        debugPrint("Foreground message: ${message.notification?.title}");

        _handleMessage(message);
        if (message.data['type'] == 'approval') {
          initLocalNotifications();
          showLocalNotification(message);
        }
      }
    });

    // Ensure notification channel is created during initialization
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vbay-channel',
      'VBay Notifications',
      description: 'Channel for showing notifications',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );

    // Create the notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void initLocalNotifications() async {
    var androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showLocalNotification(RemoteMessage message) async {
    if (message.notification == null) return;

    String title = message.notification!.title ?? 'Notification';
    String? body = message.notification!.body;

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      message.notification!.android?.channelId ?? 'vbay-channel',
      message.notification!.android?.channelId ?? 'VBay Notifications',
      description: 'Channel for showing notifications',
      importance: Importance.high,
      showBadge: true,
      playSound: true,
    );
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    AndroidNotificationDetails androidNotificationDetails;

    // Use BigTextStyle for title-only when not approval
    androidNotificationDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        title,
        contentTitle: title,
        summaryText: 'Notification',
      ),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      Random().nextInt(10000),
      title,
      null,
      notificationDetails,
      payload: json.encode(message.data),
    );
  }

  Future<void> sendNotification(String fcmToken, String title, String? body,
      {required Map<String, dynamic> msgData}) async {
    try {
      final receiverID = msgData['receiverID'];

      final serverKey = await GetServerKey().getServerKeyToken();

      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': msgData,
          'android': {
            'priority': 'high',
          },
        }
      };

      final url = 'https://fcm.googleapis.com/v1/projects/vbay-p1/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKey',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print("Notification sent to user $receiverID");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  void _handleMessage(RemoteMessage? message, {bool? changePage}) {
    if (message == null) return;
    final String? notificationType = message.data['type'];

    if (notificationType == 'chat') {
      print("Chat Notification:");
      if (changePage == true) {
        BottomNavbarKey.instance.key.currentState?.changeTab(3);
        return;
      }
      String? chatWithID = navigatorKey.currentContext!.read<ChatProvider>().chatWithID;
      if (chatWithID != message.data['senderID'] && chatWithID != null ||
          BottomNavbarKey.instance.key.currentState?.getIndex() != 3 && chatWithID != message.data['senderID']) {
        _showSlidingNotification(message, chatWithID: chatWithID);
      }
    } else if (notificationType == 'approval') {
      _showApprovalDialog(message);
    } else if (notificationType == 'new_seek' && changePage == true) {
      BottomNavbarKey.instance.key.currentState?.changeTab(1);
    } else {
      print("Just a notification.");
    }
  }

  OverlayEntry? _overlayEntry;

  void _showSlidingNotification(RemoteMessage message, {String? chatWithID}) {
    final navigatorState = navigatorKey.currentState;
    if (navigatorState == null || !navigatorState.mounted) return;

    if (_overlayEntry != null) {
      _removeSlidingNotification();
    }
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final Map<String, dynamic> receiverData = {
          'uid': message.data['senderID'],
          'profile': message.data,
        };
        return SlidingNotification(
          message: message.data,
          onTap: () {
            _removeSlidingNotification();
            if (chatWithID != null) Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverData: receiverData,
                ),
              ),
            );
          },
          onDismiss: () {
            _removeSlidingNotification();
          },
        );
      },
    );

    if (navigatorState.overlay != null) {
      navigatorState.overlay!.insert(_overlayEntry!);
    } else {
      print("Overlay is not available.");
    }
  }

  void _removeSlidingNotification() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _showApprovalDialog(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      print("Context not available to show dialog");
      return;
    }
    context.read<UserDataProvider>().updatePostNotification(
          message.data['itemID'],
          message.data['status'],
          message.data['itemURL'],
          message.data['reasons']?.split(','),
        );

    // Show dialog with extracted details
    Utils.showDialogBox(
        context: context,
        message: message.notification!.body!,
        confirmText: 'View Profile',
        onConfirm: () {
          BottomNavbarKey.instance.key.currentState?.changeTab(4);
        });
  }
}
