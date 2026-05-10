// lib/data/services/fcm_service.dart
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

 
  static const String channelId = 'edu_exam_default';
  static const String channelName = 'Thông báo hệ thống';
  static const String channelDesc = 'Thông báo đề thi, lớp học và kết quả';

  
  static final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

 
  static Future<void> init() async {
  
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

   
    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotif.initialize(initSettings);

    
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotif.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDesc,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
    });

    // 5. Yêu cầu FCM không tự ẩn notification khi foreground (iOS)
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Background handler — phải là top-level function (không nằm trong class)
  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    // Flutter tự hiện notification khi app ở background/terminated
    // Không cần làm gì thêm
  }

 
  Future<bool> hasToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final tokens = doc.data()?['fcm_tokens'] as List?;
      return tokens != null && tokens.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  
  Future<bool> requestPermissionAndSaveToken() async {
    
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      await _saveTokenToFirestore();
      _messaging.onTokenRefresh.listen(_onTokenRefresh);
    }

    return granted;
  }

 
  Future<void> removeToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).update({
          'fcm_tokens': FieldValue.arrayRemove([token]),
        });
      }
      await _messaging.deleteToken();
    } catch (_) {}
  }

  Future<void> _saveTokenToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({
        'fcm_tokens': FieldValue.arrayUnion([token]),
      });
    } catch (_) {}
  }

  Future<void> _onTokenRefresh(String newToken) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).update({
        'fcm_tokens': FieldValue.arrayUnion([newToken]),
      });
    } catch (_) {}
  }
}