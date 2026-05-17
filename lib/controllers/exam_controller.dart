import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/exam_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/firestore_service.dart';
import '../data/services/storage_service.dart';
import 'notification_controller.dart';
import 'dart:convert';

class ExamController {
  final functions = FirebaseFunctions.instance;
  final firestore = FireStoreService();
  final auth = AuthService();
  final storage = StorageService();
  final _notif = NotificationController();

  // tạo đề
  Future<ExamModel> generateExam({
    required String examName,
    required File pdfFile,
    required String extractedText,
    required String fileName,
    required int questionCount,
    required String cefrLevel, 
  }) async {
    final teacherId = auth.currentUid;
    if (teacherId == null) throw Exception('Người dùng chưa đăng nhập');

    final uploaded = await storage.uploadPdf(pdfFile, teacherId, fileName);

    final callable = functions.httpsCallable(
      'generateExamFromPdf',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 3)),
    );

    final result = await callable.call({
      'teacherId': teacherId,
      'pdfUrl': uploaded.downloadUrl,
      'storagePath': uploaded.storagePath,
      'extractedText': extractedText,
      'fileName': fileName,
      'config': {
        'questionCount': questionCount,
        'questionTypes': ['multiple_choice', 'fill_in', 'true_false', 'reading_comprehension'],
        'targetCEFR': cefrLevel, 
      },
    });

    final String jsonString = jsonEncode(result.data);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Tạo đề thi thất bại');
    }

    final examJson = data['exam'] as Map<String, dynamic>;
    final examId = (examJson['exam_id'] ?? examJson['id'] ?? '') as String;

    if (examId.isEmpty) throw Exception('Không nhận được ID đề từ server');

    final exam = ExamModel.fromJson(examJson, id: examId);

    // Thông báo giáo viên: tạo đề thành công
    await _notif.notifyExamCreated(
      teacherId: teacherId,
      examName: examName,
      examId: exam.id,
      questionCount: exam.questions.length,
    );

    return exam;
  }

  Future<void> saveExam(ExamModel exam) async {
    await firestore.setDocument('exams', exam.id, exam.toJson());
  }

  // giao đề
  Future<void> assignExamToClasses({
    required String examId,
    required List<Map<String, String>> classes, 
    required int durationMinutes,
    required DateTime openAt,
    required DateTime closeAt,
    required int maxAttempts,
    required String examName,
    bool showAnswerAfterSubmit = false,
  }) async {
    final teacherId = auth.currentUid ?? '';
    final now = DateTime.now().toIso8601String();

    final newAssignments = classes
        .map(
          (cls) => {
            'classId': cls['id'],
            'className': cls['name'],
            'durationMinutes': durationMinutes,
            'openAt': openAt.toIso8601String(),
            'closeAt': closeAt.toIso8601String(),
            'maxAttempts': maxAttempts,
            'assignedAt': now,
            'showAnswerAfterSubmit': showAnswerAfterSubmit,
          },
        )
        .toList();

    final newClassIds = classes.map((c) => c['id']!).toList();

    await FirebaseFirestore.instance.collection('exams').doc(examId).update({
      'status': 'assigned',
      'class_id': newClassIds.first,
      'assignments': FieldValue.arrayUnion(newAssignments),
      'assigned_class_ids': FieldValue.arrayUnion(newClassIds),
      'assigned_at': now,
    });

    for (final cls in classes) {
      _sendAssignNotifications(
        examId: examId,
        examName: examName,
        classId: cls['id']!,
        className: cls['name']!,
        teacherId: teacherId,
        closeAt: closeAt,
      );
    }
  }

  Future<void> assignExam({
    required String examId,
    required String classId,
    required String className,
    required int durationMinutes,
    required DateTime openAt,
    required DateTime closeAt,
    required int maxAttempts,
    required String examName,
    bool showAnswerAfterSubmit = false,
  }) async {
    final teacherId = auth.currentUid ?? '';

    final newAssignment = {
      'classId': classId,
      'className': className,
      'durationMinutes': durationMinutes,
      'openAt': openAt.toIso8601String(),
      'closeAt': closeAt.toIso8601String(),
      'maxAttempts': maxAttempts,
      'assignedAt': DateTime.now().toIso8601String(),
      'showAnswerAfterSubmit': showAnswerAfterSubmit,
    };

    await FirebaseFirestore.instance.collection('exams').doc(examId).update({
      'status': 'assigned',
      'class_id': classId,
      'assignments': FieldValue.arrayUnion([newAssignment]),
      'assigned_class_ids': FieldValue.arrayUnion([classId]),
      'assigned_at': DateTime.now().toIso8601String(),
    });

    _sendAssignNotifications(
      examId: examId,
      examName: examName,
      classId: classId,
      className: className,
      teacherId: teacherId,
      closeAt: closeAt,
    );
  }

  Future<void> _sendAssignNotifications({
    required String examId,
    required String examName,
    required String classId,
    required String className,
    required String teacherId,
    required DateTime closeAt,
  }) async {
    try {
      final memberSnap = await firestore.queryWhere(
        'class_members',
        field: 'class_id',
        isEqualTo: classId,
      );
      final studentIds = memberSnap.docs
          .where((d) => d.data()['status'] == 'active')
          .map((d) => (d.data()['student_id'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      await Future.wait([
        _notif.notifyExamAssignedToStudents(
          studentIds: studentIds,
          examName: examName,
          examId: examId,
          classId: classId,
          className: className,
          closeAt: closeAt,
        ),
        _notif.notifyExamAssignedConfirm(
          teacherId: teacherId,
          examName: examName,
          examId: examId,
          className: className,
          classId: classId,
        ),
      ]);
    } catch (_) {}
  }

  // thu hồi đề
  Future<void> unassignExam({
    required String examId,
    required String classId,
  }) async {
    final examDoc = await firestore.getDocument('exams', examId);
    if (!examDoc.exists || examDoc.data() == null) return;

    final data = examDoc.data()!;
    final List<dynamic> currentAssignments = data['assignments'] ?? [];
    final List<dynamic> currentAssignedClassIds =
        data['assigned_class_ids'] ?? [];
        
    // Lấy tên đề thi để hiện lên thông báo
    final examName = (data['title'] ?? data['name'] ?? 'Đề thi') as String;

    final updatedAssignments = currentAssignments
        .where((a) => a['classId'] != classId)
        .toList();
    final updatedAssignedClassIds = currentAssignedClassIds
        .where((id) => id != classId)
        .toList();

    // Trở về draft nếu thu hồi toàn bộ lớp
    final newStatus = updatedAssignments.isEmpty ? 'draft' : 'assigned';

    // 
    final batch = FirebaseFirestore.instance.batch();

    final examRef = FirebaseFirestore.instance.collection('exams').doc(examId);
    batch.update(examRef, {
      'assignments': updatedAssignments,
      'assigned_class_ids': updatedAssignedClassIds,
      'status': newStatus,
    });

    final subSnap = await firestore.queryWhere(
      'submissions',
      field: 'exam_id',
      isEqualTo: examId,
    );
    for (final doc in subSnap.docs) {
      if (doc.data()['class_id'] == classId) {
        batch.delete(doc.reference); // Xóa bài nộp cũ của học sinh
      }
    }

    await batch.commit(); // Chạy đồng thời

    // gửi thông báo cho học sinh 
    try {
      final memberSnap = await firestore.queryWhere(
        'class_members',
        field: 'class_id',
        isEqualTo: classId,
      );
      final studentIds = memberSnap.docs
          .where((doc) => doc.data()['status'] == 'active')
          .map((doc) => (doc.data()['student_id'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (studentIds.isNotEmpty) {
        final classDoc = await firestore.getDocument('classes', classId);
        final className =
            (classDoc.data()?['name'] as String?) ?? 'Lớp học';

        // Gọi hàm từ notification_controller
        await _notif.notifyExamDeletedToStudents(
          studentIds: studentIds,
          examName: examName,
          classId: classId,
          className: className,
        );
      }
    } catch (_) {}
  }

  // xóa đề thi và toàn bộ bài nộp
  Future<void> deleteExam(String examId) async {
    try {
      final examDoc = await firestore.getDocument('exams', examId);
      if (examDoc.exists && examDoc.data() != null) {
        final d = examDoc.data()!;
        final examName = (d['name'] ?? d['title'] ?? 'Đề thi') as String;
        final assignedIds = List<String>.from(d['assigned_class_ids'] ?? []);

        for (final classId in assignedIds) {
          final memberSnap = await firestore.queryWhere(
            'class_members',
            field: 'class_id',
            isEqualTo: classId,
          );
          final studentIds = memberSnap.docs
              .where((doc) => doc.data()['status'] == 'active')
              .map((doc) => (doc.data()['student_id'] as String?) ?? '')
              .where((id) => id.isNotEmpty)
              .toList();

          if (studentIds.isNotEmpty) {
            final classDoc = await firestore.getDocument('classes', classId);
            final className = (classDoc.data()?['name'] as String?) ?? 'Lớp học';

            await _notif.notifyExamDeletedToStudents(
              studentIds: studentIds,
              examName: examName,
              classId: classId,
              className: className,
            );
          }
        }
      }
    } catch (_) {} 

    final batch = FirebaseFirestore.instance.batch();

    final subSnap = await firestore.queryWhere(
      'submissions',
      field: 'exam_id',
      isEqualTo: examId,
    );
    for (final doc in subSnap.docs) {
      batch.delete(doc.reference);
    }

    final examRef = FirebaseFirestore.instance.collection('exams').doc(examId);
    batch.delete(examRef);

    await batch.commit();
  }

  Future<List<Map<String, String>>> getMyClasses() async {
    final teacherId = auth.currentUid ?? '';
    final snap = await firestore.queryWhere(
      'classes',
      field: 'teacher_id',
      isEqualTo: teacherId,
    );

    return snap.docs
        .map((d) => {'id': d.id, 'name': (d.data()['name'] ?? '') as String})
        .toList();
  }

  Stream<List<ExamModel>> streamMyExams() {
    final teacherId = auth.currentUid ?? '';
    if (teacherId.isEmpty) return Stream.value([]);

    return firestore
        .streamWhere('exams', field: 'teacher_id', isEqualTo: teacherId)
        .map(
          (snap) => snap.docs
              .map((doc) => ExamModel.fromJson(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<ExamModel>> streamAssignedExamsForStudent(String classId) {
    final studentId = auth.currentUid ?? '';
    if (studentId.isEmpty || classId.isEmpty) return Stream.value([]);

    return firestore
        .streamArrayContains(
          'exams',
          field: 'assigned_class_ids',
          value: classId,
        )
        .map((snap) {
          return snap.docs
              .map((doc) => ExamModel.fromJson(doc.data(), id: doc.id))
              .where(
                (exam) => exam.assignments.any((a) => a.classId == classId),
              )
              .toList()
            ..sort((a, b) {
              final closeA = a.assignments
                  .firstWhere((ass) => ass.classId == classId)
                  .closeAt;
              final closeB = b.assignments
                  .firstWhere((ass) => ass.classId == classId)
                  .closeAt;
              return closeA.compareTo(closeB);
            });
        });
  }
}