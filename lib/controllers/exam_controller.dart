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
  final firestore  = FireStoreService();
  final auth       = AuthService();
  final storage    = StorageService();
  final _notif     = NotificationController(); 

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
        'questionTypes': ['multiple_choice', 'fill_in', 'true_false'],
        'targetCEFR': cefrLevel,
      },
    });

    final String jsonString = jsonEncode(result.data);
    final Map<String, dynamic> data = jsonDecode(jsonString);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Tạo đề thi thất bại');
    }

    final examJson = data['exam'] as Map<String, dynamic>;
    final examId   = (examJson['exam_id'] ?? examJson['id'] ?? '') as String;

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

  //giao đề

  Future<void> assignExam({
    required String examId,
    required String classId,
    required String className,
    required int durationMinutes,
    required DateTime openAt,
    required DateTime closeAt,
    required int maxAttempts,
    required String examName, // thêm vào để gửi thông báo 
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

    // Gửi thông báo KHÔNG await — chạy nền, không block UI
    _sendAssignNotifications(
      examId: examId, examName: examName,
      classId: classId, className: className,
      teacherId: teacherId, closeAt: closeAt,
    );
    // Hàm kết thúc ngay, không chờ notification
  }

  // Hàm riêng chạy nền
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

  //  thu hồi đề (rút lại đề từ một lớp, và tự động chuyển trạng thái về draft nếu không còn lớp nào được giao)
  Future<void> unassignExam({
    required String examId,
    required String classId,
  }) async {
    final examDoc = await firestore.getDocument('exams', examId);
    if (!examDoc.exists || examDoc.data() == null) return;

    final data = examDoc.data()!;
    final List<dynamic> currentAssignments = data['assignments'] ?? [];
    final List<dynamic> currentAssignedClassIds = data['assigned_class_ids'] ?? [];

    // Lọc bỏ classId cần thu hồi ra khỏi danh sách
    final updatedAssignments = currentAssignments
        .where((a) => a['classId'] != classId)
        .toList();
    final updatedAssignedClassIds = currentAssignedClassIds
        .where((id) => id != classId)
        .toList();

    // 💡 Điểm mấu chốt: Nếu danh sách rỗng, đưa status về lại draft
    final newStatus = updatedAssignments.isEmpty ? 'draft' : 'assigned';

    await FirebaseFirestore.instance.collection('exams').doc(examId).update({
      'assignments': updatedAssignments,
      'assigned_class_ids': updatedAssignedClassIds,
      'status': newStatus,
    });
  }

  //xóa dề

  // xóa đề thi (Chỉ áp dụng cho đề chưa giao)
  Future<void> deleteExam(String examId) async {
    final examDoc = await firestore.getDocument('exams', examId);
    if (examDoc.exists && examDoc.data() != null) {
      final d = examDoc.data()!;
      final assignedIds = List<String>.from(d['assigned_class_ids'] ?? []);

      // Nếu danh sách lớp đã giao không rỗng, báo lỗi ngay!
      if (assignedIds.isNotEmpty) {
        throw Exception('Không thể xóa đề thi đang được giao. Vui lòng thu hồi đề khỏi các lớp trước khi xóa.');
      }
    }

    // Nếu đề chưa giao, tiến hành xóa đề thi gốc
    final examRef = FirebaseFirestore.instance.collection('exams').doc(examId);
    await examRef.delete();
  }




  Future<List<Map<String, String>>> getMyClasses() async {
    final teacherId = auth.currentUid ?? '';
    final snap = await firestore.queryWhere(
      'classes',
      field: 'teacher_id',
      isEqualTo: teacherId,
    );

    return snap.docs
        .map((d) => {
              'id': d.id,
              'name': (d.data()['name'] ?? '') as String,
            })
        .toList();
  }


  Stream<List<ExamModel>> streamMyExams() {
    final teacherId = auth.currentUid ?? '';
    if (teacherId.isEmpty) return Stream.value([]);

    return firestore
        .streamWhere('exams', field: 'teacher_id', isEqualTo: teacherId)
        .map((snap) => snap.docs
            .map((doc) => ExamModel.fromJson(doc.data(), id: doc.id))
            .toList());
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
              .where((exam) => exam.assignments.any((a) => a.classId == classId))
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