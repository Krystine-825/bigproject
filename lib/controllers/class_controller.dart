
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/models/class_model.dart';
import '../data/models/class_member_model.dart';
import '../data/models/user_model.dart';
import 'notification_controller.dart'; 

class ClassController {
  final authService     = AuthService();
  final fireStoreService = FireStoreService();
  final _notif          = NotificationController(); 

  final Map<String, UserModel> _userCache  = {};
  final Map<String, Map<String, dynamic>> _classCache = {};

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

    final docRef =
        await fireStoreService.addDocument('classes', newClass.toJson());

    final created = ClassModel(
      id: docRef.id,
      name: newClass.name,
      code: newClass.code,
      teacherId: newClass.teacherId,
      passwordHash: newClass.passwordHash,
    );

    //  Thông báo cho giáo viên: tạo lớp thành công
    await _notif.notifyClassCreated(
      teacherId: teacherId,
      className: created.name,
      classId: created.id,
      code: created.code,
    );

    return created;
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

      final classSnap = await fireStoreService.queryWhere(
        'classes',
        field: 'teacher_id',
        isEqualTo: _myUid,
      );

      int studentCount = classSnap.docs.fold<int>(0, (sum, d) {
        final raw = (d.data()['student_count'] as num?)?.toInt() ?? 0;
        return sum + (raw < 0 ? 0 : raw);
      });

      return {
        'classes': classCount,
        'students': studentCount,
        'exams': examCount
      };
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
          .where((m) => m.isActive)
          .toList();

      final enriched = await Future.wait(members.map((m) async {
        if (_userCache.containsKey(m.studentId)) {
          return m.copyWith(
              studentName: _userCache[m.studentId]!.name,
              studentEmail: _userCache[m.studentId]!.email);
        }
        try {
          final userDoc =
              await fireStoreService.getDocument('users', m.studentId);
          if (userDoc.exists && userDoc.data() != null) {
            final user = UserModel.fromJson(userDoc.data()!);
            _userCache[m.studentId] = user;
            return m.copyWith(
                studentName: user.name, studentEmail: user.email);
          }
        } catch (_) {}
        return m;
      }));

      return enriched;
    });
  }


  Future<void> kickMember(String memberId) async {
    final memberDoc =
        await fireStoreService.getDocument('class_members', memberId);
    final classId  = memberDoc.data()?['class_id']  as String?;
    final studentId = memberDoc.data()?['student_id'] as String?; // 🔔

    await fireStoreService
        .updateDocument('class_members', memberId, {'status': 'kicked'});

    if (classId != null) {
      final classDoc =
          await fireStoreService.getDocument('classes', classId);
      final currentCount =
          (classDoc.data()?['student_count'] as num?)?.toInt() ?? 0;
      if (currentCount > 0) {
        await fireStoreService.incrementField('classes', classId,
            field: 'student_count', delta: -1);
      }

      // Thông báo cho học sinh bị kick
      if (studentId != null) {
        final className =
            (classDoc.data()?['name'] as String?) ?? 'Lớp học';
        await _notif.notifyKickedFromClass(
          studentId: studentId,
          className: className,
          classId: classId,
        );
      }
    }
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
    );

    if (snap.docs.isEmpty) throw Exception('Mã lớp không tồn tại');

    final classDoc  = snap.docs.first;
    final classData = ClassModel.fromJson(classDoc.data(), id: classDoc.id);

    if (classData.passwordHash != null &&
        classData.passwordHash!.isNotEmpty) {
      if (passwordHash == null || passwordHash.isEmpty) {
        throw Exception('Lớp này yêu cầu mật khẩu');
      }
      if (passwordHash != classData.passwordHash) {
        throw Exception('Mật khẩu không đúng');
      }
    }

    final memberSnap = await fireStoreService.queryWhere(
        'class_members',
        field: 'class_id',
        isEqualTo: classDoc.id);
    final existingMember = memberSnap.docs.any((d) =>
        d.data()['student_id'] == studentId &&
        d.data()['status'] == 'active');

    if (existingMember) throw Exception('Bạn đã là thành viên của lớp này');

    final newMember = ClassMemberModel(
        id: '',
        classId: classDoc.id,
        studentId: studentId,
        status: 'active');

    final batch    = FirebaseFirestore.instance.batch();
    final memberRef = FirebaseFirestore.instance.collection('class_members').doc();
    batch.set(memberRef, newMember.toJson());

    final classRef =
        FirebaseFirestore.instance.collection('classes').doc(classDoc.id);
    batch.update(classRef, {'student_count': FieldValue.increment(1)});

    await batch.commit();

    // Lấy tên học sinh rồi thông báo cho cả HS lẫn GV
    String studentName = '';
    try {
      final userDoc =
          await fireStoreService.getDocument('users', studentId);
      studentName = (userDoc.data()?['name'] as String?) ?? '';
    } catch (_) {}

    await _notif.notifyStudentJoinedClass(
      studentId: studentId,
      studentName: studentName.isNotEmpty ? studentName : 'Học sinh',
      teacherId: classData.teacherId,
      className: classData.name,
      classId: classData.id,
    );

    return classData;
  }


  Stream<List<Map<String, dynamic>>> streamStudentClasses() {
    final studentId = authService.currentUid ?? '';
    return fireStoreService
        .streamWhere('class_members',
            field: 'student_id', isEqualTo: studentId)
        .asyncMap((snap) async {
      final activeMembers = snap.docs
          .where((d) => d.data()['status'] == 'active')
          .toList();

      final result = await Future.wait(activeMembers.map((d) async {
        final classId = d.data()['class_id'] as String;

        if (_classCache.containsKey(classId)) return _classCache[classId];

        try {
          final classDoc =
              await fireStoreService.getDocument('classes', classId);
          if (!classDoc.exists || classDoc.data() == null) return null;

          final cls = ClassModel.fromJson(classDoc.data()!, id: classDoc.id);

          String teacherName = '';
          if (_userCache.containsKey(cls.teacherId)) {
            teacherName = _userCache[cls.teacherId]!.name;
          } else {
            final teacherDoc =
                await fireStoreService.getDocument('users', cls.teacherId);
            if (teacherDoc.exists && teacherDoc.data() != null) {
              final user = UserModel.fromJson(teacherDoc.data()!);
              _userCache[cls.teacherId] = user;
              teacherName = user.name;
            }
          }

          final classInfo = {
            'classId': cls.id,
            'name': cls.name,
            'code': cls.code,
            'teacher': teacherName.isNotEmpty ? 'GV: $teacherName' : 'Giáo viên',
          };

          _classCache[classId] = classInfo;
          return classInfo;
        } catch (_) {
          return null;
        }
      }));

      return result.whereType<Map<String, dynamic>>().toList();
    });
  }

  String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand  = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}