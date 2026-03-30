import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/models/class_model.dart';
import '../data/models/class_member_model.dart';


class ClassController {
  final authService = AuthService();
  final fireStoreService = FireStoreService();


  String get _myUid => authService.currentUid ?? '';

 
  Future<String?> createClass({
    required String name,
    String? password,
  }) async {
    if (name.trim().isEmpty) return 'Vui lòng nhập tên lớp.';
    try {
      final data = {
        'name': name.trim(),
        'code': generateCode(),      // mã 6 ký tự tự động
        'teacher_id': _myUid,
        'created_at': DateTime.now().toIso8601String(),
        if (password != null && password.trim().isNotEmpty)
          'password_hash': password.trim(),
      };
      await fireStoreService.addDocument('classes', data);
      return null;
    } catch (_) {
      return 'Không thể tạo lớp. Vui lòng thử lại.';
    }
  }


  Stream<List<ClassModel>> getMyClassesStream() {
    return fireStoreService
        .streamWhere('classes', field: 'teacher_id', isEqualTo: _myUid,
            orderBy: 'created_at', descending: true)
        .map((snap) => snap.docs
            .map((doc) => ClassModel.fromJson(doc.data(), id: doc.id))
            .toList());
  }

  Stream<List<ClassModel>> getStudentClassesStream() {
    return fireStoreService
        .streamWhere('class_members', field: 'student_id', isEqualTo: _myUid)
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) return <ClassModel>[];
          
          List<ClassModel> classes = [];
          for (var doc in snap.docs) {
            final data = doc.data();
            // Chỉ lấy những lớp đang active (chưa bị kick)
            if (data['status'] == 'active') {
              final classDoc = await fireStoreService.getDocument('classes', data['class_id']);
              if (classDoc.exists) {
                classes.add(ClassModel.fromJson(classDoc.data() as Map<String, dynamic>, id: classDoc.id));
              }
            }
          }
          return classes;
        });
  }

  Future<Map<String, int>> getDashboardStats() async {
    try {
      final classCount = await fireStoreService.countWhere(
          'classes', field: 'teacher_id', isEqualTo: _myUid);
      final examCount = await fireStoreService.countWhere(
          'exams', field: 'teacher_id', isEqualTo: _myUid);
      return {'classes': classCount, 'students': 0, 'exams': examCount};
    } catch (_) {
      return {'classes': 0, 'students': 0, 'exams': 0};
    }
  }

  
  // Future<String?> deleteClass(String classId) async {
  //   try {
  //     await fireStoreService.deleteDocument('classes', classId);
  //     return null;
  //   } catch (_) {
  //     return 'Không thể xóa lớp.';
  //   }
  // }


  Future<String?> kickStudent(String memberId) async {
    try {
      await fireStoreService.updateDocument(
          'class_members', memberId, {'status': 'kicked'});
      return null;
    } catch (_) {
      return 'Không thể kick học sinh.';
    }
  }


  Future<String?> joinClass({required String code, required String password}) async {
    try {
      final snap = await fireStoreService.queryWhere(
          'classes', field: 'code', isEqualTo: code.toUpperCase(), limit: 1);
      if (snap.docs.isEmpty) return 'Mã lớp không tồn tại.';

      final classData = snap.docs.first.data();
      final stored = classData['password_hash'] as String?;
      if (stored != null && stored.isNotEmpty && password.trim() != stored) {
        return 'Mật khẩu lớp không đúng.';
      }

      await fireStoreService.addDocument('class_members', {
        'class_id': snap.docs.first.id,
        'student_id': _myUid,
        'status': 'active',
        'joined_at': DateTime.now().toIso8601String(),
      });
      return null;
    } catch (_) {
      return 'Không thể tham gia lớp.';
    }
  }


  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}