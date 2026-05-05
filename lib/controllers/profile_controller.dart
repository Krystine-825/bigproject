

import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/models/user_model.dart';
import 'notification_controller.dart'; 

class ProfileController {
  final auth       = AuthService();
  final firestore  = FireStoreService();
  final _notif     = NotificationController(); 

  Future<UserModel?> getCurrentUser() async {
    final uid = auth.currentUid;
    if (uid == null) return null;
    try {
      final doc = await firestore.getDocument('users', uid);
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson({...doc.data()!, 'uid': uid});
    } catch (_) {
      return null;
    }
  }

  Future<String?> updateProfile({
    required String name,
    String? phone,
  }) async {
    final uid = auth.currentUid;
    if (uid == null) return 'Phiên đăng nhập hết hạn.';
    if (name.trim().isEmpty) return 'Tên không được để trống.';
    try {
      await firestore.updateDocument('users', uid, {
        'name': name.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      });
      await auth.currentUser?.updateDisplayName(name.trim());
      return null;
    } catch (_) {
      return 'Không thể lưu thông tin. Vui lòng thử lại.';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword.length < 8) {
      return 'Mật khẩu mới phải có ít nhất 8 ký tự.';
    }
    if (newPassword != confirmPassword) {
      return 'Mật khẩu xác nhận không khớp.';
    }

    final user = auth.currentUser;
    if (user == null || user.email == null) return 'Phiên đăng nhập hết hạn.';

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      // Thông báo bảo mật: đổi mật khẩu thành công
      await _notif.notifyPasswordChanged(userId: user.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Mật khẩu hiện tại không đúng.';
        case 'too-many-requests':
          return 'Thử lại quá nhiều lần. Vui lòng chờ.';
        case 'requires-recent-login':
          return 'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';
        default:
          return 'Đổi mật khẩu thất bại. Vui lòng thử lại.';
      }
    } catch (_) {
      return 'Đổi mật khẩu thất bại. Vui lòng thử lại.';
    }
  }

  Future<Map<String, dynamic>> getStudentStats() async {
    final uid = auth.currentUid;
    if (uid == null) return {'classes': 0, 'exams': 0, 'avgScore': 0.0};
    try {
      final memberSnap = await firestore.queryWhere(
        'class_members',
        field: 'student_id',
        isEqualTo: uid,
      );
      final classCount =
          memberSnap.docs.where((d) => d.data()['status'] == 'active').length;

      final subSnap = await firestore.queryWhere(
        'submissions',
        field: 'student_id',
        isEqualTo: uid,
      );
      final submissions = subSnap.docs;
      final examCount = submissions.length;
      final avgScore = examCount > 0
          ? submissions.fold<double>(
                  0,
                  (s, d) =>
                      s + ((d.data()['score'] as num?)?.toDouble() ?? 0)) /
              examCount
          : 0.0;

      return {
        'classes': classCount,
        'exams': examCount,
        'avgScore': double.parse(avgScore.toStringAsFixed(1)),
      };
    } catch (_) {
      return {'classes': 0, 'exams': 0, 'avgScore': 0.0};
    }
  }

  Future<Map<String, int>> getTeacherStats() async {
    final uid = auth.currentUid;
    if (uid == null) return {'classes': 0, 'students': 0, 'exams': 0};
    try {
      final classSnap = await firestore.queryWhere(
        'classes',
        field: 'teacher_id',
        isEqualTo: uid,
      );
      final classCount = classSnap.docs.length;
      final studentCount = classSnap.docs.fold<int>(
        0,
        (s, d) =>
            s +
            (((d.data()['student_count'] as num?)?.toInt() ?? 0)
                .clamp(0, 99999)),
      );
      final examCount = await firestore.countWhere(
        'exams',
        field: 'teacher_id',
        isEqualTo: uid,
      );
      return {
        'classes': classCount,
        'students': studentCount,
        'exams': examCount,
      };
    } catch (_) {
      return {'classes': 0, 'students': 0, 'exams': 0};
    }
  }

  Future<void> signOut() => auth.signOut();
}