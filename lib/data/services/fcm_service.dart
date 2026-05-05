// lib/data/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FcmService {
  final _messaging = FirebaseMessaging.instance;
  final _db        = FirebaseFirestore.instance;

  // Gọi trong main.dart trước runApp()
  static Future<void> initBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
  }

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    // Flutter tự hiện notification khi app ở background/terminated
  }

  // Kiểm tra user hiện tại có token chưa — dùng để set trạng thái Switch
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

  // Xin quyền + lưu token → trả về true nếu được cấp quyền
  Future<bool> requestPermissionAndSaveToken() async {
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

  // Xoá token khi tắt thông báo hoặc đăng xuất
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