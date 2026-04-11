import 'dart:math';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/models/class_model.dart';
import '../data/models/class_member_model.dart';
import '../data/models/user_model.dart';

class ClassController {
  final authService = AuthService();
  final fireStoreService = FireStoreService();


  String get _myUid => authService.currentUid ?? '';

 
  Future<ClassModel> createClass({
    required String name,
    String? passwordHash,
  }) async {
    final teacherId = authService.currentUid;
    if (teacherId == null) throw Exception('Chưa đăng nhập');
 
    final code = generateCode();
 
    final newClass = ClassModel(
      id: '',
      name: name.trim(),
      code: code,
      teacherId: teacherId,
      passwordHash: passwordHash,
    );
 
    final docRef = await fireStoreService.addDocument('classes', newClass.toJson());
 
    return ClassModel(
      id: docRef.id,
      name: newClass.name,
      code: newClass.code,
      teacherId: newClass.teacherId,
      passwordHash: newClass.passwordHash,
    );
  }


   Future<List<ClassModel>> getMyClasses() async {
    final teacherId = authService.currentUid;
    if (teacherId == null) return [];
 
    final snap = await fireStoreService.queryWhere(
      'classes',
      field: 'teacher_id',
      isEqualTo: teacherId,
      orderBy: 'created_at',
      descending: true,
    );
 
    return snap.docs
        .map((d) => ClassModel.fromJson(d.data(), id: d.id))
        .toList();
  }


Stream<List<ClassModel>> streamMyClasses() {
    final teacherId = authService.currentUid ?? '';
    return fireStoreService
        .streamWhere('classes', field: 'teacher_id', isEqualTo: teacherId)
        .map((snap) => snap.docs
            .map((d) => ClassModel.fromJson(d.data(), id: d.id))
            .toList());
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

   Stream<List<ClassMemberModel>> streamMembers(String classId) {
    return fireStoreService
        .streamWhere('class_members', field: 'class_id', isEqualTo: classId)
        .asyncMap((snap) async {
      final members = snap.docs
          .map((d) => ClassMemberModel.fromJson(d.data(), id: d.id))
          .where((m) => m.isActive) // chỉ lấy thành viên active
          .toList();
 
      // Join thông tin user (name, email) song song
      final enriched = await Future.wait(members.map((m) async {
        try {
          final userDoc = await fireStoreService.getDocument('users', m.studentId);
          if (userDoc.exists && userDoc.data() != null) {
            final user =  UserModel.fromJson(userDoc.data()!);
            return m.copyWith(
              studentName: user.name,
              studentEmail: user.email,
            );
          }
        } catch (_) {}
        return m; // nếu lỗi thì trả nguyên không có name/email
      }));
 
      return enriched;
    });
  }

  
  // Future<String?> deleteClass(String classId) async {
  //   try {
  //     await fireStoreService.deleteDocument('classes', classId);
  //     return null;
  //   } catch (_) {
  //     return 'Không thể xóa lớp.';
  //   }
  // }
 
 

   Future<void> kickMember(String memberId) async {
    await fireStoreService.updateDocument(
      'class_members',
      memberId,
      {'status': 'kicked'},
    );
  }

  Future<ClassModel> joinClass({
    required String code,
    String? passwordHash,
  }) async {
    final studentId = authService.currentUid;
    if (studentId == null) throw Exception('Chưa đăng nhập');
 
    final snap = await fireStoreService.queryWhere(
      'classes',
      field: 'code',
      isEqualTo: code.trim().toUpperCase(),
      //limit: 1,
    );
 
    if (snap.docs.isEmpty) throw Exception('Mã lớp không tồn tại');
 
    final classDoc = snap.docs.first;
    final classData = ClassModel.fromJson(classDoc.data(), id: classDoc.id);
 
    if (classData.passwordHash != null && classData.passwordHash!.isNotEmpty) {
      if(passwordHash == null || passwordHash.isEmpty) {
        throw Exception('Lớp này yêu cầu mật khẩu');
      }
      if(passwordHash != classData.passwordHash) {
        throw Exception('Mật khẩu không đúng');
      }
    }
 
    // Kiểm tra nếu đã là thành viên thì không thêm nữa
    final memberSnap = await fireStoreService.queryWhere(
      'class_members',
      field: 'class_id',
      isEqualTo: classDoc.id,
    );
   final existingMember = memberSnap.docs.any((d) {
    final data= d.data();
    return data['student_id'] == studentId && data['status'] == 'active';
   });
   if(existingMember) throw Exception('Bạn đã là thành viên của lớp này');

    if (memberSnap.docs.isEmpty) {
      // Thêm thành viên mới
      final newMember = ClassMemberModel(
        id: '',
        classId: classDoc.id,
        studentId: studentId,
        status: 'active',
      );
      await fireStoreService.addDocument('class_members', newMember.toJson());
    }
 
    return classData;
  }

 Stream<List<Map<String, dynamic>>> streamStudentClasses() {
    final studentId = authService.currentUid ?? '';
    return fireStoreService.streamWhere('class_members', field: 'student_id', isEqualTo: studentId)
        .asyncMap((snap) async {
      // Chỉ lấy các membership active
      final activeMembers = snap.docs
          .where((d) => d.data()['status'] == 'active')
          .toList();
 
      final result = await Future.wait(activeMembers.map((d) async {
        final classId = d.data()['class_id'] as String;
        try {
          final classDoc = await fireStoreService.getDocument('classes', classId);
          if (!classDoc.exists || classDoc.data() == null) return null;
 
          final cls = ClassModel.fromJson(classDoc.data()!, id: classDoc.id);
 
          // Lấy tên giáo viên
          String teacherName = '';
          try {
            final teacherDoc =
                await fireStoreService.getDocument('users', cls.teacherId);
            if (teacherDoc.exists && teacherDoc.data() != null) {
              teacherName = UserModel.fromJson(teacherDoc.data()!).name;
            }
          } catch (_) {}
 
          return {
            'classId': cls.id,
            'name': cls.name,
            'code': cls.code,
            'teacher': teacherName.isNotEmpty ? 'GV: $teacherName' : 'Giáo viên',
          };
        } catch (_) {
          return null;
        }
      }));
 
      return result.whereType<Map<String, dynamic>>().toList();
    });
 }
  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}